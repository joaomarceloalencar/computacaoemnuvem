#!/usr/bin/env bash
# Parte 8: Remove todos os recursos criados durante a demonstração
# Uso: bash 03_limpar_recursos.sh
# ATENÇÃO: esta operação é irreversível. Execute apenas ao final da aula.

set -euo pipefail

REGION="us-east-1"

echo "=== Deletando instância RDS ==="
aws rds delete-db-instance \
  --db-instance-identifier "demo-rds-postgres" \
  --skip-final-snapshot

echo "Aguardando exclusão da instância RDS (pode levar alguns minutos)..."
aws rds wait db-instance-deleted \
  --db-instance-identifier "demo-rds-postgres"
echo "Instância RDS removida."

echo ""
echo "=== Deletando tabela DynamoDB ==="
aws dynamodb delete-table \
  --table-name "Produtos" \
  --region "$REGION"
echo "Tabela DynamoDB removida."

echo ""
echo "=== Deletando Security Group ==="
# Obtém o ID pelo nome caso a variável SG_ID não esteja no ambiente
SG_ID=${SG_ID:-$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=rds-demo-sg" \
  --query "SecurityGroups[0].GroupId" \
  --output text)}

if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  aws ec2 delete-security-group --group-id "$SG_ID"
  echo "Security Group $SG_ID removido."
else
  echo "Security Group 'rds-demo-sg' não encontrado — pode já ter sido removido."
fi

echo ""
echo "============================================================"
echo "  Todos os recursos da demonstração foram removidos."
echo "============================================================"
