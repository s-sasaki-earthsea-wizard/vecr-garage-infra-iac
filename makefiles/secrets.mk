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
