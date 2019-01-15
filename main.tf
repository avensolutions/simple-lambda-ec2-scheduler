#
# Module Provider
#

provider "aws" {
	region = "ap-southeast-2"
	shared_credentials_file = "~/.aws/credentials"
	profile                 = "default"
}

#
# Create IAM Role and Policy for Lambda Function
#

resource "aws_iam_role" "lambda_stop_ec2" {
  name = "lambda_stop_ec2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lamdba_ec2_shutdown_policy" {
  name = "lamdba_ec2_shutdown_policy"
  role = "${aws_iam_role.lambda_stop_ec2.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Stop*",
		"ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

#
# Create ZIP Archive for Function Source Code
#

data "archive_file" "lambda_stop_ec2_zip" {
  type = "zip"
  output_path = "${path.module}/lambda_stop_ec2.zip"
  source_dir = "${path.module}/function_source_code/"
}

#
# Create Lambda Function
#
 
resource "aws_lambda_function" "lambda_stop_ec2" {
  filename = "${substr(data.archive_file.lambda_stop_ec2_zip.output_path, length(path.cwd) + 1, -1)}"
  function_name    = "lambda_stop_ec2"
  timeout		   = 10  
  role             = "${aws_iam_role.lambda_stop_ec2.arn}"
  handler          = "lambda_stop_ec2.lambda_handler"
  runtime          = "python2.7"
}

#
# Create CloudWatch Event Rule
#

resource "aws_cloudwatch_event_rule" "stop_ec2_event_rule" {
  name        = "stop-ec2-event-rule"
  description = "Stop running EC2 instance at a specified time each day"
  schedule_expression = "${var.schedule_expression}"
}

#
# Create CloudWatch Event Target
#

resource "aws_cloudwatch_event_target" "stop_ec2_event_rule_target" {
  rule      = "${aws_cloudwatch_event_rule.stop_ec2_event_rule.name}"
  target_id = "TriggerLambdaFunction"
  arn       = "${aws_lambda_function.lambda_stop_ec2.arn}"
  input 	= "{\"environment\":\"${var.environment}\"}"
}

#
# Add Lamdba Permission
#

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_stop_ec2.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.stop_ec2_event_rule.arn}"
}