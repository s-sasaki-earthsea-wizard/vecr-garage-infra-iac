# ------------------------------------------------------------
# Secrets Manager Outputs
# ------------------------------------------------------------

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.secrets_manager.secret_arn
  sensitive   = true
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = module.secrets_manager.secret_name
}

output "secrets_manager_access_policy_arn" {
  description = "ARN of the IAM policy for accessing the secret"
  value       = module.secrets_manager.access_policy_arn
}

# ------------------------------------------------------------
# S3 Outputs
# ------------------------------------------------------------

output "s3_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3.bucket_name
}

# ------------------------------------------------------------
# Networking Outputs
# ------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# ------------------------------------------------------------
# IAM Users Outputs
# ------------------------------------------------------------

output "iam_group_name" {
  description = "Name of the IAM developers group"
  value       = module.iam_users.group_name
}

output "iam_user_names" {
  description = "Map of usernames to IAM user names"
  value       = module.iam_users.user_names
}

output "iam_access_keys" {
  description = "Map of usernames to access key IDs (use terraform output -json to see)"
  value       = module.iam_users.access_keys
  sensitive   = true
}

output "iam_secret_access_keys" {
  description = "Map of usernames to secret access keys (use terraform output -json to see)"
  value       = module.iam_users.secret_access_keys
  sensitive   = true
}
