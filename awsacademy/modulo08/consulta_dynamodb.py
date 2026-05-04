import boto3
from boto3.dynamodb.conditions import Key, Attr

REGION = "us-east-1"

dynamodb = boto3.resource('dynamodb', region_name=REGION)
tabela   = dynamodb.Table('Produtos')

sep = "=" * 60
print(sep)
print("CONSULTAS NO AMAZON DynamoDB")
print(sep)

# Consulta 1: Query por Partition Key — eficiente, usa indice primario
print("\n--- Todos os Eletronicos (Query por Partition Key) ---")
resp = tabela.query(
    KeyConditionExpression=Key('categoria').eq('Eletrônicos')
)
for item in resp['Items']:
    print(f"  [{item['produto_id']}] {item['nome']} - R$ {item['preco']}")
    if 'processador' in item:
        print(f"    CPU: {item['processador']}, RAM: {item.get('ram_gb')} GB")
    if 'sistema_operacional' in item:
        print(f"    SO: {item['sistema_operacional']}, "
              f"Armazenamento: {item.get('armazenamento_gb')} GB")

# Consulta 2: GetItem pela chave composta — acesso direto O(1)
print("\n--- Produto especifico (GetItem por chave composta) ---")
resp = tabela.get_item(
    Key={'categoria': 'Livros', 'produto_id': 'LIV001'}
)
item = resp['Item']
print(f"  {item['nome']} por {item['autor']}")
print(f"  ISBN: {item['isbn']}, {item['num_paginas']} paginas ({item['idioma']})")
print(f"  Preco: R$ {item['preco']} | Estoque: {item['estoque']}")

# Consulta 3: Scan com FilterExpression — percorre TODOS os itens
print("\n--- Produtos com estoque > 50 (Scan) ---")
resp = tabela.scan(
    FilterExpression=Attr('estoque').gt(50)
)
for item in resp['Items']:
    print(f"  [{item['categoria']}] {item['nome']} - estoque: {item['estoque']}")

print(f"\n>>> Scan leu {resp['ScannedCount']} item(ns) para retornar {resp['Count']}.")
print(">>> Em tabelas grandes, prefira Query a Scan — Scan le a tabela inteira!")
