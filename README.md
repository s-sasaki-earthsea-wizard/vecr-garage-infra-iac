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
│   ├── ec2/            # EC2インスタンス関連
│   ├── iam/            # IAMロール・ポリシー関連
│   ├── lambda/         # Lambda関数関連
│   ├── networking/     # ネットワーク関連
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

### IAMユーザーでSecrets Managerをクエリする

APIキーなどのセンシティブな情報はIAMユーザーのプロフィールを使ってaws cliで以下のようにクエリできます。

```bash
# IAMユーザーのプロフィール名を指定してクエリ
aws secretsmanager get-secret-value --secret-id vecr-garage-dev-secrets-v1 --profile vecr-garage-dev-<username> | jq -r '.SecretString | fromjson | .open_router_api_key'
```

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
│   ├── ec2/            # EC2 instance related
│   ├── iam/            # IAM roles and policies
│   ├── lambda/         # Lambda function related
│   ├── networking/     # Networking related
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
