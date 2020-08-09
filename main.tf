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
