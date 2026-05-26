variable "regiao" {
  description = "Região AWS"
  default     = "us-east-1"
}

variable "ami" {
  description = "AMI da instância (específica por região — us-east-1)"
  default     = "ami-0c7217cdde317cfec"
}

variable "tipo_instancia" {
  description = "Tipo da instância EC2"
  default     = "t2.micro"
}

variable "nome_chave" {
  description = "Nome do par de chaves SSH (deve existir na sua conta AWS)"
  default     = "vockey"
}

variable "db_password" {
  description = "Senha do banco de dados RDS PostgreSQL"
  sensitive   = true
}
