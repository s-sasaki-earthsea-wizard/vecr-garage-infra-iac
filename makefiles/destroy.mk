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
