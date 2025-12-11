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
