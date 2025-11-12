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
}
