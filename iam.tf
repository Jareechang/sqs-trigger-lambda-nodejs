###################
# IAM - Dev 
###################

resource "aws_iam_user" "dev_user" {
    name = "dev-user"
}

resource "aws_iam_access_key" "dev_key" {
    user = aws_iam_user.dev_user.name
}

data "aws_iam_policy_document" "sqs_access" {
    version = "2012-10-17"
    statement {
        actions = [
            "sqs:*",
        ]
        effect = "Allow"
        resources = [
            aws_sqs_queue.ingest_queue.arn
        ]
    }
}

resource "aws_iam_user_policy" "user_policy" {
    name = "dev-policy"
    user = aws_iam_user.dev_user.name
    policy = data.aws_iam_policy_document.sqs_access.json
}

###################
# IAM - Lambda
###################

# TODO: Create lambda role to:
#
# - Receive messages from queue 
# - Use other useful SQS methods for polling useful data (# of messages etc)
# - CW logs permissions

data "aws_iam_policy_document" "lambda_assume_role_policy" {
    statement {
        actions = [
            "sts:AssumeRole",
        ]

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "sqs_lambda" {
    version = "2012-10-17"
    statement {
        actions = [
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:ChangeMessageVisibility",
            "sqs:DeleteMessage"
        ]
        effect = "Allow"
        resources = [
            aws_sqs_queue.ingest_queue.arn
        ]
    }

    statement {
        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        effect = "Allow"
        resources = [
            "arn:aws:logs:*:*:*"
        ]
    }
}
 
resource "aws_iam_policy" "sqs_lambda_policy" {
    name = "sqs-lambda-dev-policy"
    policy = data.aws_iam_policy_document.sqs_lambda.json
}

resource "aws_iam_role" "lambda_role" {
    name               = "lambda-sqs-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "attach_policy_to_role_lambda" {
    name       = "lambda-role-attachment"
    roles      = [aws_iam_role.lambda_role.name]
    policy_arn = aws_iam_policy.sqs_lambda_policy.arn
}

###################
# IAM - Instance 
###################

# Create instance role to:
#
# - Send Message to SQS
#  


## Policy to allow send message from instance
data "aws_iam_policy_document" "sqs_instance" {
    version = "2012-10-17"
    statement {
        actions = [
            "sqs:SendMessage",
            "sqs:GetQueueAttributes",
        ]
        effect = "Allow"
        resources = [
            aws_sqs_queue.ingest_queue.arn
        ]
    }
}

## Policy for instance to assume a role 
data "aws_iam_policy_document" "instance_assume_role_policy" {
    statement {
        actions = [
            "sts:AssumeRole",
        ]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}
 
resource "aws_iam_policy" "sqs_instance_policy" {
    name = "sqs-instance-dev-policy"
    policy = data.aws_iam_policy_document.sqs_instance.json
}

resource "aws_iam_role" "instance_role" {
    name               = "instance-sqs-role"
    assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "attach_policy_to_role_instance" {
    name       = "instance-role-attachment"
    roles      = [aws_iam_role.instance_role.name]
    policy_arn = aws_iam_policy.sqs_instance_policy.arn
}

resource "aws_iam_instance_profile" "custom_web_profile" {
    name = "instance-sqs-profile"
    role = aws_iam_role.instance_role.name
}
