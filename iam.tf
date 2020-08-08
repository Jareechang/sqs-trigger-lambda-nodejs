
provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

resource "aws_iam_user" "dev_user" {
  name = "dev-user"
}

resource "aws_iam_access_key" "dev_key" {
  user = aws_iam_user.dev_user.name
}
