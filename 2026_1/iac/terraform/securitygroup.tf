resource "aws_security_group" "devops" {
  name        = "devops"
  description = "Grupo de Segurança da Disciplina DevOps"
  tags = {
    Name = "devops"
  }
}

# SSH — necessário para o Ansible acessar as instâncias
resource "aws_vpc_security_group_ingress_rule" "permitir_ssh_ipv4" {
  security_group_id = aws_security_group.devops.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# HTTP — necessário para acessar o NGINX
resource "aws_vpc_security_group_ingress_rule" "permitir_http_ipv4" {
  security_group_id = aws_security_group.devops.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# PostgreSQL — necessário para a EC2 conectar ao RDS
resource "aws_vpc_security_group_ingress_rule" "permitir_postgres_ipv4" {
  security_group_id = aws_security_group.devops.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

# Saída irrestrita — necessária para apt instalar pacotes
resource "aws_vpc_security_group_egress_rule" "permitir_saida_ipv4" {
  security_group_id = aws_security_group.devops.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
