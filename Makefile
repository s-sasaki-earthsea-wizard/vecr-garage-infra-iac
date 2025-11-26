.PHONY: all

# Include environment variables
include .env
export

# Define the root directory as the directory of the Makefile
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Set help as the default target
default: help

# ------------------------------------------------------------
# Environment setup
# ------------------------------------------------------------

check-env: ## Check if required environment variables are set
	@if [ -z "$(AWS_PROFILE)" ]; then \
		echo "Error: AWS_PROFILE is not set in .env file"; \
		exit 1; \
	fi
	@if [ -z "$(ENVIRONMENT)" ]; then \
		echo "Error: ENVIRONMENT is not set in .env file"; \
		exit 1; \
	fi
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT is not set in .env file"; \
		exit 1; \
	fi


# ------------------------------------------------------------
# Terraform commands
# ------------------------------------------------------------

init: check-env ## Initialize the Terraform project
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform init

plan: check-env ## Create a Terraform execution plan
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) TF_VAR_environment=$(ENVIRONMENT) TF_VAR_project=$(PROJECT) terraform plan -var-file=${ROOT_DIR}/terraform.tfvars -out=tfplan

apply: check-env ## Apply the Terraform execution plan
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform apply tfplan

validate: check-env ## Validate Terraform configuration
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform validate

fmt: ## Format Terraform configuration files
	terraform fmt -recursive

output: check-env ## Show Terraform outputs
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform output

graph: check-env ## Generate a Terraform graph
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform graph \
	> $(ROOT_DIR)/graphs/graph.dot && \
	dot -Tpng $(ROOT_DIR)/graphs/graph.dot -o $(ROOT_DIR)/graphs/graph.png

# ------------------------------------------------------------
# Resource-specific commands
# ------------------------------------------------------------

show: check-env ## Show the current Terraform state
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform show

state-list: check-env ## List all resources in Terraform state
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) terraform state list

# ------------------------------------------------------------
# Lambda Testing
# ------------------------------------------------------------

test-lambda: check-env ## Test Lambda function by uploading sample YAML to S3 and checking logs
	@echo "============================================================"
	@echo "Lambda Function Integration Test"
	@echo "============================================================"
	@echo "Creating sample YAML file..."
	@mkdir -p /tmp/lambda-test
	@echo "name: テストメンバー" > /tmp/lambda-test/test.yaml
	@echo "bio: Lambda関数の自動実行テスト" >> /tmp/lambda-test/test.yaml
	@echo "created_at: $$(date +%Y-%m-%d)" >> /tmp/lambda-test/test.yaml
	@echo ""
	@echo "Uploading to S3: $(PROJECT)-$(ENVIRONMENT)/data/test.yaml"
	@AWS_PROFILE=$(AWS_PROFILE) aws s3 cp /tmp/lambda-test/test.yaml s3://$(PROJECT)-$(ENVIRONMENT)/data/test.yaml
	@echo "✅ Upload complete! Lambda should be triggered automatically."
	@echo ""
	@echo "Waiting for Lambda execution (5 seconds)..."
	@sleep 5
	@echo ""
	@echo "============================================================"
	@echo "CloudWatch Logs (Last 2 minutes):"
	@echo "============================================================"
	@AWS_PROFILE=$(AWS_PROFILE) aws logs tail /aws/lambda/$(PROJECT)-$(ENVIRONMENT)-file-watcher --since 2m --format short || echo "No logs found yet. Try running: make test-lambda-logs"
	@echo ""
	@echo "============================================================"
	@echo "Test completed!"
	@echo "============================================================"

test-lambda-upload: check-env ## Upload a sample YAML file to S3 to trigger Lambda
	@echo "Creating sample YAML file..."
	@mkdir -p /tmp/lambda-test
	@echo "name: テストメンバー" > /tmp/lambda-test/test.yaml
	@echo "bio: Lambda関数の自動実行テスト - $$(date '+%Y-%m-%d %H:%M:%S')" >> /tmp/lambda-test/test.yaml
	@echo "created_at: $$(date +%Y-%m-%d)" >> /tmp/lambda-test/test.yaml
	@echo ""
	@echo "Uploading to S3: $(PROJECT)-$(ENVIRONMENT)/data/test.yaml"
	@AWS_PROFILE=$(AWS_PROFILE) aws s3 cp /tmp/lambda-test/test.yaml s3://$(PROJECT)-$(ENVIRONMENT)/data/test.yaml
	@echo "✅ Upload complete! Lambda should be triggered automatically."
	@echo "Run 'make test-lambda-logs' to see the execution logs."

