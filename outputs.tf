output "aws_iam_access_id" {
    value = aws_iam_access_key.dev_key.id
}

output "aws_iam_access_key" {
    value = aws_iam_access_key.dev_key.secret
}

output "aws_queue_url" {
    value = aws_sqs_queue.ingest_queue.id

}
