import boto3

REGION = "us-east-1"

dynamodb = boto3.resource('dynamodb', region_name=REGION)
tabela   = dynamodb.Table('Produtos')

# Cada categoria tem atributos próprios — nenhuma declaração de schema necessária.
produtos = [
    # Eletrônicos: processador, ram_gb, voltagem, garantia_meses
    {
        "categoria": "Eletrônicos", "produto_id": "ELET001",
        "nome": "Notebook Dell XPS 15", "preco": "8999.90", "estoque": 15,
        "voltagem": "Bivolt", "garantia_meses": 12,
        "processador": "Intel Core i7", "ram_gb": 16,
    },
    {
        "categoria": "Eletrônicos", "produto_id": "ELET002",
        "nome": "Smartphone Samsung Galaxy S24", "preco": "4499.00", "estoque": 42,
        "voltagem": "5V", "garantia_meses": 12,
        "sistema_operacional": "Android 14", "armazenamento_gb": 256,
    },
    # Livros: autor, isbn, num_paginas, idioma
    {
        "categoria": "Livros", "produto_id": "LIV001",
        "nome": "Python Fluente", "preco": "129.90", "estoque": 100,
        "autor": "Luciano Ramalho", "isbn": "978-8575228418",
        "num_paginas": 792, "idioma": "Português",
    },
    {
        "categoria": "Livros", "produto_id": "LIV002",
        "nome": "Clean Code", "preco": "89.90", "estoque": 75,
        "autor": "Robert C. Martin", "isbn": "978-0132350884",
        "num_paginas": 431, "idioma": "Inglês",
    },
    # Vestuário: tamanho (lista), material, cor
    {
        "categoria": "Vestuário", "produto_id": "VES001",
        "nome": "Camiseta Polo Lacoste", "preco": "399.00", "estoque": 50,
        "tamanho": ["P", "M", "G", "GG"], "material": "100% Algodão", "cor": "Branca",
    },
    {
        "categoria": "Vestuário", "produto_id": "VES002",
        "nome": "Tenis Nike Air Max", "preco": "699.90", "estoque": 60,
        "tamanho": [38, 39, 40, 41, 42, 43], "material": "Sintético", "cor": "Preto",
    },
]

with tabela.batch_writer() as batch:
    for produto in produtos:
        batch.put_item(Item=produto)

print(f"{len(produtos)} produto(s) inserido(s) no DynamoDB.")