test-lambda-logs: check-env ## Show CloudWatch Logs for Lambda function
	@echo "============================================================"
	@echo "CloudWatch Logs: /aws/lambda/$(PROJECT)-$(ENVIRONMENT)-file-watcher"
	@echo "============================================================"
	@AWS_PROFILE=$(AWS_PROFILE) aws logs tail /aws/lambda/$(PROJECT)-$(ENVIRONMENT)-file-watcher --since 5m --format short

test-lambda-logs-follow: check-env ## Follow CloudWatch Logs in real-time
	@echo "============================================================"
	@echo "Following CloudWatch Logs (press Ctrl+C to stop):"
	@echo "============================================================"
	@AWS_PROFILE=$(AWS_PROFILE) aws logs tail /aws/lambda/$(PROJECT)-$(ENVIRONMENT)-file-watcher --follow --format short

test-lambda-invoke: check-env ## Manually invoke Lambda function (not triggered by S3)
	@echo "Manually invoking Lambda function: $(PROJECT)-$(ENVIRONMENT)-file-watcher"
	@AWS_PROFILE=$(AWS_PROFILE) aws lambda invoke --function-name $(PROJECT)-$(ENVIRONMENT)-file-watcher --payload '{}' /tmp/lambda-response.json
	@echo ""
	@echo "Response:"
	@cat /tmp/lambda-response.json | jq . || cat /tmp/lambda-response.json
	@echo ""
	@echo "Check logs with: make test-lambda-logs"

# ------------------------------------------------------------
# Secrets Manager
# ------------------------------------------------------------

secret-get: check-env ## Get a secret value by key. Usage: make secret-get KEY=anthropic_api_key [SECRET=lambda-secrets]
	@if [ -z "$(KEY)" ]; then \
		echo "Error: KEY is required. Usage: make secret-get KEY=<key_name> [SECRET=lambda-secrets|app-secrets]"; \
		exit 1; \
	fi
	@SECRET_NAME=$${SECRET:-lambda-secrets}; \
	AWS_PROFILE=$(AWS_PROFILE) aws secretsmanager get-secret-value \
		--secret-id $(PROJECT)-$(ENVIRONMENT)-$$SECRET_NAME \
		--query 'SecretString' --output text | jq -r ".$(KEY)"

secret-list: check-env ## List all secret keys. Usage: make secret-list [SECRET=lambda-secrets]
	@SECRET_NAME=$${SECRET:-lambda-secrets}; \
	echo "Keys in $(PROJECT)-$(ENVIRONMENT)-$$SECRET_NAME:"; \
	AWS_PROFILE=$(AWS_PROFILE) aws secretsmanager get-secret-value \
		--secret-id $(PROJECT)-$(ENVIRONMENT)-$$SECRET_NAME \
		--query 'SecretString' --output text | jq -r 'keys[]'

secret-list-all: check-env ## List all secrets in Secrets Manager for this project
	@echo "Secrets for $(PROJECT)-$(ENVIRONMENT):"
	@AWS_PROFILE=$(AWS_PROFILE) aws secretsmanager list-secrets \
		--filter Key=name,Values=$(PROJECT)-$(ENVIRONMENT) \
		--query 'SecretList[].Name' --output text | tr '\t' '\n'

# ------------------------------------------------------------
# Destroy commands
# ------------------------------------------------------------

# DANGER!: The following targets will destroy resources created by Terraform.
# Use with extreme caution.

destroy-all: check-env ## DANGER!: Destroy all resources created by Terraform. Use with extreme caution.
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) TF_VAR_environment=$(ENVIRONMENT) TF_VAR_project=$(PROJECT) terraform destroy -var-file=${ROOT_DIR}/terraform.tfvars

destroy-s3: check-env ## DANGER!: Destroy the S3 bucket. Use with extreme caution.
	cd environments/$(ENVIRONMENT) && \
	AWS_PROFILE=$(AWS_PROFILE) TF_VAR_environment=$(ENVIRONMENT) TF_VAR_project=$(PROJECT) terraform destroy -target=module.s3 -var-file=${ROOT_DIR}/terraform.tfvars

# destroy-ec2: check-env ## DANGER!: Destroy the EC2 instance. Use with extreme caution. (Currently commented out)
# 	cd environments/$(ENVIRONMENT) && \
# 	AWS_PROFILE=$(AWS_PROFILE) TF_VAR_environment=$(ENVIRONMENT) TF_VAR_project=$(PROJECT) terraform destroy -target=module.ec2 -var-file=${ROOT_DIR}/terraform.tfvars

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

help: ## Show this help message
	@echo "------------------------------------------------------------------------------"
	@echo "Usage: make [target]"
	@echo "------------------------------------------------------------------------------"
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "------------------------------------------------------------------------------"