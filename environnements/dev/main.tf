terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================
# 5.2 LE RÉSEAU PRIVÉ VIRTUEL (VPC) - SUJET
# ==========================================

# VPC : Le réseau privé isolé dans AWS
resource "aws_vpc" "agricam_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name          = "digicrm-vpc-dev"
    Projet        = "DIGITRANS-CM"
    Entreprise    = "CamTech Solutions"
    Environnement = "dev"
  }
}

# Sous-réseau public
resource "aws_subnet" "agricam_subnet" {
  vpc_id                  = aws_vpc.agricam_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "digicrm-subnet-dev"
  }
}

# Passerelle Internet
resource "aws_internet_gateway" "agricam_igw" {
  vpc_id = aws_vpc.agricam_vpc.id

  tags = {
    Name = "digicrm-igw-dev"
  }
}

# Table de routage
resource "aws_route_table" "agricam_rt" {
  vpc_id = aws_vpc.agricam_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.agricam_igw.id
  }

  tags = {
    Name = "digicrm-rt-dev"
  }
}

# Association route table / subnet
resource "aws_route_table_association" "agricam_rta" {
  subnet_id      = aws_subnet.agricam_subnet.id
  route_table_id = aws_route_table.agricam_rt.id
}

# ==========================================
# GROUPES DE SÉCURITÉ (Adaptés au nouveau VPC)
# ==========================================

resource "aws_security_group" "bastion" {
  name        = "digicrm-bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.agricam_vpc.id # Utilise le nouveau VPC créé au-dessus

ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ip_admin] # 👈 Remplace TOUTE la ligne par ça !
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "digicrm-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.agricam_vpc.id # Utilise le nouveau VPC créé au-dessus

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# RESSOURCES APPLICATIVES & STOCKAGE
# ==========================================

resource "aws_db_subnet_group" "default" {
  name       = "digicrm-db-subnet-group"
  subnet_ids = [aws_subnet.agricam_subnet.id] # Utilise le nouveau sous-réseau
}

resource "aws_db_instance" "crm_db" {
  identifier              = "digicrm-db"
  engine                  = "postgres"
  engine_version          = "14.17"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "crmdb"
  username                = "crmadmin"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 7
  storage_encrypted       = true
}

resource "aws_sqs_queue" "offline_sync" {
  name = "offline-sync-queue"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "documents" {
  bucket = "digicrm-docs-${random_id.suffix.hex}"
}

resource "aws_instance" "bastion" {
  ami                         = "ami-01d7ee76e5d6d84a7" # AWS Linux 2023 af-south-1
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = aws_subnet.agricam_subnet.id # Met le Bastion dans le nouveau sous-réseau public
  associate_public_ip_address = true

  tags = { Name = "digicrm-bastion" }
}
