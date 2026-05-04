import os
import psycopg2
from psycopg2.extras import RealDictCursor

RDS_HOST = os.environ.get("RDS_ENDPOINT", "SEU_ENDPOINT_AQUI")
DB_NAME  = "postgres"
DB_USER  = "admindb"
DB_PASS  = "Demo2024Seguro"

conn = psycopg2.connect(host=RDS_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
cur  = conn.cursor(cursor_factory=RealDictCursor)

sep = "=" * 60
print(sep)
print("CONSULTAS NO AMAZON RDS (PostgreSQL)")
print(sep)

# Consulta 1: JOIN entre produtos e categorias
print("\n--- Todos os produtos com categoria ---")
cur.execute("""
    SELECT p.nome, p.preco, p.estoque, c.nome AS categoria
    FROM   produtos p
    JOIN   categorias c ON p.categoria_id = c.id
    ORDER  BY c.nome, p.preco DESC
""")
for row in cur.fetchall():
    print(f"  [{row['categoria']}] {row['nome']} "
          f"- R$ {row['preco']} (estoque: {row['estoque']})")

# Consulta 2: filtro por categoria e faixa de preco
print("\n--- Eletronicos acima de R$ 2.000,00 ---")
cur.execute("""
    SELECT p.nome, p.preco
    FROM   produtos p
    JOIN   categorias c ON p.categoria_id = c.id
    WHERE  c.nome = 'Eletrônicos' AND p.preco > 2000
    ORDER  BY p.preco DESC
""")
for row in cur.fetchall():
    print(f"  {row['nome']} - R$ {row['preco']}")

# Consulta 3: agregacao por categoria
print("\n--- Resumo por categoria (GROUP BY) ---")
cur.execute("""
    SELECT c.nome                   AS categoria,
           COUNT(*)                 AS total_produtos,
           ROUND(AVG(p.preco), 2)   AS preco_medio,
           SUM(p.estoque)           AS estoque_total
    FROM   produtos p
    JOIN   categorias c ON p.categoria_id = c.id
    GROUP  BY c.nome
    ORDER  BY preco_medio DESC
""")
for row in cur.fetchall():
    print(f"  {row['categoria']}: {row['total_produtos']} produtos | "
          f"media R$ {row['preco_medio']} | estoque total: {row['estoque_total']}")

cur.close()
conn.close()
