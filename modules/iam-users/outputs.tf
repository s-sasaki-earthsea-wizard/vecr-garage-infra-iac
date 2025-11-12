output "group_name" {
  description = "Name of the IAM group"
  value       = aws_iam_group.developers.name
}

output "group_arn" {
  description = "ARN of the IAM group"
  value       = aws_iam_group.developers.arn
}

output "user_names" {
  description = "Map of usernames to IAM user names"
  value       = { for k, v in aws_iam_user.members : k => v.name }
}

output "user_arns" {
  description = "Map of usernames to IAM user ARNs"
  value       = { for k, v in aws_iam_user.members : k => v.arn }
}

output "access_keys" {
  description = "Map of usernames to access key IDs (sensitive)"
  value       = { for k, v in aws_iam_access_key.members : k => v.id }
  sensitive   = true
}

output "secret_access_keys" {
  description = "Map of usernames to secret access keys (sensitive)"
  value       = { for k, v in aws_iam_access_key.members : k => v.secret }
  sensitive   = true
}

output "s3_access_policy_arn" {
  description = "ARN of the S3 access policy (if created)"
  value       = length(aws_iam_policy.s3_access) > 0 ? aws_iam_policy.s3_access[0].arn : null
}
