output "sns_alert_topic_arn" {
  value = aws_sns_topic.alerts
}

output "ec2_instance_id" {
  value = aws_instance.ec2_demo.id
}

output "lambda_function_url" {
  value = aws_lambda_function_url.sumo_webhook.function_url
}