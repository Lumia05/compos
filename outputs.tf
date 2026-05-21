output "rds_endpoint" {
  value = aws_db_instance.crm_db.endpoint
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "sqs_queue_url" {
  value = aws_sqs_queue.offline_sync.url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.documents.bucket
}