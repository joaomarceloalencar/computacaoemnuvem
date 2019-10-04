#!/bin/bash
# Script simples para criação de um bucket e copiar arquivo para ele

# O nome do bucket precisa ser único
NOMEBUCKET="treinamentoawsufcqx0310"

# Criar o bucket
aws s3api create-bucket --bucket $NOMEBUCKET

# Mover arquivo para o Bucket
aws s3 cp criar_bucket.sh s3://$NOMEBUCKET

# Listar o conteúdo do Bucket
aws s3 ls $NOMEBUCKET

# Remover o conteúdo do Bucket
aws s3 rm s3://$NOMEBUCKET/ --recursive

# Remover o bucket
aws s3api delete-bucket --bucket $NOMEBUCKET
