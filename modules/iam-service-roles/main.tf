# IAM Role for Service (Discord Bot, etc.)
# This role can be assumed by Lambda, ECS, or other compute services

# Trust policy - which services can assume this role
data "aws_iam_policy_document" "assume_role" {
  # Lambda
  dynamic "statement" {
    for_each = var.enable_lambda_assume ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }
    }
  }

  # ECS Tasks
  dynamic "statement" {
    for_each = var.enable_ecs_assume ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
    }
  }

  # EC2
  dynamic "statement" {
    for_each = var.enable_ec2_assume ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }
    }
  }
}

# IAM Role
resource "aws_iam_role" "service_role" {
  name               = "${var.project}-${var.environment}-${var.role_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-${var.role_name}"
    Environment = var.environment
    Project     = var.project
  }
}

# Secrets Manager Access Policy
resource "aws_iam_policy" "secrets_manager_access" {
  count       = var.enable_secrets_manager_access ? 1 : 0
  name        = "${var.project}-${var.environment}-${var.role_name}-secrets-policy"
  description = "Secrets Manager access for ${var.role_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_secret_arns
      },
      {
        Sid    = "ListSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  count      = var.enable_secrets_manager_access ? 1 : 0
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.secrets_manager_access[0].arn
}

# DynamoDB Access Policy
resource "aws_iam_policy" "dynamodb_access" {
  count       = var.enable_dynamodb_access ? 1 : 0
  name        = "${var.project}-${var.environment}-${var.role_name}-dynamodb-policy"
  description = "DynamoDB access for ${var.role_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = var.dynamodb_table_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  count      = var.enable_dynamodb_access ? 1 : 0
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.dynamodb_access[0].arn
}

# CloudWatch Logs Policy (for Lambda)
resource "aws_iam_policy" "cloudwatch_logs" {
  count       = var.enable_cloudwatch_logs ? 1 : 0
  name        = "${var.project}-${var.environment}-${var.role_name}-logs-policy"
  description = "CloudWatch Logs access for ${var.role_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/*/${var.project}-${var.environment}-*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  count      = var.enable_cloudwatch_logs ? 1 : 0
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs[0].arn
}
