# ------------------------------------------------------------
# Bastion / SSH commands
# ------------------------------------------------------------

ssh-bastion: check-env ## Connect to Bastion host via SSH
	@BASTION_IP=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw bastion_public_ip 2>/dev/null); \
	if [ -z "$$BASTION_IP" ] || [ "$$BASTION_IP" = "" ]; then \
		echo "Error: Bastion is not deployed or IP not available"; \
		exit 1; \
	fi; \
	echo "Connecting to Bastion: ubuntu@$$BASTION_IP"; \
	ssh ubuntu@$$BASTION_IP

rds-tunnel: check-env ## Create SSH tunnel for RDS access (localhost:5432 -> RDS)
	@BASTION_IP=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw bastion_public_ip 2>/dev/null); \
	RDS_HOST=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw rds_address 2>/dev/null); \
	if [ -z "$$BASTION_IP" ] || [ "$$BASTION_IP" = "" ]; then \
		echo "Error: Bastion is not deployed or IP not available"; \
		exit 1; \
	fi; \
	if [ -z "$$RDS_HOST" ] || [ "$$RDS_HOST" = "" ]; then \
		echo "Error: RDS is not deployed or address not available"; \
		exit 1; \
	fi; \
	echo "Creating SSH tunnel: localhost:5432 -> $$RDS_HOST:5432"; \
	echo "Press Ctrl+C to close the tunnel"; \
	ssh -L 5432:$$RDS_HOST:5432 ubuntu@$$BASTION_IP

rds-credentials: check-env ## Show RDS connection credentials
	@echo "============================================================"
	@echo "RDS Connection Credentials"
	@echo "============================================================"
	@AWS_PROFILE=$(AWS_PROFILE) aws secretsmanager get-secret-value \
		--secret-id $(PROJECT)-$(ENVIRONMENT)-db-credentials \
		--query 'SecretString' --output text | jq -r '"Host:     \(.host)\nPort:     \(.port)\nDatabase: \(.dbname)\nUsername: \(.username)\nPassword: \(.password)"'
	@echo "============================================================"
	@echo "Connection command (from Bastion):"
	@AWS_PROFILE=$(AWS_PROFILE) aws secretsmanager get-secret-value \
		--secret-id $(PROJECT)-$(ENVIRONMENT)-db-credentials \
		--query 'SecretString' --output text | jq -r '"psql -h \(.host) -U \(.username) -d \(.dbname)"'

# ------------------------------------------------------------
# Instance Management (Start/Stop)
# ------------------------------------------------------------

rds-start: check-env ## Start RDS instance
	@echo "Starting RDS instance: $(PROJECT)-$(ENVIRONMENT)-db"
	@AWS_PROFILE=$(AWS_PROFILE) aws rds start-db-instance \
		--db-instance-identifier $(PROJECT)-$(ENVIRONMENT)-db
	@echo "✅ RDS start initiated. Use 'make rds-status' to check status."

rds-stop: check-env ## Stop RDS instance
	@echo "Stopping RDS instance: $(PROJECT)-$(ENVIRONMENT)-db"
	@AWS_PROFILE=$(AWS_PROFILE) aws rds stop-db-instance \
		--db-instance-identifier $(PROJECT)-$(ENVIRONMENT)-db
	@echo "✅ RDS stop initiated. Use 'make rds-status' to check status."

rds-status: check-env ## Show RDS instance status
	@AWS_PROFILE=$(AWS_PROFILE) aws rds describe-db-instances \
		--db-instance-identifier $(PROJECT)-$(ENVIRONMENT)-db \
		--query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}' \
		--output table

bastion-start: check-env ## Start Bastion EC2 instance
	@INSTANCE_ID=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw bastion_instance_id 2>/dev/null); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "Error: Bastion instance ID not found"; \
		exit 1; \
	fi; \
	echo "Starting Bastion instance: $$INSTANCE_ID"; \
	AWS_PROFILE=$(AWS_PROFILE) aws ec2 start-instances --instance-ids $$INSTANCE_ID; \
	echo "✅ Bastion start initiated. Use 'make bastion-status' to check status."

bastion-stop: check-env ## Stop Bastion EC2 instance
	@INSTANCE_ID=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw bastion_instance_id 2>/dev/null); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "Error: Bastion instance ID not found"; \
		exit 1; \
	fi; \
	echo "Stopping Bastion instance: $$INSTANCE_ID"; \
	AWS_PROFILE=$(AWS_PROFILE) aws ec2 stop-instances --instance-ids $$INSTANCE_ID; \
	echo "✅ Bastion stop initiated. Use 'make bastion-status' to check status."

bastion-status: check-env ## Show Bastion EC2 instance status
	@INSTANCE_ID=$$(cd environments/$(ENVIRONMENT) && AWS_PROFILE=$(AWS_PROFILE) terraform output -raw bastion_instance_id 2>/dev/null); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "Error: Bastion instance ID not found"; \
		exit 1; \
	fi; \
	AWS_PROFILE=$(AWS_PROFILE) aws ec2 describe-instances \
		--instance-ids $$INSTANCE_ID \
		--query 'Reservations[0].Instances[0].{Status:State.Name,PublicIP:PublicIpAddress,InstanceId:InstanceId}' \
		--output table

infra-start: check-env ## Start both RDS and Bastion instances
	@$(MAKE) rds-start
	@$(MAKE) bastion-start

infra-stop: check-env ## Stop both RDS and Bastion instances
	@$(MAKE) bastion-stop
	@$(MAKE) rds-stop

infra-status: check-env ## Show status of RDS and Bastion instances
	@echo "============================================================"
	@echo "RDS Status:"
	@echo "============================================================"
	@$(MAKE) rds-status
	@echo ""
	@echo "============================================================"
	@echo "Bastion Status:"
	@echo "============================================================"
	@$(MAKE) bastion-status
