# ------------------------------------------------------------
# Secrets Manager Outputs
# ------------------------------------------------------------

output "secrets_manager_lambda_secret_arn" {
  description = "ARN of the Lambda Secrets Manager secret"
  value       = module.secrets_manager_lambda.secret_arn
  sensitive   = true
}

output "secrets_manager_lambda_secret_name" {
  description = "Name of the Lambda Secrets Manager secret"
  value       = module.secrets_manager_lambda.secret_name
}

output "secrets_manager_app_secret_arn" {
  description = "ARN of the App Secrets Manager secret"
  value       = module.secrets_manager_app.secret_arn
  sensitive   = true
}

output "secrets_manager_app_secret_name" {
  description = "Name of the App Secrets Manager secret"
  value       = module.secrets_manager_app.secret_name
}

# ------------------------------------------------------------
# IAM Service Roles Outputs
# ------------------------------------------------------------

output "discord_bot_role_arn" {
  description = "ARN of the Discord Bot IAM role"
  value       = module.iam_discord_bot.role_arn
}

output "discord_bot_role_name" {
  description = "Name of the Discord Bot IAM role"
  value       = module.iam_discord_bot.role_name
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

# ------------------------------------------------------------
# RDS Outputs
# ------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_rds ? module.rds[0].db_instance_endpoint : null
}

output "rds_address" {
  description = "RDS instance address"
  value       = var.create_rds ? module.rds[0].db_instance_address : null
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.create_rds ? module.rds[0].db_instance_port : null
}

output "rds_db_name" {
  description = "RDS database name"
  value       = var.create_rds ? module.rds[0].db_name : null
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials"
  value       = var.create_rds ? module.rds[0].db_credentials_secret_arn : null
  sensitive   = true
}

# ------------------------------------------------------------
# Bastion Outputs
# ------------------------------------------------------------

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = var.create_bastion ? module.bastion[0].instance_id : null
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = var.create_bastion ? module.bastion[0].public_ip : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to Bastion"
  value       = var.create_bastion ? module.bastion[0].ssh_connection_command : null
}

output "rds_ssh_tunnel_command" {
  description = "SSH tunnel command to connect to RDS via Bastion"
  value       = var.create_rds && var.create_bastion ? "ssh -L 5432:${module.rds[0].db_instance_address}:5432 ec2-user@${module.bastion[0].public_ip}" : null
}
