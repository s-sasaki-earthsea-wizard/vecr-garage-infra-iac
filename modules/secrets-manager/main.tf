# Secrets Manager Secret
resource "aws_secretsmanager_secret" "secret" {
  name        = "${var.project}-${var.environment}-${var.secret_name}"
  description = var.description
  
  recovery_window_in_days = var.recovery_window_in_days
  
  tags = {
    Name        = "${var.project}-${var.environment}-${var.secret_name}"
    Environment = var.environment
    Project     = var.project
  }
}

# Initial secret version
resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_value != null ? var.secret_value : jsonencode(var.secret_map)
}

# IAM Policy for accessing this secret
resource "aws_iam_policy" "secret_access" {
  count       = var.create_access_policy ? 1 : 0
  name        = "${var.project}-${var.environment}-${var.secret_name}-access-policy"
  description = "Policy to allow access to ${var.secret_name} secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.secret.arn
      },
      {
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.secret.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.secret.name
}

output "access_policy_arn" {
  description = "ARN of the IAM policy for accessing the secret"
  value       = var.create_access_policy ? aws_iam_policy.secret_access[0].arn : null
}