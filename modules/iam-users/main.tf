# IAM Group for project team members
resource "aws_iam_group" "developers" {
  name = "${var.project}-${var.environment}-developers"
  path = "/"
}

# Attach Secrets Manager access policy to group
resource "aws_iam_group_policy_attachment" "secrets_manager_access" {
  count      = var.secrets_manager_policy_arn != null ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = var.secrets_manager_policy_arn
}

# Attach S3 access policy to group (if provided)
resource "aws_iam_group_policy_attachment" "s3_access" {
  count      = var.s3_policy_arn != null ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = var.s3_policy_arn
}

# Custom policy for S3 access (if no external policy provided)
resource "aws_iam_policy" "s3_access" {
  count       = var.s3_policy_arn == null && var.s3_bucket_arn != null ? 1 : 0
  name        = "${var.project}-${var.environment}-s3-access-policy"
  description = "Policy to allow access to project S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = var.s3_bucket_arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# Attach custom S3 policy to group
resource "aws_iam_group_policy_attachment" "s3_access_custom" {
  count      = var.s3_policy_arn == null && var.s3_bucket_arn != null ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# IAM Users
resource "aws_iam_user" "members" {
  for_each = { for user in var.team_members : user.username => user }

  name = "${var.project}-${var.environment}-${each.value.username}"
  path = "/"

  tags = {
    Name        = "${var.project}-${var.environment}-${each.value.username}"
    Environment = var.environment
    Project     = var.project
    Role        = each.value.role
  }
}

# Add users to developers group
resource "aws_iam_user_group_membership" "members" {
  for_each = { for user in var.team_members : user.username => user }

  user = aws_iam_user.members[each.key].name

  groups = [
    aws_iam_group.developers.name
  ]
}

# Create access keys for users (optional)
resource "aws_iam_access_key" "members" {
  for_each = { for user in var.team_members : user.username => user if user.create_access_key }

  user = aws_iam_user.members[each.key].name
}

# Enable console access (optional)
resource "aws_iam_user_login_profile" "members" {
  for_each = { for user in var.team_members : user.username => user if user.console_access }

  user                    = aws_iam_user.members[each.key].name
  password_reset_required = true
}
