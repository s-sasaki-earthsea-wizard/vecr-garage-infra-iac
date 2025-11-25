# ------------------------------------------------------------
# Lambda Deployment Package
# ------------------------------------------------------------

# Archive the Lambda function source code
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = var.output_path != "" ? var.output_path : "${path.module}/lambda_function.zip"
}

# ------------------------------------------------------------
# CloudWatch Logs Group
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}-${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "/aws/lambda/${var.project}-${var.environment}-${var.function_name}"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}

# ------------------------------------------------------------
# Lambda Function
# ------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = "${var.project}-${var.environment}-${var.function_name}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  description   = var.description != "" ? var.description : "Lambda function for ${var.function_name}"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # Ensure CloudWatch Logs group is created before Lambda function
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(
    {
      Name        = "${var.project}-${var.environment}-${var.function_name}"
      Environment = var.environment
      Project     = var.project
    },
    var.tags
  )
}
