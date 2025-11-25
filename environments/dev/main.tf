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

# Secrets Manager Module for storing sensitive information
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project     = var.project
  environment = var.environment
  secret_name = "secrets-${var.secrets_version}"
  description = "Secrets for ${var.project} ${var.environment} environment"

  secret_map = {
    project             = var.project
    environment         = var.environment
    open_router_api_key = var.open_router_api_key
    created_at          = timestamp()
    initial_setup       = "completed"
  }

  create_access_policy = true
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  create_nat_gateway = var.create_nat_gateway
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

  # Attach Secrets Manager access policy
  secrets_manager_policy_arn = module.secrets_manager.access_policy_arn

  # Grant access to S3 bucket
  s3_bucket_arn = module.s3.bucket_arn
}
