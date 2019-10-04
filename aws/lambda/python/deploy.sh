#!/bin/bash
# Este script faz o deploy da função Lambda ExemploS3
# Parâmetros: [id do ROLE] [bucket] [nome da função]
ROLE=$1
BUCKET=$2
FUNCTION=$3

# Criar o zip com a função
zip -r9 function.zip lambda_function.py

# Criar a função
aws lambda create-function --function $FUNCTION --runtime python3.7 --role $ROLE --handle lambda_function.lambda_handler --zip-file fileb://function.zip
