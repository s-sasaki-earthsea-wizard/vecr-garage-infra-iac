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
