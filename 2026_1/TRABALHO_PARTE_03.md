# Trabalho Prático — Implantação de Aplicação Conteinerizada com IaC — 2,5 pontos na Terceira Nota

**Data de entrega:** 24/06/2026

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando o uso integrado de Terraform, Ansible e Docker Compose para implantar uma aplicação composta por múltiplos contêineres em uma instância de nuvem.

---

## Infraestrutura alvo

```
┌─────────────────────────────────────────────────────────┐
│                  AWS (us-east-1)                        │
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │                EC2 (t2.micro)                 │    │
│   │                                               │    │
│   │   ┌─────────┐    /app1     ┌─────────┐       │    │
│   │   │         │ ─────────▶  │  app1   │       │    │
│   │   │  nginx  │              │ showip  │       │    │
│   │   │  :80    │ ─────────▶  ├─────────┤       │    │
│   │   │         │    /app2     │  app2   │       │    │
│   │   └─────────┘              │ showip  │       │    │
│   │        ▲                   └─────────┘       │    │
│   │        │ Docker Compose · rede devops        │    │
│   └────────┼──────────────────────────────────────┘    │
└────────────┼───────────────────────────────────────────┘
             │ HTTP (porta 80)
          Internet
```

- **Uma instância EC2** (provisionada pelo Terraform, configurada pelo Ansible).
- **Três contêineres** em execução na instância, orquestrados pelo Docker Compose:
  - `nginx` exposto na porta 80, servindo de *proxy* reverso.
  - `app1` e `app2`, instâncias da aplicação Python *showip* (Flask + gunicorn) que retorna o IP interno do contêiner.
- Não há banco de dados nem instâncias adicionais — toda a aplicação roda dentro de um único *host* Docker.

---

## O que deve aparecer no vídeo

### 1. Alterações no Terraform

Mostre e explique as mudanças nos arquivos `.tf` em relação ao Trabalho Parte 01:

- **`securitygroup.tf`**: regra de entrada liberando a porta `80` (HTTP) para o mundo. Não precisa mais liberar 5432.
- **`main.tf`**:
  - Remoção do `aws_db_subnet_group` e do `aws_db_instance` — não há mais RDS.
  - Manutenção da `aws_instance` que hospedará o Docker.
  - `output` com o IP público da instância EC2.
- **`variables.tf`**: remoção da variável `db_password`.

### 2. Alterações no Ansible

Mostre e explique as mudanças no *playbook* e *roles*:

- **`playbook.yml`**: substituição da *role* `web` por uma nova *role* (ex: `docker`) responsável por instalar Docker e implantar a aplicação.
- **`roles/docker/tasks/main.yml`**: deve conter as tarefas para:
  - Instalar `docker-ce`, `docker-ce-cli`, `containerd.io` e `docker-compose-plugin`.
  - Adicionar o usuário `ubuntu` ao grupo `docker`.
  - Copiar o diretório da aplicação (`Dockerfile`, `requirements.txt`, `__init__.py`, `wsgi.py`, `default.conf`, `docker-compose.yml`) para a instância.
  - Construir a imagem `showip:latest` com `docker build`.
  - Subir os contêineres com `docker compose up -d`.

### 3. Estrutura da aplicação enviada à instância

Mostre brevemente os arquivos que o Ansible copia para a EC2:

- `Dockerfile` da aplicação *showip* (Python 3.10-alpine + gunicorn).
- `requirements.txt` com Flask e gunicorn.
- `showip/__init__.py` com a rota que retorna o IP interno do contêiner.
- `wsgi.py` com o ponto de entrada para o gunicorn.
- `default.conf` do *nginx* com `proxy_pass` para `app1` e `app2`.
- `docker-compose.yml` declarando os serviços `nginx`, `app1`, `app2` e a rede `devops`.

> O código completo da aplicação está disponível em `docker/03_composicao_de_conteineres.md`.

### 4. Execução do Terraform

```bash
terraform init
terraform plan
terraform apply
```

Mostre os *outputs* ao final — especialmente o IP público da EC2.

### 5. Execução do Ansible

```bash
ansible-playbook -i aws_ec2.yaml playbook.yml
```

### 6. Verificação final

No navegador (ou via `curl`), acesse:

```
http://<ip_publico>/app1
http://<ip_publico>/app2
```

O vídeo deve evidenciar que:

- Ambas as rotas respondem com sucesso.
- Os endereços IP retornados por `/app1` e `/app2` são **diferentes**, comprovando que o *nginx* está direcionando para contêineres distintos na rede interna *devops*.

---

## Critérios de avaliação

| Critério | Peso |
|---|---|
| Explica corretamente as alterações no Terraform | 20% |
| Explica corretamente a *role* Ansible para Docker | 25% |
| Execução bem-sucedida do `terraform apply` | 15% |
| Execução bem-sucedida do `ansible-playbook` | 15% |
| `http://<ip>/app1` e `http://<ip>/app2` respondem com IPs distintos | 25% |

---

## Referências

- Código de referência: pasta `iac/` (Terraform e Ansible base).
- Slides do módulo Docker: `docker/01_introducao_docker.md`, `docker/02_criacao_imagens_dockerfile.md`, `docker/03_composicao_de_conteineres.md`.
- Trabalho Parte 01 (`TRABALHO_PARTE_01.md`) — ponto de partida para o Terraform e Ansible.
- Documentação Ansible — [módulo community.docker](https://docs.ansible.com/ansible/latest/collections/community/docker/index.html)
- Documentação oficial do Docker Compose — <https://docs.docker.com/compose/>
