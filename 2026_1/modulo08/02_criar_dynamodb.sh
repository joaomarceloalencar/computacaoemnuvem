#!/usr/bin/env bash
# Parte 2: Cria a tabela no Amazon DynamoDB
# Uso: bash 02_criar_dynamodb.sh
# Pré-requisito: AWS CLI configurada (aws configure ou Learner Lab ativo)

set -euo pipefail

REGION="us-east-1"

echo "=== Criando tabela DynamoDB: Produtos ==="
aws dynamodb create-table \
  --table-name "Produtos" \
  --attribute-definitions \
    AttributeName=categoria,AttributeType=S \
    AttributeName=produto_id,AttributeType=S \
  --key-schema \
    AttributeName=categoria,KeyType=HASH \
    AttributeName=produto_id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "=== Aguardando tabela ficar ativa ==="
aws dynamodb wait table-exists \
  --table-name "Produtos" \
  --region "$REGION"

STATUS=$(aws dynamodb describe-table \
  --table-name "Produtos" \
  --region "$REGION" \
  --query "Table.TableStatus" \
  --output text)

echo ""
echo "============================================================"
echo "  Tabela 'Produtos': $STATUS"
echo "  Partition Key : categoria  (String)"
echo "  Sort Key      : produto_id (String)"
echo "  Billing mode  : PAY_PER_REQUEST (On-Demand)"
echo "============================================================"
echo ""
echo "Ponto de discussão:"
echo "  Apenas as chaves foram declaradas. Os demais atributos"
echo "  não precisam de schema — cada item pode ter campos distintos."
