output "aws_iam_user" {
    value = aws_iam_user.dev_user.unique_id
}

output "aws_iam_access_key" {
    value = aws_iam_access_key.dev_key.secret
}
