# Exemplo Completo — Calculadora com CI/CD

Nesta aula construímos um exemplo maior, do início ao fim: uma aplicação *web* de **calculadora** em Python + Flask, conteinerizada com Docker, com um *pipeline* de **Integração e Entrega Contínua** no GitHub Actions. A cada `push` no *branch* `main`, o GitHub Actions irá:

1. Construir a imagem Docker (validando que o *build* funciona).
2. Executar testes das operações aritméticas.
3. Implantar a nova versão em uma instância EC2, via SSH, recarregando a aplicação automaticamente.

O objetivo final é simples e poderoso: **mudar um trecho do HTML ou do código Python, fazer `push`, e ver a alteração no ar em produção sem nenhum passo manual.**

## Visão geral do *pipeline*

```
  ┌────────────┐   git push main   ┌──────────────────────────────┐
  │  Sua       │ ────────────────▶ │   GitHub: calculadora-python │
  │  máquina   │                   │   .github/workflows/ci-cd.yml│
  └────────────┘                   └───────────────┬──────────────┘
                                                   │ evento push
                                                   ▼
                              ┌──────────────────────────────────┐
                              │  Job 1: build-and-test           │
                              │   • docker build                 │
                              │   • pytest (operações)           │
                              └───────────────┬──────────────────┘
                                              │ sucesso
                                              ▼
                              ┌──────────────────────────────────┐
                              │  Job 2: deploy (SSH)             │
                              │   • rsync do código → EC2        │
                              │   • docker compose up -d --build │
                              └───────────────┬──────────────────┘
                                              ▼
                              ┌──────────────────────────────────┐
                              │  EC2 Ubuntu + Docker             │
                              │   calculadora :80  ◀── HTTP      │
                              └──────────────────────────────────┘
```

## Pré-requisitos

- Conta no GitHub com um repositório **novo e vazio** chamado `calculadora-python`.
- A ferramenta de linha de comando da AWS (`aws`) já configurada e funcionando.
- Docker instalado na sua máquina (opcional, apenas para testar localmente).

---

## Passo 1 — Estrutura do repositório

Crie a seguinte estrutura de arquivos no diretório do repositório clonado:

```
calculadora-python/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # Pipeline de CI/CD
├── templates/
│   └── index.html             # Formulário da calculadora
├── tests/
│   └── test_calculadora.py    # Testes das operações
├── calculadora.py             # Lógica aritmética (pura, testável)
├── app.py                     # Aplicação Flask (rotas)
├── wsgi.py                    # Ponto de entrada do gunicorn
├── requirements.txt           # Dependências Python
├── Dockerfile                 # Receita da imagem
└── docker-compose.yml         # Orquestração do contêiner
```

> Crie todos os arquivos abaixo, mas **só faça o `push` no final**, quando o *pipeline* estiver completo.

---

## Passo 2 — A lógica da calculadora

Separamos a aritmética em um módulo próprio, `calculadora.py`. Isso a torna **fácil de testar** sem precisar subir o servidor *web*.

```python
# calculadora.py

def calcular(a, b, operacao):
    if operacao == "somar":
        return a + b
    if operacao == "subtrair":
        return a - b
    if operacao == "multiplicar":
        return a * b
    if operacao == "dividir":
        if b == 0:
            raise ValueError("Divisão por zero não é permitida.")
        return a / b
    raise ValueError(f"Operação desconhecida: {operacao}")
```

---

## Passo 3 — A aplicação Flask

O arquivo `app.py` define a rota principal. Em `GET`, exibe o formulário; em `POST`, lê os valores, chama a função `calcular` e devolve o resultado (ou o erro).

```python
# app.py
from flask import Flask, render_template, request

from calculadora import calcular

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def index():
    resultado = None
    erro = None
    if request.method == "POST":
        try:
            a = float(request.form["a"])
            b = float(request.form["b"])
            operacao = request.form["operacao"]
            resultado = calcular(a, b, operacao)
        except (ValueError, KeyError) as e:
            erro = str(e)
    return render_template("index.html", resultado=resultado, erro=erro)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
```

O ponto de entrada para o *gunicorn* (servidor de produção) fica em `wsgi.py`:

```python
# wsgi.py
from app import app

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
```

---

## Passo 4 — O formulário HTML

O *template* `templates/index.html` tem as duas entradas numéricas, a caixa de seleção da operação, o botão de calcular e a exibição do resultado.

