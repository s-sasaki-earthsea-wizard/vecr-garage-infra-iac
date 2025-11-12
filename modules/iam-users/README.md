# IAM Users Module

This module manages IAM users, groups, and access policies for team members.

## Features

- Creates an IAM group for project team members
- Attaches Secrets Manager and S3 access policies to the group
- Creates IAM users and adds them to the group
- Optionally creates access keys for programmatic access
- Optionally enables AWS Console access with password

## Usage

```hcl
module "iam_users" {
  source = "../../modules/iam-users"

  project     = "my-project"
  environment = "dev"

  team_members = [
    {
      username          = "admin"
      role              = "admin"
      create_access_key = true
      console_access    = false
    },
    {
      username          = "developer1"
      role              = "developer"
      create_access_key = true
      console_access    = true
    }
  ]

  secrets_manager_policy_arn = module.secrets_manager.access_policy_arn
  s3_bucket_arn             = module.s3.bucket_arn
}
```

## Access Keys Management

After applying Terraform, retrieve access keys for team members:

```bash
# View all access keys (JSON format)
terraform output -json iam_access_keys

# View all secret access keys (JSON format)
terraform output -json iam_secret_access_keys

# Extract specific user's credentials
terraform output -json iam_access_keys | jq -r '.admin'
terraform output -json iam_secret_access_keys | jq -r '.admin'
```

## Console Access

When `console_access = true`, users can log in to the AWS Console with:
- Username: `{project}-{environment}-{username}`
- Password: Temporary password (must be reset on first login)

To get the temporary password, check Terraform state or use AWS Console to send a password reset link.

## Security Best Practices

1. **Do not commit `terraform.tfvars`** - It contains sensitive information
2. **Store access keys securely** - Use a password manager or secret management tool
3. **Rotate access keys regularly** - Set up a rotation policy
4. **Use MFA** - Enable multi-factor authentication for console users
5. **Principle of least privilege** - Grant only necessary permissions

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| team_members | List of team members | list(object) | [] | no |
| secrets_manager_policy_arn | Secrets Manager policy ARN | string | null | no |
| s3_policy_arn | S3 policy ARN | string | null | no |
| s3_bucket_arn | S3 bucket ARN | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| group_name | Name of the IAM group |
| group_arn | ARN of the IAM group |
| user_names | Map of usernames to IAM user names |
| user_arns | Map of usernames to IAM user ARNs |
| access_keys | Map of usernames to access key IDs (sensitive) |
| secret_access_keys | Map of usernames to secret access keys (sensitive) |
