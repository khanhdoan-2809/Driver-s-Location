# policy: api gateway with sqs 
resource "aws_iam_role" "api_sqs" {
    name = "apigateway_sqs"

    assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF
}

data "template_file" "gateway_policy" {
  template = file("${path.root}/policies/api-gateway-permission.json")

  vars = {
    sqs_arn   = var.mv_sqs_arn
  }
}

resource "aws_iam_policy" "api_policy" {
  name = "api-sqs-cloudwatch-policy"

  policy = data.template_file.gateway_policy.rendered
}

resource "aws_iam_role_policy_attachment" "api_exec_role" {
  role       =  aws_iam_role.api_sqs.name
  policy_arn =  aws_iam_policy.api_policy.arn
}

# lambda role
resource "aws_iam_role" "lambda_exec_role" {
  name               = "handler-lambda"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# policy: sqs with lambda
data "template_file" "lambda_sqs_file" {
  template = file("${path.root}/policies/sqs-lambda.json")

  vars = {
    sqs_arn   = var.mv_sqs_arn
  }
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "sqs_policy_lambda"
  description = "IAM policy for lambda Being invoked by SQS"

  policy = data.template_file.lambda_sqs_file.rendered
}

resource "aws_iam_role_policy_attachment" "sqs_lambda_role_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# policy: lambda with dynamodb
data "template_file" "lambda_dynamodb_file" {
  template = file("${path.root}/policies/lambda-dynamodb.json")

  vars = {
    dynamodb_arn  = var.mv_dynamodb_arn 
  }
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_policy_dynamodb"
  description = "IAM policy for lambda get, write with dynamodb"

  policy = data.template_file.lambda_dynamodb_file.rendered
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_role_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}