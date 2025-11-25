"""
Infrastructure Test Lambda Function - Placeholder

このファイルは、S3、Lambda、IAMの接続を確認するためのテストコードです。
実際のアプリケーションロジックは、vecr-garage/backend-db-registrationで実装し、
動作確認後にこのファイルを置き換えてください。

テスト方法:
1. S3バケット (vecr-garage-dev) に test.txt をアップロード
   例: echo "Hello from S3!" > test.txt
   aws s3 cp test.txt s3://vecr-garage-dev/test.txt

2. Lambda関数がトリガーされ、test.txtの内容をCloudWatch Logsに出力

3. CloudWatch Logsで確認:
   /aws/lambda/vecr-garage-dev-file-watcher

期待される動作:
- S3からファイルを読み取れることを確認
- Lambda関数が正しく起動することを確認
- IAM権限（S3読み取り）が正しく設定されていることを確認
"""

import boto3
import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# S3 client
s3_client = boto3.client('s3')


def lambda_handler(event, context):
    """
    Simple infrastructure test Lambda handler.

    Reads test.txt from S3 bucket and logs the content.

    Args:
        event: Lambda event (not used in this test)
        context: Lambda context (not used in this test)

    Returns:
        Response dictionary with status code and body
    """
    logger.info("=" * 60)
    logger.info("Infrastructure Test Lambda Function Started")
    logger.info("=" * 60)

    bucket_name = 'vecr-garage-dev'
    test_file_key = 'test.txt'

    try:
        # Read test.txt from S3
        logger.info(f"📥 Reading file from S3...")
        logger.info(f"   Bucket: {bucket_name}")
        logger.info(f"   Key: {test_file_key}")

        response = s3_client.get_object(Bucket=bucket_name, Key=test_file_key)
        content = response['Body'].read().decode('utf-8')

        logger.info("=" * 60)
        logger.info("✅ SUCCESS: S3 file read successfully!")
        logger.info("=" * 60)
        logger.info(f"📄 File content:")
        logger.info("-" * 60)
        logger.info(content)
        logger.info("-" * 60)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': '✅ Infrastructure test successful',
                'bucket': bucket_name,
                'key': test_file_key,
                'content': content,
                'note': 'S3, Lambda, and IAM are working correctly!'
            })
        }

    except s3_client.exceptions.NoSuchKey:
        error_msg = f"❌ ERROR: File not found: s3://{bucket_name}/{test_file_key}"
        logger.error("=" * 60)
        logger.error(error_msg)
        logger.error("=" * 60)
        logger.error("Please create test.txt first:")
        logger.error(f"  echo 'Hello from S3!' > test.txt")
        logger.error(f"  aws s3 cp test.txt s3://{bucket_name}/{test_file_key}")

        return {
            'statusCode': 404,
            'body': json.dumps({
                'error': 'File not found',
                'message': error_msg,
                'hint': f'Please upload test.txt to s3://{bucket_name}/{test_file_key}'
            })
        }

    except Exception as e:
        error_msg = f"❌ ERROR: {str(e)}"
        logger.error("=" * 60)
        logger.error(error_msg)
        logger.error("=" * 60)
        logger.exception("Full error traceback:")

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal error',
                'message': error_msg
            })
        }