```html
<!-- templates/index.html -->
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>Calculadora DevOps</title>
    <style>
        body { font-family: sans-serif; max-width: 360px; margin: 48px auto; }
        input, select, button { display: block; width: 100%; margin: 8px 0; padding: 10px; box-sizing: border-box; }
        button { background: #2c7; color: #fff; border: 0; cursor: pointer; font-size: 1em; }
        .resultado { font-size: 1.4em; margin-top: 20px; }
        .erro { color: #c0392b; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Calculadora DevOps</h1>
    <form method="post">
        <input type="number" step="any" name="a" placeholder="Primeiro número" required>
        <select name="operacao">
            <option value="somar">Somar (+)</option>
            <option value="subtrair">Subtrair (−)</option>
            <option value="multiplicar">Multiplicar (×)</option>
            <option value="dividir">Dividir (÷)</option>
        </select>
        <input type="number" step="any" name="b" placeholder="Segundo número" required>
        <button type="submit">Calcular</button>
    </form>

    {% if resultado is not none %}
    <div class="resultado">Resultado: {{ resultado }}</div>
    {% endif %}
    {% if erro %}
    <div class="erro">Erro: {{ erro }}</div>
    {% endif %}
</body>
</html>
```

---

## Passo 5 — Dependências e testes

Arquivo `requirements.txt`:

```
Flask
gunicorn
pytest
```

Arquivo `tests/test_calculadora.py` — cobre as quatro operações, a divisão por zero e uma operação inválida:

```python
# tests/test_calculadora.py
import pytest

from calculadora import calcular


def test_somar():
    assert calcular(2, 3, "somar") == 5


def test_subtrair():
    assert calcular(10, 4, "subtrair") == 6


def test_multiplicar():
    assert calcular(6, 7, "multiplicar") == 42


def test_dividir():
    assert calcular(20, 5, "dividir") == 4


def test_dividir_por_zero():
    with pytest.raises(ValueError):
        calcular(1, 0, "dividir")


def test_operacao_invalida():
    with pytest.raises(ValueError):
        calcular(1, 2, "potencia")
```

---

## Passo 6 — Dockerfile

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Servidor de produção: gunicorn carregando "app" do módulo "wsgi"
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:8000", "wsgi:app"]
```

---

## Passo 7 — docker-compose.yml

O *Compose* descreve o serviço, mapeando a porta `80` do *host* para a `8000` do contêiner (onde o *gunicorn* escuta).

```yaml
# docker-compose.yml
services:
  web:
    build: .
    image: calculadora-python:latest
    ports:
      - "80:8000"
    restart: unless-stopped
```

### Testando localmente (opcional)

Antes de seguir, você pode validar tudo na sua máquina:

```bash
docker compose up --build
# Acesse http://localhost no navegador
```

---

## Passo 8 — Provisionando a instância EC2

Vamos criar uma instância Ubuntu com Docker já instalado. Primeiro, o *script* de inicialização (*user-data*) que instala o Docker assim que a máquina liga.

Crie o arquivo `user-data.sh`:

```bash
#!/bin/bash
set -e

# Instala o Docker seguindo o repositório oficial
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

ARCH=$(dpkg --print-architecture)
. /etc/os-release
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Permite ao usuário ubuntu usar docker sem sudo
usermod -aG docker ubuntu
```

Agora o *script* que cria a chave SSH, o *security group* e a instância. Crie `criar-ec2.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
KEY_NAME="calculadora-key"
SG_NAME="calculadora-sg"
INSTANCE_TYPE="t2.micro"
TAG_NAME="calculadora-python"

# 1. AMI mais recente do Ubuntu 22.04 (via SSM Parameter Store)
AMI_ID=$(aws ssm get-parameters \
  --region "$REGION" \
  --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
  --query 'Parameters[0].Value' --output text)
echo "AMI Ubuntu: $AMI_ID"

# 2. Par de chaves SSH (a chave privada é salva localmente)
aws ec2 create-key-pair --region "$REGION" --key-name "$KEY_NAME" \
  --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
chmod 600 "${KEY_NAME}.pem"
echo "Chave privada salva em ${KEY_NAME}.pem"

# 3. Security group liberando SSH (22) e HTTP (80)
SG_ID=$(aws ec2 create-security-group --region "$REGION" \
  --group-name "$SG_NAME" \
  --description "Calculadora Python - SSH e HTTP" \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0

# 4. Instância EC2 com o user-data que instala o Docker
INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
  --query 'Instances[0].InstanceId' --output text)
echo "Instância: $INSTANCE_ID — aguardando ficar disponível..."

aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "-----------------------------------------------"
echo "IP público da EC2: $PUBLIC_IP"
echo "Acesso SSH: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
echo "-----------------------------------------------"
```

Execute:

```bash
chmod +x criar-ec2.sh
./criar-ec2.sh
```

Anote o **IP público** exibido ao final. A instalação do Docker pela *user-data* leva 1–2 minutos após a instância ligar.

> **Sobre o IP:** não usaremos IP elástico. O IP público capturado serve para esta execução do *pipeline*. Se a instância for parada e reiniciada, o IP muda — bastaria atualizar o *secret* correspondente.

---

## Passo 9 — Configurando os *Secrets* no GitHub

O *job* de *deploy* precisa de dados sensíveis que **não** podem ir para o código. No repositório, vá em **Settings → Secrets and variables → Actions → New repository secret** e crie:

| Secret | Valor |
|---|---|
| `EC2_HOST` | O IP público da EC2 (ex.: `54.91.x.x`) |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | O conteúdo **completo** do arquivo `calculadora-key.pem` |

> Para copiar a chave: `cat calculadora-key.pem` e cole todo o conteúdo, incluindo as linhas `-----BEGIN ...-----` e `-----END ...-----`.

---

## Passo 10 — O fluxo de trabalho

Crie `.github/workflows/ci-cd.yml`. São **dois trabalhos**: `build-and-test` sempre roda; `deploy` só roda se o primeiro passar **e** se o evento for um `push` no `main`.

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Calculadora

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  # ---------- Job 1: construir a imagem e testar ----------
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do código
        uses: actions/checkout@v4

      - name: Validar a construção da imagem Docker
        run: docker build -t calculadora-python:ci .

      - name: Testar as operações aritméticas
        run: docker run --rm calculadora-python:ci pytest tests/ -v

  # ---------- Job 2: implantar na EC2 ----------
  deploy:
    needs: build-and-test          # só roda se o job anterior passar
    if: github.ref == 'refs/heads/main'   # e apenas em push no main
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do código
        uses: actions/checkout@v4

      - name: Configurar a chave SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.EC2_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H "${{ secrets.EC2_HOST }}" >> ~/.ssh/known_hosts

      - name: Copiar o código para a EC2
        run: |
          rsync -avz --delete --exclude='.git' \
            -e "ssh -i ~/.ssh/id_rsa" \
            ./ "${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }}:~/calculadora-python/"

      - name: Construir a imagem e recarregar a aplicação
        run: |
          ssh -i ~/.ssh/id_rsa "${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }}" \
            "cd ~/calculadora-python && docker compose up -d --build"
```

### Entendendo o fluxo

- **`on: push`/`pull_request` no `main`** — o *pipeline* roda a cada envio ou *pull request* contra o `main`.
- **Job `build-and-test`:**
  - `docker build` garante que o `Dockerfile` está correto e a imagem é construída.
  - `docker run ... pytest` executa os testes **dentro da própria imagem recém-construída**, validando as operações aritméticas no mesmo ambiente que irá para produção.
- **Job `deploy`:**
  - **`needs: build-and-test`** cria a dependência: só implanta se os testes passarem.
  - **`if: github.ref == 'refs/heads/main'`** evita implantar a partir de *pull requests*.
  - A chave SSH vem dos *Secrets*, nunca do código.
  - O `rsync` copia a versão mais recente do código para a EC2.
  - `docker compose up -d --build` **reconstrói a imagem na EC2** e recria o contêiner com a nova versão.

---

## Passo 11 — Primeira implantação

Com todos os arquivos criados e os *secrets* configurados, faça o primeiro envio:

```bash
git add .
git commit -m "Calculadora com pipeline CI/CD"
git push origin main
```

Na aba **Actions** do repositório, acompanhe os dois *jobs* até concluírem com sucesso (✓). Em seguida, acesse no navegador:

```
http://<IP_PUBLICO_DA_EC2>
```

A calculadora deve estar no ar.

---

## Passo 12 — Demonstrando a Entrega Contínua

Aqui está o ponto central. Faça uma **pequena alteração visível** — por exemplo, mude o título em `templates/index.html`:

```html
<h1>Calculadora DevOps — v2 🚀</h1>
```

Envie a mudança:

```bash
git add templates/index.html
git commit -m "Atualiza título da calculadora"
git push origin main
```

Observe na aba **Actions**: o *workflow* dispara automaticamente, testa e reimplanta. Ao recarregar `http://<IP_PUBLICO_DA_EC2>`, o novo título aparece — **sem nenhum acesso manual ao servidor**. Esse é o resultado da Entrega Contínua.

---

## Considerações de segurança

- A regra de SSH (porta 22) liberada para `0.0.0.0/0` é necessária porque os *runners* do GitHub têm IPs dinâmicos. Em produção, restrinja por faixas de IP ou use um *runner self-hosted* dentro da rede.
- A imagem final inclui o `pytest` (está no `requirements.txt`). Em um cenário de produção, separe as dependências de teste em outro arquivo ou use *build* multiestágio para manter a imagem enxuta.

## Conclusão

- Construímos um *pipeline* CI/CD completo: do `push` até a aplicação atualizada em produção.
- A separação entre lógica (`calculadora.py`) e *web* (`app.py`) tornou os testes simples e rápidos.
- O *job* de testes roda na **mesma imagem** que vai para produção, aumentando a confiança.
- O *deploy* por SSH + Docker Compose demonstra, de ponta a ponta, o ciclo de Integração e Entrega Contínua que estudamos no módulo.
