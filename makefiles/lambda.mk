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
