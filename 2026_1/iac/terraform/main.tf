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

# Instância para o banco de dados (PostgreSQL)
# A tag Name=InstanciaPostgres é usada pelo Ansible
# para identificar este host como membro do grupo tag_Name_InstanciaPostgres.
resource "aws_instance" "postgres" {
  ami             = var.ami
  instance_type   = var.tipo_instancia
  key_name        = var.nome_chave
  security_groups = [aws_security_group.devops.name]

  tags = {
    Name = "InstanciaPostgres"
  }
}

output "ip_nginx" {
  description = "IP público da instância NGINX"
  value       = aws_instance.nginx.public_ip
}

output "ip_postgres" {
  description = "IP público da instância PostgreSQL"
  value       = aws_instance.postgres.public_ip
}
