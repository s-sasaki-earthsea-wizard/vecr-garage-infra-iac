variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "team_members" {
  description = "List of team members with their configurations"
  type = list(object({
    username          = string
    role              = string
    create_access_key = bool
    console_access    = bool
  }))
  default = []
}

variable "secrets_manager_policy_arns" {
  description = "Map of Secrets Manager access policy ARNs to attach (key => arn)"
  type        = map(string)
  default     = {}
}

variable "s3_policy_arn" {
  description = "ARN of the S3 access policy to attach (optional)"
  type        = string
  default     = null
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for access policy (used if s3_policy_arn is not provided)"
  type        = string
  default     = null
}
