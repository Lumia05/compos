terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Récupérer le VPC par défaut (ou crée un VPC dédié)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Groupe de sécurité pour RDS (privé)
resource "aws_security_group" "rds" {
  name        = "digicrm-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id] # uniquement depuis le bastion
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Groupe de sécurité pour le bastion (SSH depuis ton IP)
resource "aws_security_group" "bastion" {
  name        = "digicrm-bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Sous‑réseau pour RDS (obligatoire)
resource "aws_db_subnet_group" "default" {
  name       = "digicrm-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

# Base RDS PostgreSQL (identique à ta création manuelle)
resource "aws_db_instance" "crm_db" {
  identifier     = "digicrm-db"
  engine         = "postgres"
  engine_version = "14.17"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_name        = "crmdb"
  username       = "crmadmin"
  password       = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  backup_retention_period = 7
  storage_encrypted      = true
}

# File SQS pour la synchronisation offline
resource "aws_sqs_queue" "offline_sync" {
  name = "offline-sync-queue"
}

# Bucket S3 pour les documents
resource "aws_s3_bucket" "documents" {
  bucket = "digicrm-docs-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Instance EC2 bastion (optionnelle, mais déjà créée manuellement)
resource "aws_instance" "bastion" {
  ami                    = "ami-0236922087fa98b6e" # Amazon Linux 2023 us-east-1
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  tags = { Name = "digicrm-bastion" }
}