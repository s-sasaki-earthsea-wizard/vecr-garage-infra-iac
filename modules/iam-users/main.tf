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
  count       = var.s3_policy_arn == null ? 1 : 0
  name        = "${var.project}-${var.environment}-s3-access-policy"
  description = "Policy to allow access to project S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:ListBucket"
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
  count      = var.s3_policy_arn == null ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# CloudWatch Logs read-only access policy
resource "aws_iam_policy" "cloudwatch_logs_readonly" {
  name        = "${var.project}-${var.environment}-cloudwatch-logs-readonly-policy"
  description = "Policy to allow read-only access to CloudWatch Logs for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsReadOnly"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project}-${var.environment}-*",
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project}-${var.environment}-*:*"
        ]
      }
    ]
  })
}

# Attach CloudWatch Logs policy to group
resource "aws_iam_group_policy_attachment" "cloudwatch_logs_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.cloudwatch_logs_readonly.arn
}

# IAM Self-Service Policy (allow users to manage their own credentials)
resource "aws_iam_policy" "self_service" {
  name        = "${var.project}-${var.environment}-iam-self-service-policy"
  description = "Policy to allow users to manage their own credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUsersToChangeTheirOwnPassword"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowUsersToGetTheirOwnAccountInformation"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:GetUser"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowUsersToManageTheirOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:DeactivateMFADevice"
        ]
        Resource = [
          "arn:aws:iam::*:user/$${aws:username}",
          "arn:aws:iam::*:mfa/$${aws:username}"
        ]
      },
      {
        Sid    = "AllowUsersToListMFADevices"
        Effect = "Allow"
        Action = [
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowUsersToManageTheirOwnAccessKeys"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:ListAccessKeys"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })
}

# Attach self-service policy to group
resource "aws_iam_group_policy_attachment" "self_service" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.self_service.arn
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
