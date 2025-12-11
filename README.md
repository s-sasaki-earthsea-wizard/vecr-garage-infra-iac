# VECR Garage Infrastructure terraform

## 概要

VECRのオフィスインフラストラクチャを管理するためのTerraformプロジェクトです。
AWS上に必要なリソースを構築・管理します。

## プロジェクト構造

```
.
├── environments/          # 環境ごとの設定
│   ├── dev/             # 開発環境
│   ├── prod/            # 本番環境
│   └── staging/         # ステージング環境
├── global/              # グローバルリソース
│   └── iam-global/      # グローバルIAMポリシー
├── modules/             # 再利用可能なTerraformモジュール
│   ├── bastion/        # Bastionホスト（SSHジャンプサーバー）
│   ├── ec2/            # EC2インスタンス関連
│   ├── iam/            # IAMロール・ポリシー関連
│   ├── iam-service-roles/ # サービス用IAMロール
│   ├── iam-users/      # IAMユーザー管理
│   ├── lambda/         # Lambda関数関連
│   ├── networking/     # ネットワーク関連（VPC Endpoints含む）
│   ├── rds/            # RDS PostgreSQL関連
│   ├── s3/             # S3バケット関連
│   └── secrets-manager/# Secrets Manager関連
├── lambda_functions/   # Lambda関数のソースコード
│   └── file-watcher/   # S3イベント監視用Lambda（プレースホルダー）
└── terraform.tfvars     # 環境変数ファイル
```

## 開発環境

- OS: Ubuntu 24.04.1 LTS
- Terraform: v1.11.3
- AWS CLI: 2.25.6

### TerraformとAWS CLIのインストール

以下の公式ドキュメントを参照し、各自の環境に合わせてインストールをしてください。

- Terraform: https://developer.hashicorp.com/terraform/install
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## セットアップ

1. 必要な環境変数を設定します：
   ```bash
   cp .env.sample .env
   # .envファイルを編集して必要な値を設定
   ```

2. AWS認証情報を設定します：
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # terraform.tfvarsファイルを編集して必要な値を設定
   ```

## 使い方

### 初期化

```bash
make init
```
- 指定された環境のTerraformを初期化します
- 必要なプロバイダーやモジュールをダウンロードします

### 実行計画の作成

```bash
make plan
```
- インフラの変更計画を作成します
- 変更内容を確認できます

### インフラの適用

```bash
make apply
```
- 実行計画に基づいてインフラを構築・更新します

### インフラの削除

```bash
make destroy
```
- 構築したインフラを削除します
- 注意: 本番環境では使用しないでください

## 環境変数

以下の環境変数が必要です：
- `AWS_PROFILE`: AWS認証プロファイル名
- `ENVIRONMENT`: 対象環境（dev/staging/prod）
- `PROJECT`: プロジェクト名

## Tips 

### キーペアの作成

キーペアは例えば以下のようなコマンドで作成します:

```bash
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > ~/.aws/vecr-ssh-key.pem
```

### Secrets Managerの操作

APIキーなどのセンシティブな情報はAWS Secrets Managerで管理されています。

#### シークレットの構成

| シークレット名 | 用途 | 含まれるキー |
|---------------|------|-------------|
| `vecr-garage-dev-lambda-secrets` | Lambda関数用 | LLM APIキー、Discord Bot Token、Webhook URL |
| `vecr-garage-dev-app-secrets` | アプリケーション用 | Flask Secret Key など |
| `vecr-garage-dev-db-credentials` | RDS認証情報 | host, port, username, password, dbname |

#### Makeターゲットで操作

```bash
# プロジェクトの全シークレット一覧
make secret-list-all

# Lambda secretsのキー一覧（デフォルト）
make secret-list

# App secretsのキー一覧
make secret-list SECRET=app-secrets

# 特定のキーの値を取得
make secret-get KEY=anthropic_api_key

# App secretsから取得
make secret-get KEY=flask_secret_key SECRET=app-secrets
```

#### AWS CLIで直接操作

```bash
# IAMユーザーのプロフィール名を指定してクエリ
aws secretsmanager get-secret-value \
  --secret-id vecr-garage-dev-lambda-secrets \
  --profile vecr-garage-dev-<username> \
  | jq -r '.SecretString | fromjson | .open_router_api_key'
