# Demonstração: Amazon RDS vs Amazon DynamoDB

## Módulo 08 — Banco de Dados na Nuvem | AWS Academy Cloud Foundations

---

## Cenário

Vamos construir um **catálogo de produtos** para uma loja virtual fictícia. O mesmo conjunto de dados será armazenado no Amazon RDS (PostgreSQL) e no Amazon DynamoDB, evidenciando as características, vantagens e casos de uso de cada serviço.

**Por que esse cenário ilustra bem a diferença?**
- No **RDS**, exploraremos a força dos bancos relacionais: integridade referencial, JOINs e consultas de agregação.
- No **DynamoDB**, exploraremos a flexibilidade do modelo chave-valor/documento: produtos de categorias diferentes com atributos distintos, sem necessidade de schema fixo.

---

## Estrutura dos Arquivos

```
modulo08/
├── README.md                  # este roteiro
├── 01_criar_rds.sh            # cria Security Group e instância RDS
├── 02_criar_dynamodb.sh       # cria tabela DynamoDB
├── 03_limpar_recursos.sh      # remove todos os recursos ao final
├── requirements.txt           # dependências Python
├── setup_rds.py               # cria schema e insere dados no RDS
├── setup_dynamodb.py          # insere dados no DynamoDB
├── consulta_rds.py            # exemplos de consulta no RDS (SQL)
├── consulta_dynamodb.py       # exemplos de consulta no DynamoDB (boto3)
└── demo_schema.py             # demonstra schema fixo (RDS) vs flexível (DynamoDB)
```

---

## Pré-requisitos

- AWS CLI configurada e autenticada (`aws configure` ou perfil do AWS Academy Learner Lab já ativo)
- Python 3.8 ou superior instalado localmente
- Conta AWS com permissões para RDS, DynamoDB e EC2 (Free Tier é suficiente)

Verifique que a AWS CLI está funcionando:

```bash
aws sts get-caller-identity
```

A saída deve mostrar o `UserId`, `Account` e `Arn` da sua sessão. Se retornar erro, configure as credenciais antes de continuar.

---

## Parte 1: Amazon RDS com PostgreSQL

### 1.1 Criar o Security Group e a instância

O script `01_criar_rds.sh` realiza todas as etapas:
1. Identifica a VPC padrão da conta
2. Cria um Security Group liberando a porta 5432
3. Cria a instância `db.t3.micro` com PostgreSQL 16
4. Aguarda a instância ficar `available`
5. Exibe o endpoint ao final

```bash
bash 01_criar_rds.sh
```

A criação leva entre **5 e 10 minutos**. Anote o endpoint exibido ao final — ele será usado nos scripts Python.

> **Nota de segurança:** O script libera a porta 5432 para `0.0.0.0/0` (qualquer IP), adequado apenas para demonstração. Em produção, restrinja ao IP da aplicação ou use acesso via VPC privada.

### 1.2 Ponto de discussão em sala

Mostre ao lado do terminal a aba **Databases** no Console RDS. A instância aparecerá com status *Creating* e depois *Available*. Destaque:
- A necessidade de escolher classe de instância, armazenamento e Multi-AZ
- O contraste com o DynamoDB, que não tem nenhuma dessas configurações

---

## Parte 2: Amazon DynamoDB

O DynamoDB é **serverless** — não há instância para provisionar. A criação de uma tabela é imediata.

```bash
bash 02_criar_dynamodb.sh
```

> **Ponto de discussão em sala:** O script declara apenas as **chaves** (`HASH` = Partition Key, `RANGE` = Sort Key). Os demais atributos não precisam ser declarados — cada item pode ter uma estrutura diferente. Compare isso com o `CREATE TABLE` do SQL, que exige todas as colunas antecipadamente.

---

## Parte 3: Configurar o Ambiente Python

### 3.1 Criar e ativar o virtualenv

```bash
python3 -m venv venv-nuvem

# Linux/macOS
source venv-nuvem/bin/activate

# Windows
# venv-nuvem\Scripts\activate
```

### 3.2 Instalar as dependências

```bash
pip install -r requirements.txt
```

O `requirements.txt` instala:
- **psycopg2-binary** — driver Python para PostgreSQL
- **boto3** — SDK oficial da AWS para Python (inclui DynamoDB)

---

## Parte 4: Popular os Bancos de Dados

### 4.1 RDS

Edite `setup_rds.py` e substitua `SEU_ENDPOINT_AQUI` pelo endpoint obtido no passo 1, ou exporte a variável de ambiente:

```bash
export RDS_ENDPOINT="<endpoint-do-passo-1>"
python setup_rds.py
```

O script cria as tabelas `categorias` e `produtos` e insere 7 registros.

