resource "aws_sqs_queue" "ingest_queue" {
    name = "ingest-queue"
    tags = {
        Environment = "dev"
    }
}
