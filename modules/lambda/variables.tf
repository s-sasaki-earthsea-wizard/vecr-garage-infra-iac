# ------------------------------------------------------------
# Basic Configuration
# ------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function (will be prefixed with project and environment)"
  type        = string
}

# ------------------------------------------------------------
# Lambda Function Configuration
# ------------------------------------------------------------

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda_handler.lambda_handler"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

# ------------------------------------------------------------
# Lambda Code Configuration
# ------------------------------------------------------------

variable "source_dir" {
  description = "Path to the directory containing Lambda function source code"
  type        = string
}

variable "output_path" {
  description = "Path where the Lambda deployment package will be saved"
  type        = string
  default     = ""
}

# ------------------------------------------------------------
# VPC Configuration
# ------------------------------------------------------------

variable "enable_vpc" {
  description = "Enable VPC configuration for Lambda function"
  type        = bool
  default     = false
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------

variable "environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------
# IAM Permissions Configuration
# ------------------------------------------------------------

variable "enable_s3_access" {
  description = "Enable S3 access for this Lambda function"
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to grant access"
  type        = list(string)
  default     = []
}

variable "enable_dynamodb_access" {
  description = "Enable DynamoDB access for this Lambda function"
  type        = bool
  default     = false
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs to grant access"
  type        = list(string)
  default     = []
}

variable "enable_secrets_manager_access" {
  description = "Enable Secrets Manager access for this Lambda function"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs to grant access"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------
# CloudWatch Logs Configuration
# ------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
}

# ------------------------------------------------------------
# Tags
# ------------------------------------------------------------

variable "tags" {
  description = "Additional tags for Lambda function"
  type        = map(string)
  default     = {}
}
