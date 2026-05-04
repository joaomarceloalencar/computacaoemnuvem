"""
Demonstração da diferença de schema entre RDS e DynamoDB.
Execute após setup_rds.py e setup_dynamodb.py.
"""
import os
import psycopg2
import boto3

sep = "=" * 60

# --- RDS: constraint NOT NULL impede inserção sem categoria_id ---
print(sep)
print("RDS: tentativa de inserir produto sem categoria_id (NOT NULL)")
print(sep)

RDS_HOST = os.environ.get("RDS_ENDPOINT", "SEU_ENDPOINT_AQUI")

conn = psycopg2.connect(
    host=RDS_HOST, dbname="postgres",
    user="admindb", password="Demo@2024Seguro"
)
cur = conn.cursor()

try:
    cur.execute("""
        INSERT INTO produtos (nome, preco, estoque)
        VALUES ('Produto sem categoria', 50.00, 10)
    """)
    conn.commit()
    print("Insercao realizada.")
except psycopg2.errors.NotNullViolation as e:
    print(f"ERRO (esperado): violacao de NOT NULL\n  {e}")
    conn.rollback()

cur.close()
conn.close()

# --- DynamoDB: nova categoria com atributos ineditos, sem alterar nada ---
print()
print(sep)
print("DynamoDB: inserindo produto de categoria nova com atributos ineditos")
print(sep)

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabela   = dynamodb.Table('Produtos')

tabela.put_item(Item={
    "categoria":            "Alimentos",
    "produto_id":           "ALI001",
    "nome":                 "Cafe Especial",
    "preco":                "49.90",
    "peso_gramas":          500,
    "torra":                "Media",
    "origem":               "Minas Gerais",
    "certificacao_organica": True,
})
print("Produto inserido com sucesso — nenhuma alteracao de schema necessaria!")
print()
print("Conclusao:")
print("  RDS  -> schema rigido: a estrutura deve existir antes dos dados.")
print("  DynamoDB -> schema flexivel: cada item define seus proprios atributos.")
