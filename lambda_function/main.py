import logging
import json
import boto3
import os
from typing import Any
from datetime import datetime, UTC

logger = logging.getLogger()
logger.setLevel(logging.INFO)
ec2 = boto3.client("ec2")
sns = boto3.client("sns")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")

def get_response(status_code: int, message: str) -> dict[str, Any]:
    return {
      "statusCode": status_code,
      "headers": {"Content-Type": "application/json"},
      "body": json.dumps({
        "message": message
      })
    }

def extract_payload(event: dict[str, Any]) -> dict[str, Any]:
  if event.get("requestContext", {}).get("http", ""):
    body = event.get("body", "")

    if not body or body == "":
      return {}

    return json.loads(body) if isinstance(body, str) else {}

  return event

def lambda_handler(event: dict[str, Any], context: Any):
  logger.info(event)

  if SNS_TOPIC_ARN == "":
    return get_response(status_code=400, message="SNS Topic ARN environment variable must be set.")
  
  payload = extract_payload(event=event)
  ec2_instance_id = payload.get("ec2_instance_id", "")
  logger.info(f"Rebooting EC2 instance: {ec2_instance_id}")
  ec2.reboot_instances(InstanceIds=[ec2_instance_id])
  logger.info(f"EC2 instance: {ec2_instance_id} successfully restarted")
  msg = {
    "ec2_instance_id": ec2_instance_id,
    "timestamp": datetime.now(tz=UTC).isoformat()
  }
  sns.publish(TopicArn=SNS_TOPIC_ARN, Subject="Restarted EC2 Instance", Message=json.dumps(msg))
  logger.info(f"Successfully published message to SNS: {SNS_TOPIC_ARN}")
  
  return get_response(status_code=200, message="Success")