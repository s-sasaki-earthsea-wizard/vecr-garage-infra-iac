# ------------------------------------------------------------
# AWS Configuration
# ------------------------------------------------------------

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

# ------------------------------------------------------------
# Environment Configuration
# ------------------------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------
# LLM API Configuration
# ------------------------------------------------------------

variable "anthropic_api_key" {
  description = "Anthropic API Key"
  type        = string
  sensitive   = true
}

variable "open_router_api_key" {
  description = "OpenRouter API Key"
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------
# Discord Configuration
# ------------------------------------------------------------

variable "discord_bot_tokens" {
  description = "Discord Bot Tokens (bot_name => token)"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "discord_webhooks" {
  description = "Discord Webhook URLs (webhook_name => url)"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# ------------------------------------------------------------
# Flask Configuration
# ------------------------------------------------------------

variable "flask_secret_key" {
  description = "Flask Session Secret Key"
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------
# EC2 Configuration
# ------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
}

variable "create_elastic_ip" {
  description = "Whether to create and associate an Elastic IP"
  type        = bool
}

variable "detailed_monitoring_enabled" {
  description = "Whether to enable detailed monitoring"
  type        = bool
}

# ------------------------------------------------------------
# Networking Configuration
# ------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Create NAT gateway"
  type        = bool
  default     = false
}

# ------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------

variable "ssh_allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "users" {
  description = "List of users to create with their SSH keys"
  type = list(object({
    username = string
    ssh_keys = list(string)
  }))
  default = []
}

# ------------------------------------------------------------
# S3 Configuration
# ------------------------------------------------------------

variable "s3_bucket_name" {
  description = "S3 bucket name suffix"
  type        = string
  default     = "storage"
}

variable "s3_enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_block_public_access" {
  description = "Block all public access to S3 bucket"
  type        = bool
  default     = true
}

variable "s3_enable_lifecycle_rules" {
  description = "Enable lifecycle rules for S3 bucket"
  type        = bool
  default     = false
}

variable "s3_transition_to_ia_days" {
  description = "Number of days before transitioning objects to STANDARD_IA"
  type        = number
  default     = 30
}

variable "s3_transition_to_glacier_days" {
  description = "Number of days before transitioning objects to GLACIER"
  type        = number
  default     = 90
}

variable "s3_expiration_days" {
  description = "Number of days before objects expire"
  type        = number
  default     = 365
}

# ------------------------------------------------------------
# IAM Users Configuration
# ------------------------------------------------------------

variable "team_members" {
  description = "List of team members with their IAM configurations"
  type = list(object({
    username          = string
    role              = string
    create_access_key = bool
    console_access    = bool
    ssh_public_key    = optional(string, "")
  }))
  default = []
}

# ------------------------------------------------------------
# RDS Configuration
# ------------------------------------------------------------

variable "create_rds" {
  description = "Whether to create RDS instance"
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

# ------------------------------------------------------------
# Bastion Configuration
# ------------------------------------------------------------

variable "create_bastion" {
  description = "Whether to create Bastion host"
  type        = bool
  default     = false
}

variable "bastion_instance_type" {
  description = "Bastion EC2 instance type"
  type        = string
  default     = "t4g.nano"
}

variable "bastion_use_spot" {
  description = "Use spot instance for Bastion (On-Demand recommended for start/stop support)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------
# VPC Endpoints Configuration
# ------------------------------------------------------------

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = false
}
