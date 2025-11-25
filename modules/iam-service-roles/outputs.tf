output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.service_role.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.service_role.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.service_role.id
}
