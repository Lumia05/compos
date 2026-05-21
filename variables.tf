variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "af-south-1"
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "Your public IP address for SSH access to the bastion"
  type        = string
}

variable "key_name" {
  description = "The name of the AWS key pair to use for the bastion host"
  type        = string
}
