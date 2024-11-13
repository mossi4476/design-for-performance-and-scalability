# Configure the AWS provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/greet_lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "greet_lambda" {
  filename      = "lambda.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "greet_lambda.lambda_handler"
  runtime       = "python3.10"
  environment {
    variables = {
      greeting = "Hello World!"
    }
  }
}
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch_logs_policy"
  description = "Allows writing logs to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_lambda_permission" "greet_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.greet_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}