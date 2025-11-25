# ------------------------------------------------------------
# Lambda Execution Role
# ------------------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-${var.environment}-lambda-${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-role"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

# ------------------------------------------------------------
# CloudWatch Logs Policy (Always attached)
# ------------------------------------------------------------

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project}-${var.environment}-lambda-${var.function_name}-cloudwatch-logs"
  description = "Allow Lambda function to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-cloudwatch-logs"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# ------------------------------------------------------------
# VPC Access Policy (Conditional - for VPC Lambda)
# ------------------------------------------------------------

resource "aws_iam_policy" "vpc_access" {
  count = var.enable_vpc ? 1 : 0

  name        = "${var.project}-${var.environment}-lambda-${var.function_name}-vpc-access"
  description = "Allow Lambda function to manage ENIs in VPC"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-vpc-access"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.enable_vpc ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.vpc_access[0].arn
}

# ------------------------------------------------------------
# S3 Access Policy (Conditional)
# ------------------------------------------------------------

resource "aws_iam_policy" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  name        = "${var.project}-${var.environment}-lambda-${var.function_name}-s3-access"
  description = "Allow Lambda function to read from S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          for arn in var.s3_bucket_arns : "${arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-s3-access"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# ------------------------------------------------------------
# DynamoDB Access Policy (Conditional)
# ------------------------------------------------------------

resource "aws_iam_policy" "dynamodb_access" {
  count = var.enable_dynamodb_access ? 1 : 0

  name        = "${var.project}-${var.environment}-lambda-${var.function_name}-dynamodb-access"
  description = "Allow Lambda function to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
        Resource = concat(
          var.dynamodb_table_arns,
          [for arn in var.dynamodb_table_arns : "${arn}/index/*"]
        )
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-dynamodb-access"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  count = var.enable_dynamodb_access ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access[0].arn
}

# ------------------------------------------------------------
# Secrets Manager Access Policy (Conditional)
# ------------------------------------------------------------

resource "aws_iam_policy" "secrets_manager_access" {
  count = var.enable_secrets_manager_access ? 1 : 0

  name        = "${var.project}-${var.environment}-lambda-${var.function_name}-secrets-manager-access"
  description = "Allow Lambda function to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_arns
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-lambda-${var.function_name}-secrets-manager-access"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  count = var.enable_secrets_manager_access ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.secrets_manager_access[0].arn
}