```

#### 新しいシークレットの追加方法

Discord Botやwebhookを追加する場合、`terraform.tfvars`のmap変数に追加するだけで自動的にSecrets Managerに反映されます：

```hcl
discord_bot_tokens = {
  kasen         = "..."
  karasuno_endo = "..."
  new_bot       = "新しいトークン"  # ← 追加
}
```

## RDS PostgreSQL

### 概要

プライベートサブネット内にRDS PostgreSQLインスタンスをデプロイし、Bastionホスト経由でアクセスします。

### アーキテクチャ

```
Internet → Bastion (Public Subnet) → RDS PostgreSQL (Private Subnet)
```

- **RDS**: PostgreSQL 16、db.t4g.micro、暗号化有効
- **Bastion**: Ubuntu 24.04 Minimal (ARM64)、On-Demandインスタンス、psqlプリインストール
- **VPC Endpoints**: NAT Gateway不要でSecretsManager/S3にアクセス

### 接続方法

#### 1. 認証情報の確認

```bash
make rds-credentials
```

出力例:
```
============================================================
RDS Connection Credentials
============================================================
Host:     vecr-garage-dev-db.xxx.ap-northeast-1.rds.amazonaws.com
Port:     5432
Database: vecr
Username: vecr_admin
Password: xxxxxxxx
============================================================
```

#### 2. Bastion経由でRDSに接続

```bash
# Bastionにログイン
make ssh-bastion

# Bastion上でpsqlを実行
psql -h <RDS_HOST> -U vecr_admin -d vecr
```

#### 3. SSHトンネル経由（ローカルから接続）

```bash
# ターミナル1: SSHトンネルを作成
make rds-tunnel

