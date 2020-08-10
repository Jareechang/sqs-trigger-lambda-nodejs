variable "aws_region" {
    default = "us-east-1"
}

variable "env" {
    default = "dev"
}

variable "local_ip_address" {}

variable "lambda_name" {
    default = "process-queue-function"
}

variable "lambda_timeout" {
    default = 120
}

