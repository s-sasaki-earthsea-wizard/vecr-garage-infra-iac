# IAM Group for project team members
resource "aws_iam_group" "developers" {
  name = "${var.project}-${var.environment}-developers"
  path = "/"
}

# Attach Secrets Manager access policies to group
resource "aws_iam_group_policy_attachment" "secrets_manager_access" {
  for_each   = var.secrets_manager_policy_arns
  group      = aws_iam_group.developers.name
  policy_arn = each.value
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

# =============================================================================
# Instance Management Policies (RDS and EC2 start/stop)
# =============================================================================

# RDS Instance Management Policy
resource "aws_iam_policy" "rds_management" {
  count = var.enable_instance_management && length(var.rds_instance_arns) > 0 ? 1 : 0

  name        = "${var.project}-${var.environment}-rds-management-policy"
  description = "Policy to allow developers to start/stop RDS instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RDSInstanceManagement"
        Effect = "Allow"
        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = var.rds_instance_arns
      },
      {
        Sid    = "RDSDescribe"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "rds_management" {
  count = var.enable_instance_management && length(var.rds_instance_arns) > 0 ? 1 : 0

  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.rds_management[0].arn
}

# EC2 Instance Management Policy (restricted by Project tag)
resource "aws_iam_policy" "ec2_management" {
  count = var.enable_instance_management && length(var.ec2_instance_arns) > 0 ? 1 : 0

  name        = "${var.project}-${var.environment}-ec2-management-policy"
  description = "Policy to allow developers to start/stop EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2InstanceManagement"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = var.ec2_instance_arns
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = var.project
          }
        }
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "ec2_management" {
  count = var.enable_instance_management && length(var.ec2_instance_arns) > 0 ? 1 : 0

  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ec2_management[0].arn
}

# =============================================================================
# IAM Users
# =============================================================================

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
