# Terraform provider
provider "aws" {
  region = "us-west-2"  # Change to your preferred region
  profile = "raj-private"
}


# Define the IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_ec2_control_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_ec2_control_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda function code packaging
data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Lambda function
resource "aws_lambda_function" "ec2_control_lambda" {
  function_name = "ec2_control_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  # Lambda deployment package
  filename         = data.archive_file.lambda_code.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_code.output_path)

  environment {
    variables = {
      INSTANCE_ID = "i-050ea5cbd03549832"  # Replace with your EC2 instance ID
    }
  }
}

# CloudWatch Events rule to trigger Lambda at 7:55 PM UTC
resource "aws_cloudwatch_event_rule" "start_ec2_rule" {
  name                = "start_ec2_rule"
  schedule_expression = "cron(55 19 * * ? *)"
}

# CloudWatch Events rule to trigger Lambda at 9:00 PM UTC
resource "aws_cloudwatch_event_rule" "stop_ec2_rule" {
  name                = "stop_ec2_rule"
  schedule_expression = "cron(0 21 * * ? *)"
}

# Add Lambda function as target for start EC2 rule
resource "aws_cloudwatch_event_target" "start_ec2_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_rule.name
  arn       = aws_lambda_function.ec2_control_lambda.arn
  input     = jsonencode({ "action": "start" })
}

# Add Lambda function as target for stop EC2 rule
resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_rule.name
  arn       = aws_lambda_function.ec2_control_lambda.arn
  input     = jsonencode({ "action": "stop" })
}

# Lambda permission to allow CloudWatch to invoke the function
resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_control_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_control_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2_rule.arn
}

# Define the Lambda function code source
resource "local_file" "lambda_code" {
  content  = file("${path.module}/lambda_code/index.py")
  filename = "${path.module}/lambda_code/index.py"
}
