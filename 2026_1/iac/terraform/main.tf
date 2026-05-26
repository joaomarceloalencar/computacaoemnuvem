# Instância para o servidor web (NGINX)
# A tag Name=InstanciaNginx é usada pelo inventário dinâmico do Ansible
# para identificar este host como membro do grupo tag_Name_InstanciaNginx.
resource "aws_instance" "nginx" {
  ami             = var.ami
  instance_type   = var.tipo_instancia
  key_name        = var.nome_chave
  security_groups = [aws_security_group.devops.name]

  tags = {
    Name = "InstanciaNginx"
  }
}

# Subnet group usando as subnets da VPC padrão da conta AWS Academy
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "devops" {
  name       = "devops-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

# Banco de dados RDS PostgreSQL
# A senha é fornecida via variável de ambiente: export TF_VAR_db_password="..."
resource "aws_db_instance" "postgres" {
  identifier        = "instancia-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "meubanco"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.devops.name
  vpc_security_group_ids = [aws_security_group.devops.id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0
}

output "ip_nginx" {
  description = "IP público da instância NGINX"
  value       = aws_instance.nginx.public_ip
}

output "endpoint_postgres" {
  description = "Endpoint do banco de dados RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}
