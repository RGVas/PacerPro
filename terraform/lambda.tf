resource "aws_iam_role" "lambda_role" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_policy" "lambda_least_priv" {
  name   = "${var.name_prefix}-lambda-least-priv"
  policy = data.aws_iam_policy_document.lambda_least_priv.json
}

resource "aws_iam_role_policy_attachment" "lambda_least_priv_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_least_priv.arn
}

resource "aws_lambda_function" "restart_ec2" {
  function_name    = "${var.name_prefix}-restart-ec2"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "main.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_lambda_function_url" "sumo_webhook" {
  function_name      = aws_lambda_function.restart_ec2.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_function_url" {
  statement_id           = "AllowFunctionURLInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.restart_ec2.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}