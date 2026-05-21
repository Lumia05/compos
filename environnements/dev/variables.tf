variable "aws_region" {
  description = "Region AWS ou deployer les ressources"
  type        = string
  default     = "af-south-1"
}

variable "environnement" {
  description = "Nom de l'environnement (dev, staging, prod)"
  type        = string
}

variable "type_instance" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro" # Ajusté en t3.micro car le t2 n'existe pas au Cap (af-south-1)
}

variable "ami_id" {
  description = "ID de l'image AMI (systeme d'exploitation)"
  type        = string
  default     = "ami-0c071a93b512a5987" # AMI Amazon Linux 2023 pour af-south-1
}

# 🛠️ AJOUT D'UNE VALEUR PAR DÉFAUT POUR LA CI/CD
variable "ip_admin" {
  description = "IP de l'admin autorise au SSH (format x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0" # Autorise tout Internet par défaut pour éviter que le pipeline GitHub ne plante
}

variable "key_name" {
  description = "The name of the AWS key pair to use for the bastion host"
  type        = string
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}