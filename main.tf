provider "aws" {
  version = "~> 2.39.0"
  region  = "${var.aws_region}"
}

resource "aws_sqs_queue" "ingest_dlq" {
    name = "ingest-queue-dql"
    visibility_timeout_seconds = var.lambda_timeout
    tags = {
        Environment = "dev"
    }
}

resource "aws_sqs_queue" "ingest_queue" {
    name = "ingest-queue"
    visibility_timeout_seconds = var.lambda_timeout
    redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.ingest_dlq.arn,
        maxReceiveCount: 2
    })
    tags = {
        Environment = "dev"
    }
}

## Instance
data "aws_ami" "amazon_linux_2" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm*"]
    }
}

## Key-Pair
resource "tls_private_key" "dev" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "dev" {
    key_name   = "dev-key"
    public_key = tls_private_key.dev.public_key_openssh 
}

### allow port 22 for ssh
resource "aws_security_group" "web_sg" {
    name        = "web-dev-sg"
    description = "Allow TLS inbound traffic"

    ingress {
        description = "TLS from VPC"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =  ["${var.local_ip_address}/32"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Web-Dev-SG"
    }
}

resource "aws_instance" "dev" {
    ami = data.aws_ami.amazon_linux_2.id
    iam_instance_profile = aws_iam_instance_profile.custom_web_profile.name
    instance_type = "t2.micro"
    vpc_security_group_ids = [
        aws_security_group.web_sg.id
    ]
    associate_public_ip_address = true
    key_name = aws_key_pair.dev.key_name
    tags = {
        Name = "Dev-Instance"
    }
}

# Lambda

## Read the configuration from local files
locals {
    package_json = jsondecode(file("./package.json"))
    build_folder = "dist"
}

resource "aws_s3_bucket" "lambda" {
    bucket = "lambda-artifact-dev01"
    acl    = "private"
    tags = {
        Name        = "Dev"
        Environment = "Dev"
    }
}

resource "aws_s3_bucket_object" "lambda" {
    bucket = aws_s3_bucket.lambda.id
    key    = "main-${local.package_json.version}"
    source = "${local.build_folder}/main-${local.package_json.version}.zip"
}

resource "aws_lambda_function" "process_queue_lambda" {
    function_name = "${var.lambda_name}-${var.env}"
    s3_bucket = "${aws_s3_bucket.lambda.id}"
    s3_key = "${aws_s3_bucket_object.lambda.id}"
    handler = "src/index.handler"
    role = "${aws_iam_role.lambda_role.arn}"
    timeout = var.lambda_timeout 
    source_code_hash = "${filebase64sha256("dist/${aws_s3_bucket_object.lambda.id}.zip")}"
    runtime = "nodejs12.x"
    depends_on = [
        #aws_iam_role_policy_attachment.attach_policy_to_role_lambda,
        aws_cloudwatch_log_group.lambda_logs
    ]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
    name = "/aws/lambda/${var.lambda_name}-${var.env}"
    retention_in_days = 3
}

resource "aws_lambda_event_source_mapping" "queue_lambda_event" {
    event_source_arn = "${aws_sqs_queue.ingest_queue.arn}"
    function_name    = "${aws_lambda_function.process_queue_lambda.arn}"
    batch_size       = 1
}
