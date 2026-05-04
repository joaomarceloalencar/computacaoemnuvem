#!/usr/bin/env bash
# Parte 1: Cria o Security Group e a instância Amazon RDS (PostgreSQL)
# Uso: bash 01_criar_rds.sh
# Pré-requisito: AWS CLI configurada (aws configure ou Learner Lab ativo)

set -euo pipefail

echo "=== Verificando credenciais AWS ==="
aws sts get-caller-identity

echo ""
echo "=== Obtendo VPC padrão ==="
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)
echo "VPC padrão: $VPC_ID"

echo ""
echo "=== Criando Security Group ==="
SG_ID=$(aws ec2 create-security-group \
  --group-name "rds-demo-sg" \
  --description "Security Group para demo RDS" \
  --vpc-id "$VPC_ID" \
  --query "GroupId" \
  --output text)
echo "Security Group criado: $SG_ID"

# ATENÇÃO: 0.0.0.0/0 é adequado apenas para demonstração.
# Em produção, substitua pelo IP da sua aplicação.
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0
echo "Porta 5432 liberada no Security Group."

echo ""
echo "=== Criando instância RDS PostgreSQL (aguarde 5-10 minutos) ==="
aws rds create-db-instance \
  --db-instance-identifier "demo-rds-postgres" \
  --db-instance-class "db.t3.micro" \
  --engine "postgres" \
  --engine-version "16.3" \
  --master-username "admindb" \
  --master-user-password "Demo@2024Seguro" \
  --allocated-storage 20 \
  --storage-type gp2 \
  --vpc-security-group-ids "$SG_ID" \
  --publicly-accessible \
  --no-multi-az \
  --backup-retention-period 0 \
  --no-deletion-protection

echo ""
echo "=== Aguardando instância ficar disponível ==="
aws rds wait db-instance-available \
  --db-instance-identifier "demo-rds-postgres"
echo "Instância disponível!"

echo ""
echo "=== Obtendo endpoint ==="
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "demo-rds-postgres" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

echo ""
echo "============================================================"
echo "  Endpoint RDS: $RDS_ENDPOINT"
echo "  Guarde esse valor e substitua RDS_HOST nos scripts Python."
echo "============================================================"

# Exporta para uso imediato na mesma sessão de shell
export RDS_ENDPOINT
export SG_ID
