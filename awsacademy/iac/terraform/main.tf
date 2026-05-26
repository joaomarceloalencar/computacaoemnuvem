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

# Instância para o banco de dados (MySQL)
# A tag Name=InstanciaMySql é usada pelo Ansible
# para identificar este host como membro do grupo tag_Name_InstanciaMySql.
resource "aws_instance" "mysql" {
  ami             = var.ami
  instance_type   = var.tipo_instancia
  key_name        = var.nome_chave
  security_groups = [aws_security_group.devops.name]

  tags = {
    Name = "InstanciaMySql"
  }
}

output "ip_nginx" {
  description = "IP público da instância NGINX"
  value       = aws_instance.nginx.public_ip
}

output "ip_mysql" {
  description = "IP público da instância MySQL"
  value       = aws_instance.mysql.public_ip
}
