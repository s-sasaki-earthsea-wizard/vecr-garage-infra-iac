variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role (will be prefixed with project-environment-)"
  type        = string
}

# Trust Policy - Which services can assume this role
variable "enable_lambda_assume" {
  description = "Allow Lambda to assume this role"
  type        = bool
  default     = true
}

variable "enable_ecs_assume" {
  description = "Allow ECS tasks to assume this role"
  type        = bool
  default     = false
}

variable "enable_ec2_assume" {
  description = "Allow EC2 to assume this role"
  type        = bool
  default     = false
}

# Secrets Manager Access
variable "enable_secrets_manager_access" {
  description = "Enable Secrets Manager access"
  type        = bool
  default     = false
}

variable "secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs to grant access to"
  type        = list(string)
  default     = []
}

# DynamoDB Access
variable "enable_dynamodb_access" {
  description = "Enable DynamoDB access"
  type        = bool
  default     = false
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs to grant access to"
  type        = list(string)
  default     = []
}

# CloudWatch Logs
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs access"
  type        = bool
  default     = true
}
