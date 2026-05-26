# Trabalho Prático — Infraestrutura como Código na AWS - 2,0 pontos na Terceira Nota.

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando o uso de ferramentas IaC para provisionar e configurar uma infraestrutura de nuvem na AWS.

---

## Infraestrutura alvo

```
┌─────────────────────────────────────────────┐
│                  AWS (us-east-1)            │
│                                             │
│  ┌──────────────┐       ┌───────────────┐  │
│  │  EC2 (NGINX) │──────▶│  RDS Postgres │  │
│  │  t2.micro    │ :5432 │  db.t3.micro  │  │
│  └──────────────┘       └───────────────┘  │
│         ▲                                   │
│         │ SSH / HTTP                        │
└─────────┼───────────────────────────────────┘
          │
       Internet
```

- **Uma instância EC2** rodando NGINX (provisionada pelo Terraform, configurada pelo Ansible).
- **Um banco de dados RDS PostgreSQL** (provisionado pelo Terraform).
- O banco **não** é instalado em EC2 — essa é a mudança central em relação ao código inicial do repositório.

---

## O que deve aparecer no vídeo

### 1. Explicação das alterações no Terraform

Mostre e explique as mudanças nos arquivos `.tf`:

- **`variables.tf`**: adição da variável `db_password` (sensível, sem valor padrão).
- **`securitygroup.tf`**: nova regra de entrada liberando a porta `5432` (PostgreSQL).
- **`main.tf`**:
  - Remoção da `aws_instance` do PostgreSQL.
  - Adição do `aws_db_subnet_group` e do `aws_db_instance` para o RDS.
  - `output` com o endpoint do RDS no lugar do IP da instância de banco.

### 2. Explicação das alterações no Ansible

Mostre e explique as mudanças nos arquivos Ansible:

- **`playbook.yml`**: remoção da *role* `bancodedados` — o banco agora é gerenciado pelo Terraform (RDS), não pelo Ansible.
- **`roles/web/tasks/main.yml`**: adição da instalação do `postgresql-client` para permitir a conexão ao RDS via `psql`.

### 3. Execução do Terraform

```bash
# Forneça a senha do banco via variável de ambiente
export TF_VAR_db_password="SuaSenhaAqui"

terraform init
terraform plan
terraform apply
```

Mostre os *outputs* ao final — especialmente o `endpoint_postgres`.

### 4. Execução do Ansible

```bash
ansible-playbook -i aws_ec2.yaml playbook.yml
```

### 5. Verificação final

Faça SSH na instância EC2:

```bash
ssh -i ~/labuser.pem ubuntu@<ip_nginx>
```

Conecte ao banco de dados RDS via `psql`:

```bash
psql -h <endpoint_postgres> -U postgres -d meubanco
```

O vídeo pode encerrar com o prompt do `psql` ativo, confirmando que a infraestrutura está funcionando.

---

## Critérios de avaliação

| Critério | Peso |
|---|---|
| Explica corretamente as alterações no Terraform | 40% |
| Explica corretamente as alterações no Ansible | 20% |
| Execução bem-sucedida do `terraform apply` | 20% |
| Conexão ao RDS via `psql` demonstrada | 20% |

---

## Referências

- Código de referência: pasta `iac/` neste repositório.
- Slides: `iac/01_infraestrutura_como_codigo.md`, `iac/02_terraform.md`, `iac/03_ansible.md`.
- Documentação Terraform AWS Provider — [aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- Documentação Ansible — [módulo apt](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
