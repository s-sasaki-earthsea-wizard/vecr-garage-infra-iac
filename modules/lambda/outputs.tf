# ------------------------------------------------------------
# Lambda Function Outputs
# ------------------------------------------------------------

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_invoke_arn" {
  description = "The Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "The qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "The version of the Lambda function"
  value       = aws_lambda_function.this.version
}

# ------------------------------------------------------------
# IAM Role Outputs
# ------------------------------------------------------------

output "role_name" {
  description = "The name of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.name
}

output "role_arn" {
  description = "The ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}

# ------------------------------------------------------------
# CloudWatch Logs Outputs
# ------------------------------------------------------------

output "log_group_name" {
  description = "The name of the CloudWatch Logs group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Logs group"
  value       = aws_cloudwatch_log_group.lambda.arn
}
