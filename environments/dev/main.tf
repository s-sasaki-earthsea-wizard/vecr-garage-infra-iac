terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Project     = var.project
      }
    )
  }
}

# Secrets Manager Module for Lambda secrets (LLM APIs + Discord credentials)
module "secrets_manager_lambda" {
  source = "../../modules/secrets-manager"

  project     = var.project
  environment = var.environment
  secret_name = "lambda-secrets"
  description = "Secrets for Lambda functions (LLM APIs, Discord Bot)"

  secret_map = merge(
    # LLM APIs
    {
      anthropic_api_key   = var.anthropic_api_key
      open_router_api_key = var.open_router_api_key
    },
    # Discord Bot Tokens (dynamically from map)
    { for k, v in var.discord_bot_tokens : "${k}_bot_token" => v },
    # Discord Webhook URLs (dynamically from map)
    { for k, v in var.discord_webhooks : "${k}_webhook" => v }
  )

  create_access_policy = true
}

# Secrets Manager Module for App secrets (EC2/ECS/Lightsail)
module "secrets_manager_app" {
  source = "../../modules/secrets-manager"

  project     = var.project
  environment = var.environment
  secret_name = "app-secrets"
  description = "Secrets for application (Flask, etc.)"

  secret_map = {
    flask_secret_key = var.flask_secret_key
  }

  create_access_policy = true
}

# IAM Module (for EC2)
module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
}

# IAM Role for Discord Bot Service
module "iam_discord_bot" {
  source = "../../modules/iam-service-roles"

  project     = var.project
  environment = var.environment
  role_name   = "discord-bot-role"

  # Trust policy - can be assumed by Lambda, ECS, etc.
  enable_lambda_assume = true
  enable_ecs_assume    = false # Enable when migrating to ECS
  enable_ec2_assume    = false

  # Secrets Manager access
  enable_secrets_manager_access = true
  secrets_manager_secret_arns   = [module.secrets_manager_lambda.secret_arn]

  # DynamoDB access (enable when DynamoDB module is created)
  enable_dynamodb_access = false
  # dynamodb_table_arns    = [module.dynamodb.table_arn]

  # CloudWatch Logs
  enable_cloudwatch_logs = true
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  create_nat_gateway   = var.create_nat_gateway
  create_vpc_endpoints = var.create_vpc_endpoints
  aws_region           = var.aws_region
}

# EC2 Module (Commented out - not needed for current setup)
# module "ec2" {
#   source = "../../modules/ec2"
#
#   project     = var.project
#   environment = var.environment
#   iam_role_arn = module.iam.ec2_role_arn
#   iam_instance_profile_name = module.iam.ec2_instance_profile_name
#   instance_type = var.instance_type
#   key_name      = var.key_name
#   root_volume_size = var.root_volume_size
#   create_elastic_ip = var.create_elastic_ip
#   detailed_monitoring_enabled = var.detailed_monitoring_enabled
#   vpc_id        = module.networking.vpc_id
#   subnet_id     = module.networking.public_subnet_ids[0]  # Using the first public subnet
#   users         = var.users
# }

# Lambda Module for File Watcher
module "lambda_file_watcher" {
  source = "../../modules/lambda"

  project       = var.project
  environment   = var.environment
  function_name = "file-watcher"
  runtime       = "python3.12"
  handler       = "lambda_handler.lambda_handler"
  timeout       = 60
  memory_size   = 512
  description   = "Lambda function to process S3 file changes for backend-db-registration"

  # Lambda function source code
  source_dir  = "${path.root}/../../lambda_functions/file-watcher"
  output_path = "${path.root}/../../lambda_functions/file-watcher.zip"

  # Environment variables for Lambda function
  environment_variables = {
    ENVIRONMENT = var.environment
    PROJECT     = var.project
    # Add more environment variables as needed (DynamoDB table name, etc.)
  }

  # IAM permissions
  enable_s3_access = true
  s3_bucket_arns   = [module.s3.bucket_arn]

  # DynamoDB access will be enabled when DynamoDB module is created
  enable_dynamodb_access = false
  # dynamodb_table_arns    = [module.dynamodb.table_arn]

  # Secrets Manager access not needed for file-watcher
  enable_secrets_manager_access = false

  # VPC configuration (disabled for now, enable when needed for PostgreSQL/RDS)
  enable_vpc = false
  # vpc_subnet_ids         = module.networking.private_subnet_ids
  # vpc_security_group_ids = [module.networking.default_security_group_id]

  # CloudWatch Logs
  log_retention_days = 30
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  project                    = var.project
  environment                = var.environment
  bucket_name                = var.s3_bucket_name
  enable_versioning          = var.s3_enable_versioning
  block_public_access        = var.s3_block_public_access
  enable_lifecycle_rules     = var.s3_enable_lifecycle_rules
  transition_to_ia_days      = var.s3_transition_to_ia_days
  transition_to_glacier_days = var.s3_transition_to_glacier_days
  expiration_days            = var.s3_expiration_days

  # Lambda notification configuration
  enable_lambda_notification = true
  lambda_function_arn        = module.lambda_file_watcher.function_arn
  lambda_function_name       = module.lambda_file_watcher.function_name
  notification_events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  notification_filter_prefix = "data/"
  notification_filter_suffix = ".yaml"
}

# IAM Users Module
module "iam_users" {
  source = "../../modules/iam-users"

  project     = var.project
  environment = var.environment

  team_members = var.team_members

  # Attach Secrets Manager access policies (lambda, app, and db secrets)
  secrets_manager_policy_arns = merge(
    {
      lambda_secrets = module.secrets_manager_lambda.access_policy_arn
      app_secrets    = module.secrets_manager_app.access_policy_arn
    },
    var.create_rds ? { db_credentials = module.rds[0].db_credentials_access_policy_arn } : {}
  )

  # Grant access to S3 bucket
  s3_bucket_arn = module.s3.bucket_arn

  # Instance management permissions (RDS and EC2 start/stop)
  # Note: Using wildcard pattern to avoid circular dependency with bastion module
  enable_instance_management = var.create_rds || var.create_bastion
  rds_instance_arns          = var.create_rds ? [module.rds[0].db_instance_arn] : []
  ec2_instance_arns          = var.create_bastion ? ["arn:aws:ec2:*:*:instance/*"] : []
}

# =============================================================================
# RDS PostgreSQL
# =============================================================================

# Security Group for Lambda to access RDS
resource "aws_security_group" "lambda" {
  count = var.create_rds ? 1 : 0

  name        = "${var.project}-${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = module.networking.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# RDS Module
module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  instance_class    = var.rds_instance_class
  engine_version    = var.rds_engine_version
  allocated_storage = var.rds_allocated_storage
  multi_az          = var.rds_multi_az

  # Allow access from Lambda and Bastion
  allowed_security_group_ids = concat(
    var.create_rds ? [aws_security_group.lambda[0].id] : [],
    var.create_bastion ? [module.bastion[0].security_group_id] : []
  )
}

# =============================================================================
# Bastion Host
# =============================================================================

module "bastion" {
  count  = var.create_bastion ? 1 : 0
  source = "../../modules/bastion"

  project     = var.project
  environment = var.environment

  vpc_id    = module.networking.vpc_id
  subnet_id = module.networking.public_subnet_ids[0]

  instance_type     = var.bastion_instance_type
  use_spot_instance = var.bastion_use_spot

  # SSH public keys from team members
  ssh_public_keys = module.iam_users.ssh_public_keys

  allowed_ssh_cidr_blocks = var.ssh_allowed_cidr_blocks
}
