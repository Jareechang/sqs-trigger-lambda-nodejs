resource "aws_sqs_queue" "ingest_queue" {
    name = "ingest-queue"
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
    region = var.aws_region
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

resource "aws_lambda_function" "process_queue" {
    function_name = var.lambda_name
    s3_bucket = "${aws_s3_bucket.lambda.id}"
    s3_key = "${aws_s3_bucket_object.lambda.id}"
    handler = "src/index.handler"
    role = "${aws_iam_role.lambda_role.arn}"
    timeout = 300
    source_code_hash = "${filebase64sha256("dist/${aws_s3_bucket_object.lambda.id}.zip")}"
    runtime = "nodejs12.x"
    depends_on = [
        #"aws_iam_role_policy_attachment.lambda_logs",
        "aws_cloudwatch_log_group.sample_log_group"
    ]
}

resource "aws_cloudwatch_log_group" "sample_log_group" {
    name = "/aws/lambda/${var.lambda_name}-${var.env}"
    retention_in_days = 3
}

