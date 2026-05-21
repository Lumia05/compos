# ==========================================
# OUTPUTS - INFRASTRUCTURE DIGITRANS-CM (DEV)
# ==========================================

output "id_vpc" {
  description = "Identifiant du VPC cree"
  value       = aws_vpc.agricam_vpc.id
}

output "bastion_public_ip" {
  description = "Adresse IP publique du serveur Bastion"
  value       = aws_instance.bastion.public_ip
}

output "rds_endpoint" {
  description = "Point d'acces (Endpoint) de la base RDS"
  value       = aws_db_instance.crm_db.endpoint
}

output "s3_bucket_name" {
  description = "Nom du bucket S3 de stockage"
  value       = aws_s3_bucket.documents.bucket
}

output "sqs_queue_url" {
  description = "URL de la file d'attente SQS"
  value       = aws_sqs_queue.offline_sync.url
}
