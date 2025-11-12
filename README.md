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
│   ├── networking/     # ネットワーク関連
│   └── secrets-manager/# Secrets Manager関連
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
│   ├── networking/     # Networking related
│   └── secrets-manager/# Secrets Manager related
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

## Important Notes

- Always review changes before applying to production environment
- Store sensitive information in AWS Secrets Manager
- Always review execution plans before applying infrastructure changes