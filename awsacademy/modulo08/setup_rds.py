import os
import psycopg2

RDS_HOST = os.environ.get("RDS_ENDPOINT", "SEU_ENDPOINT_AQUI")
DB_NAME  = "postgres"
DB_USER  = "admindb"
DB_PASS  = "Demo@2024Seguro"
DB_PORT  = 5432

conn = psycopg2.connect(
    host=RDS_HOST, dbname=DB_NAME,
    user=DB_USER, password=DB_PASS, port=DB_PORT
)
conn.autocommit = True
cur = conn.cursor()

cur.execute("""
    CREATE TABLE IF NOT EXISTS categorias (
        id   SERIAL PRIMARY KEY,
        nome VARCHAR(100) NOT NULL UNIQUE
    )
""")

cur.execute("""
    CREATE TABLE IF NOT EXISTS produtos (
        id           SERIAL PRIMARY KEY,
        nome         VARCHAR(200)   NOT NULL,
        preco        NUMERIC(10, 2) NOT NULL,
        estoque      INTEGER        NOT NULL DEFAULT 0,
        categoria_id INTEGER        NOT NULL REFERENCES categorias(id)
    )
""")

cur.execute("""
    INSERT INTO categorias (nome)
    VALUES ('Eletrônicos'), ('Livros'), ('Vestuário')
    ON CONFLICT DO NOTHING
""")

produtos = [
    ("Notebook Dell XPS 15",              8999.90, 15, 1),
    ("Smartphone Samsung Galaxy S24",     4499.00, 42, 1),
    ("Fone de Ouvido Sony WH-1000XM5",    1899.00, 30, 1),
    ("Python Fluente - Luciano Ramalho",   129.90, 100, 2),
    ("Clean Code - Robert Martin",          89.90,  75, 2),
    ("Camiseta Polo Lacoste",              399.00,  50, 3),
    ("Tenis Nike Air Max",                 699.90,  60, 3),
]

cur.executemany("""
    INSERT INTO produtos (nome, preco, estoque, categoria_id)
    VALUES (%s, %s, %s, %s)
""", produtos)

print(f"{len(produtos)} produto(s) inserido(s) no RDS.")

cur.close()
conn.close()