# ターミナル2: ローカルからpsqlで接続
psql -h localhost -p 5432 -U vecr_admin -d vecr
```

### Makeターゲット

| ターゲット | 説明 |
|-----------|------|
| `make ssh-bastion` | Bastionホストに接続 |
| `make rds-tunnel` | RDSへのSSHトンネルを作成（localhost:5432） |
| `make rds-credentials` | RDS認証情報を表示 |

## Lambda関数のテスト

### 概要

このプロジェクトでは、S3イベント通知をトリガーとするLambda関数を使用しています。
`lambda_functions/file-watcher/`配下のLambda関数は、インフラテスト用のプレースホルダーです。

### Lambda関数の構成

現在実装されているLambda関数：

- **file-watcher**: S3バケットへのファイルアップロード/削除を監視
  - トリガー: S3イベント通知 (`data/*.yaml`)
  - 権限: S3読み取り、CloudWatch Logs書き込み
  - 目的: インフラストラクチャの動作確認（プレースホルダー）

### IAMポリシーの設計

Lambda関数には最小権限の原則に基づき、必要な権限のみが付与されます：

```hcl
# 例: file-watcher Lambda関数の権限
enable_s3_access              = true   # S3読み取り権限を有効化
enable_dynamodb_access        = false  # DynamoDB権限は無効
enable_secrets_manager_access = false  # Secrets Manager権限は無効
```

将来的に他のLambda関数（例: `backend-llm-response`）を追加する際は、
各関数に必要な権限のみを個別に設定できます。

### テスト方法

#### 1. 完全な統合テスト（推奨）

S3へのファイルアップロードからCloudWatch Logsの確認まで一連の流れをテストします：

```bash
make test-lambda
```

このコマンドは以下を実行します：
1. テスト用YAMLファイルを作成
2. S3バケット (`vecr-garage-dev/data/`) にアップロード
3. Lambda関数が自動実行されるまで待機（約5秒）
4. CloudWatch Logsの直近2分間のログを表示

#### 2. 個別のテストコマンド

各ステップを個別に実行することもできます：

```bash
# S3へのテストファイルアップロードのみ
make test-lambda-upload

# CloudWatch Logsの確認のみ（過去5分間）
make test-lambda-logs

# CloudWatch Logsをリアルタイムで監視
make test-lambda-logs-follow

# Lambda関数の手動実行（S3イベントなし）
make test-lambda-invoke
```

#### 3. 期待される動作

正常に動作している場合、以下のようなログが表示されます：

```
============================================================
Infrastructure Test Lambda Function Started
============================================================
📥 Reading file from S3...
   Bucket: vecr-garage-dev
   Key: test.txt
============================================================
✅ SUCCESS: S3 file read successfully!
============================================================
📄 File content:
------------------------------------------------------------
Hello from S3! This is a test file.
------------------------------------------------------------
Duration: 71.56 ms
Memory Used: 93 MB
```

### 本番用Lambda関数への置き換え

現在の`lambda_functions/file-watcher/lambda_handler.py`はプレースホルダーです。
実際のアプリケーションロジックを実装する際は以下の手順で置き換えてください：

1. `vecr-garage/backend-db-registration`で実装したコードを準備
2. `lambda_functions/file-watcher/`配下のファイルを置き換え
3. 必要に応じて依存関係を`requirements.txt`に追加
4. `make plan`で変更内容を確認
5. `make apply`でデプロイ
6. `make test-lambda`で動作確認

**注意**: 実装の際は、Lambda関数の制限事項に注意してください：
- タイムアウト: デフォルト300秒
- メモリ: デフォルト128MB（必要に応じて調整可能）
- パッケージサイズ: 圧縮後50MB、展開後250MB

## 注意事項

- 本番環境への変更は必ずレビューを経て行ってください
- 機密情報は必ずAWS Secrets Managerで管理してください
- インフラの変更は必ず実行計画を確認してから適用してください

_____

# VECR Garage Infrastructure

## Overview
This is a Terraform project for managing VECR's office infrastructure.
It builds and manages necessary resources on AWS.

## Project Structure
```
.
├── environments/          # Environment-specific configurations
│   ├── dev/             # Development environment
│   ├── prod/            # Production environment
│   └── staging/         # Staging environment
├── global/              # Global resources
│   └── iam-global/      # Global IAM policies
├── modules/             # Reusable Terraform modules
│   ├── bastion/        # Bastion host (SSH jump server)
│   ├── ec2/            # EC2 instance related
│   ├── iam/            # IAM roles and policies
│   ├── iam-service-roles/ # Service-specific IAM roles
│   ├── iam-users/      # IAM user management
│   ├── lambda/         # Lambda function related
│   ├── networking/     # Networking related (incl. VPC Endpoints)
│   ├── rds/            # RDS PostgreSQL related
│   ├── s3/             # S3 bucket related
│   └── secrets-manager/# Secrets Manager related
├── lambda_functions/   # Lambda function source code
│   └── file-watcher/   # S3 event monitoring Lambda (placeholder)
└── terraform.tfvars     # Environment variables file
```

## Development Environment

- OS: Ubuntu 24.04.1 LTS
- Terraform: v1.11.3
- AWS CLI: 2.25.6

### Installing Terraform and AWS CLI

Please refer to the following official documentation for installation instructions according to your environment:

- Terraform: https://developer.hashicorp.com/terraform/install
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## Setup

1. Set up required environment variables:
   ```bash
   cp .env.sample .env
   # Edit .env file with necessary values
   ```

2. Configure AWS credentials:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars file with necessary values
   ```

## Usage

### Initialization

```bash
make init
```
- Initializes Terraform for the specified environment
- Downloads required providers and modules

### Creating Execution Plan

```bash
make plan
```
- Creates an infrastructure change plan
- Allows review of changes

### Applying Infrastructure

```bash
make apply
```
- Builds or updates infrastructure based on the execution plan

### Destroying Infrastructure

```bash
make destroy
```
- Removes the built infrastructure
- Note: Do not use in production environment

## Environment Variables

The following environment variables are required:

- `AWS_PROFILE`: AWS authentication profile name
- `ENVIRONMENT`: Target environment (dev/staging/prod)
- `PROJECT`: Project name

## Secrets Manager Operations

Sensitive information such as API keys is managed in AWS Secrets Manager.

### Secrets Configuration

| Secret Name | Purpose | Keys Included |
|-------------|---------|---------------|
| `vecr-garage-dev-lambda-secrets` | For Lambda functions | LLM API keys, Discord Bot Tokens, Webhook URLs |
| `vecr-garage-dev-app-secrets` | For applications | Flask Secret Key, etc. |
| `vecr-garage-dev-db-credentials` | RDS credentials | host, port, username, password, dbname |

### Operations via Make Targets

```bash
# List all secrets in the project
make secret-list-all

# List keys in Lambda secrets (default)
make secret-list

# List keys in App secrets
make secret-list SECRET=app-secrets

# Get a specific key value
make secret-get KEY=anthropic_api_key

# Get from App secrets
make secret-get KEY=flask_secret_key SECRET=app-secrets
```

### Direct AWS CLI Operations

```bash
# Query using IAM user profile
aws secretsmanager get-secret-value \
  --secret-id vecr-garage-dev-lambda-secrets \
  --profile vecr-garage-dev-<username> \
  | jq -r '.SecretString | fromjson | .open_router_api_key'
```

### Adding New Secrets

To add a new Discord Bot or webhook, simply add it to the map variable in `terraform.tfvars` and it will automatically be reflected in Secrets Manager:

```hcl
discord_bot_tokens = {
  kasen         = "..."
  karasuno_endo = "..."
  new_bot       = "new_token"  # ← Just add here
}
```

## RDS PostgreSQL

### Overview

Deploy an RDS PostgreSQL instance in a private subnet, accessible via Bastion host.

### Architecture

```
Internet → Bastion (Public Subnet) → RDS PostgreSQL (Private Subnet)
```

- **RDS**: PostgreSQL 16, db.t4g.micro, encryption enabled
- **Bastion**: Ubuntu 24.04 Minimal (ARM64), On-Demand instance, psql pre-installed
- **VPC Endpoints**: Access SecretsManager/S3 without NAT Gateway

### Connection Methods

#### 1. Check Credentials

```bash
make rds-credentials
```

#### 2. Connect via Bastion

```bash
# Login to Bastion
make ssh-bastion

# Run psql on Bastion
psql -h <RDS_HOST> -U vecr_admin -d vecr
```

#### 3. SSH Tunnel (Connect from local)

```bash
# Terminal 1: Create SSH tunnel
make rds-tunnel

# Terminal 2: Connect via psql locally
psql -h localhost -p 5432 -U vecr_admin -d vecr
```

### Make Targets

| Target | Description |
|--------|-------------|
| `make ssh-bastion` | Connect to Bastion host |
| `make rds-tunnel` | Create SSH tunnel to RDS (localhost:5432) |
| `make rds-credentials` | Display RDS credentials |

## Lambda Function Testing

### Lambda Configuration

Currently implemented Lambda functions:

- **file-watcher**: Monitors file uploads/deletions in S3 bucket
  - Trigger: S3 event notifications (`data/*.yaml`)
  - Permissions: S3 read access, CloudWatch Logs write access
  - Purpose: Infrastructure validation (placeholder)

### IAM Policy Design

Lambda functions are granted only the necessary permissions based on the principle of least privilege:

```hcl
# Example: file-watcher Lambda function permissions
enable_s3_access              = true   # Enable S3 read access
enable_dynamodb_access        = false  # Disable DynamoDB access
enable_secrets_manager_access = false  # Disable Secrets Manager access
```

When adding other Lambda functions in the future (e.g., `backend-llm-response`), you can configure only the required permissions for each function individually.

### Testing Methods

#### 1. Full Integration Test (Recommended)

Test the complete workflow from S3 file upload to CloudWatch Logs verification:

```bash
make test-lambda
```

This command performs the following steps:

1. Create a test YAML file
2. Upload to S3 bucket (`vecr-garage-dev/data/`)
3. Wait for Lambda function auto-execution (~5 seconds)
4. Display CloudWatch Logs from the past 2 minutes

#### 2. Individual Test Commands

You can also run each step individually:

```bash
# Upload test file to S3 only
make test-lambda-upload

# View CloudWatch Logs only (past 5 minutes)
make test-lambda-logs

# Monitor CloudWatch Logs in real-time
make test-lambda-logs-follow

# Manually invoke Lambda function (without S3 event)
make test-lambda-invoke
```

#### 3. Expected Behavior

When functioning correctly, you should see logs similar to:

```
============================================================
Infrastructure Test Lambda Function Started
============================================================
📥 Reading file from S3...
   Bucket: vecr-garage-dev
   Key: test.txt
============================================================
✅ SUCCESS: S3 file read successfully!
============================================================
📄 File content:
------------------------------------------------------------
Hello from S3! This is a test file.
------------------------------------------------------------
Duration: 71.56 ms
Memory Used: 93 MB
```

### Replacing with Production Lambda Function

The current `lambda_functions/file-watcher/lambda_handler.py` is a placeholder. When implementing actual application logic, follow these steps:

1. Prepare code implemented in `vecr-garage/backend-db-registration`
2. Replace files in `lambda_functions/file-watcher/`
3. Add dependencies to `requirements.txt` as needed
4. Verify changes with `make plan`
5. Deploy with `make apply`
6. Test functionality with `make test-lambda`

**Note**: Be aware of Lambda function limitations when implementing:

- Timeout: Default 300 seconds
- Memory: Default 128MB (adjustable as needed)
- Package size: 50MB compressed, 250MB uncompressed

## Important Notes

- Always review changes before applying to production environment
- Store sensitive information in AWS Secrets Manager
- Always review execution plans before applying infrastructure changes
