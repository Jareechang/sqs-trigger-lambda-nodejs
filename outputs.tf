output "aws_iam_access_id" {
    value = aws_iam_access_key.dev_key.id
}

output "aws_iam_access_key" {
    value = aws_iam_access_key.dev_key.secret
}

output "aws_queue_url" {
    value = aws_sqs_queue.ingest_queue.id
}

output "instance_ip" {
    value = aws_instance.dev.public_ip
}

output "ssh-key" {
    value = tls_private_key.dev.private_key_pem
}
