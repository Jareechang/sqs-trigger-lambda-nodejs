###############
# IAM - Dev 
###############

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
    policy = data.aws_iam_policy_document.sqs_access.json
}

###############
# IAM - Lambda
###############

# TODO: Create lambda role to:
#
# - Receive messages from queue 
# - Use other useful SQS methods for polling useful data (# of messages etc)
# - CW logs permissions
#  


###############
# IAM - Instance 
###############

# TODO: Create instance role to:
#
# - Send Message to SQS
#  

