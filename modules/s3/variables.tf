variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name suffix (will be prefixed with project and environment)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Block all public access to S3 bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules for S3 bucket"
  type        = bool
  default     = false
}

variable "transition_to_ia_days" {
  description = "Number of days before transitioning objects to STANDARD_IA"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Number of days before transitioning objects to GLACIER"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Number of days before objects expire"
  type        = number
  default     = 365
}

# ------------------------------------------------------------
# Lambda Event Notification Configuration
# ------------------------------------------------------------

variable "enable_lambda_notification" {
  description = "Enable Lambda function notification for S3 events"
  type        = bool
  default     = false
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger on S3 events"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to trigger on S3 events"
  type        = string
  default     = ""
}

variable "notification_events" {
  description = "List of S3 events that trigger the Lambda function"
  type        = list(string)
  default     = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
}

variable "notification_filter_prefix" {
  description = "S3 object key prefix filter for notifications (e.g., 'data/')"
  type        = string
  default     = ""
}

variable "notification_filter_suffix" {
  description = "S3 object key suffix filter for notifications (e.g., '.yaml')"
  type        = string
  default     = ""
}