### 4.2 DynamoDB

```bash
python setup_dynamodb.py
```

O script insere 6 produtos usando `batch_writer`. Observe que cada categoria tem **atributos diferentes** — eletrônicos têm `processador` e `ram_gb`; livros têm `autor` e `isbn`; vestuário tem `tamanho` (lista) e `cor`.

---

## Parte 5: Consultas em Python

### 5.1 RDS — SQL completo

```bash
python consulta_rds.py
```

O script demonstra três consultas:
1. `JOIN` entre `produtos` e `categorias` — lista todos os produtos com o nome da categoria
2. Filtro por categoria e faixa de preço — `WHERE c.nome = 'Eletrônicos' AND p.preco > 2000`
3. Agregação — `GROUP BY` com `COUNT`, `AVG` e `SUM` por categoria

### 5.2 DynamoDB — Query, GetItem e Scan

```bash
python consulta_dynamodb.py
```

O script demonstra três formas de acesso:

| Operação | Quando usar | Custo de leitura |
|---|---|---|
| `GetItem` | chave exata conhecida | 1 unidade por item |
| `Query` | todos os itens de uma Partition Key | proporcional aos itens retornados |
| `Scan` | filtro sem chave (evitar em produção) | lê **toda** a tabela |

---

## Parte 6: Schema Fixo vs Flexível

```bash
python demo_schema.py
```

O script executa dois experimentos lado a lado:
- **RDS**: tenta inserir um produto sem `categoria_id` → recebe `NotNullViolation`
- **DynamoDB**: insere um produto da categoria "Alimentos" com atributos totalmente novos (`peso_gramas`, `torra`, `origem`) → sucesso imediato

> **Ponto de discussão:** No RDS, adicionar uma nova categoria pode exigir `ALTER TABLE`. No DynamoDB, simplesmente inserimos um item com os atributos necessários — o banco aceita qualquer estrutura.

---

## Parte 7: Tabela Comparativa

| Aspecto | Amazon RDS (PostgreSQL) | Amazon DynamoDB |
|---|---|---|
| **Modelo de dados** | Relacional (tabelas, linhas, colunas) | Chave-valor / Documento |
| **Schema** | Fixo — definido antes da inserção | Flexível — cada item pode ter atributos distintos |
| **Linguagem de consulta** | SQL completo: JOINs, GROUP BY, subqueries | Query (por chave) e Scan (varredura total) |
| **Escalabilidade** | Vertical + réplicas de leitura | Horizontal automática, serverless |
| **Consistência** | ACID total | Eventual (padrão) ou forte (por requisição) |
| **Administração** | Instância gerenciada (patches, backups) | Totalmente serverless — zero operação |
| **Latência típica** | Milissegundos | Sub-milissegundo para GetItem/Query |
| **Modelo de custo** | Por hora de instância + armazenamento | Por unidades de leitura/escrita + armazenamento |
| **Melhor para** | ERP, CRM, sistemas financeiros, relatórios | Sessões, IoT, gaming, catálogos, carrinhos |

### Quando escolher cada serviço?

**Use o RDS quando:**
- Os dados têm relacionamentos complexos entre entidades (pedidos, clientes, produtos)
- Você precisa de consultas ad-hoc flexíveis para relatórios e análises
- A consistência ACID é obrigatória (transações financeiras, estoque)
- A equipe já domina SQL

**Use o DynamoDB quando:**
- A escala é imprevisível ou muito elevada (picos de milhões de req/seg)
- O padrão de acesso é bem definido — quase sempre busca por chave primária
- Os itens têm estruturas variáveis por tipo (catálogos, documentos JSON)
- Você quer zero administração de infraestrutura

---

## Parte 8: Limpeza dos Recursos

Execute ao final da demonstração para evitar cobranças contínuas:

```bash
bash 03_limpar_recursos.sh
```

O script remove, nesta ordem:
1. Instância RDS (aguarda a exclusão completa)
2. Tabela DynamoDB
3. Security Group

---

## Ordem de Execução — Resumo

```
aws sts get-caller-identity          # verificar credenciais

bash 01_criar_rds.sh                 # ~5-10 min
bash 02_criar_dynamodb.sh            # imediato

python3 -m venv venv-nuvem
source venv-nuvem/bin/activate
pip install -r requirements.txt

export RDS_ENDPOINT="<endpoint>"
python setup_rds.py
python setup_dynamodb.py

python consulta_rds.py
python consulta_dynamodb.py
python demo_schema.py

bash 03_limpar_recursos.sh           # ao final da aula
```

---

*Demonstração desenvolvida para o Módulo 08 — Banco de Dados | AWS Academy Cloud Foundations*
