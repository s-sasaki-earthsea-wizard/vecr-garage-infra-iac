# S3 Bucket for project storage
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name != "" ? "${var.project}-${var.environment}-${var.bucket_name}" : "${var.project}-${var.environment}"

  tags = {
    Name        = var.bucket_name != "" ? "${var.project}-${var.environment}-${var.bucket_name}" : "${var.project}-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# S3 Bucket Lifecycle Configuration (optional)
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# ------------------------------------------------------------
# Lambda Event Notification Configuration
# ------------------------------------------------------------

# Lambda permission to allow S3 to invoke the function
resource "aws_lambda_permission" "allow_s3_invoke" {
  count = var.enable_lambda_notification ? 1 : 0

  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "lambda_trigger" {
  count  = var.enable_lambda_notification ? 1 : 0
  bucket = aws_s3_bucket.main.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = var.notification_events
    filter_prefix       = var.notification_filter_prefix
    filter_suffix       = var.notification_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
