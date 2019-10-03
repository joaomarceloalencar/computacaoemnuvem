#!/bin/bash
# Script exemplo de criação de um função (role) na AWS
NOMEFUNCAO="testeDeCriacaoDeFuncao"
NOMEPOLITICA="testePolitica"
ARQUIVOPOLITICACONFIANCA="politica_de_confianca.json"
ARQUIVOPOLITICA="politicas.json"

# Criar a função - o arquivo de política inicial diz qual serviço irá desempenhar a função
aws iam create-role --role-name $NOMEFUNCAO --assume-role-policy-document file://$ARQUIVOPOLITICACONFIANCA

# Anexa políticas a função - permitir que o serviço que desempenha a função possa acessar os outros 
aws iam put-role-policy --role-name $NOMEFUNCAO --policy-name $NOMEPOLITICA --policy-document file://$ARQUIVOPOLITICA
