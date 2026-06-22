# Trabalho Prático — CI/CD com GitHub Actions, Docker e AWS — 2,5 pontos na Terceira Nota

**Data de entrega:** 01/07/2026

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando um *pipeline* de **Entrega Contínua** completo: uma aplicação *web* de **lista de tarefas** (*to-do list*), conteinerizada com Docker, é automaticamente reimplantada em uma infraestrutura AWS sempre que uma alteração é enviada ao *branch* `main` do repositório no GitHub.

Este trabalho é um **fechamento** do semestre: ele exige o domínio dos assuntos dos trabalhos anteriores — Infraestrutura como Código (Parte 01), Git e GitHub (Parte 02), Docker e Docker Compose (Parte 03) — e adiciona a camada de CI/CD com GitHub Actions.

A escolha da aplicação é **livre**: a equipe deve partir de um exemplo de lista de tarefas disponível na Internet (em qualquer linguagem de programação) e adaptá-lo para execução via `docker-compose.yml`, usando o banco de dados RDS para persistência.

---

## Infraestrutura alvo

A infraestrutura **já deve estar implantada** (reaproveite o resultado dos trabalhos anteriores). O vídeo **não** precisa demonstrar o provisionamento dela.

```
   ┌──────────────┐   git push main    ┌─────────────────────────┐
   │   Estação    │ ─────────────────▶ │     GitHub (repo)       │
   │ do aluno     │                    │  .github/workflows/     │
   └──────────────┘                    └───────────┬─────────────┘
                                                    │ evento: push
                                                    ▼
                                       ┌─────────────────────────┐
                                       │  GitHub Actions runner  │
                                       │   (ubuntu-latest)       │
                                       └───────────┬─────────────┘
                                                   │ SSH (chave em Secrets)
                                                   ▼
   ┌───────────────────────────────────────────────────────────────┐
   │                       AWS (us-east-1)                          │
   │                                                               │
   │   ┌──────────────────────────┐        ┌───────────────────┐  │
   │   │        EC2 (t2.micro)    │        │  RDS PostgreSQL   │  │
   │   │  docker compose up -d    │ :5432  │  db.t3.micro      │  │
   │   │   ┌──────────────────┐   │ ─────▶ │                   │  │
   │   │   │  app to-do :80   │   │        └───────────────────┘  │
   │   │   └──────────────────┘   │                               │
   │   └────────────┬─────────────┘                               │
   └────────────────┼─────────────────────────────────────────────┘
                    │ HTTP (porta 80)
                 Internet
```

- **Uma instância EC2** que hospeda a aplicação conteinerizada via Docker Compose.
- **Um banco de dados RDS PostgreSQL** já provisionado, usado para a persistência das tarefas.
- A imagem da aplicação é **construída na própria EC2** e recarregada pelo Docker Compose a cada implantação.

---

## Funcionamento do *pipeline*

1. O aluno faz uma alteração no código e executa `git push` no *branch* `main`.
2. O evento `push` dispara o *workflow* do GitHub Actions.
3. O *runner* do GitHub conecta-se à instância EC2 via **SSH** (chave privada guardada em *GitHub Secrets*).
4. Na EC2, o *workflow* atualiza o código, **constrói uma nova imagem** e recarrega os contêineres com `docker compose up -d`.
5. A nova versão fica imediatamente acessível via HTTP no IP público da EC2.

---

## O que deve aparecer no vídeo

### 1. A aplicação e sua conteinerização (apresentação rápida)

Mostre brevemente:

- A aplicação de lista de tarefas escolhida e adaptada (cite a fonte do exemplo usado).
- O **`Dockerfile`** da aplicação.
- O **`docker-compose.yml`**, destacando:
  - O serviço da aplicação e a porta `80` publicada.
  - As variáveis de ambiente de conexão com o **RDS** (*host*/endpoint, usuário, senha, base) — que **não** devem estar versionadas em texto puro no repositório.

> A senha do banco e o *endpoint* do RDS devem vir de um arquivo `.env` na EC2 (fora do controle de versão) ou de *secrets*, nunca diretamente no `docker-compose.yml` enviado ao GitHub.

### 2. O fluxo de trabalho do GitHub Actions (explicação detalhada)

Esta é a parte central do trabalho. Mostre o arquivo em `.github/workflows/` e **explique em detalhes** cada parte. Exemplo de referência:

```yaml
# .github/workflows/deploy.yml
name: Deploy da Aplicação To-Do

# Gatilho: qualquer push no branch main
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # Passo 1: recupera o código (opcional, útil para validações antes do deploy)
      - name: Checkout do código
        uses: actions/checkout@v4

      # Passo 2: conecta na EC2 por SSH e reimplanta a aplicação
      - name: Implantar na EC2
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.EC2_HOST }}        # IP público / DNS da EC2
          username: ${{ secrets.EC2_USER }}    # ex.: ubuntu
          key: ${{ secrets.EC2_SSH_KEY }}      # chave privada SSH
          script: |
            cd ~/todo-app
            git pull origin main          # traz o código mais recente
            docker compose build          # constrói a nova imagem NA EC2
            docker compose up -d          # recarrega os contêineres
            docker image prune -f         # remove imagens antigas órfãs
```

Pontos que a explicação deve cobrir:

- **`on: push: branches: [ main ]`** — por que o gatilho restringe ao `main`.
- **`secrets`** — como os dados sensíveis (IP, usuário, chave SSH) ficam protegidos em *Settings → Secrets and variables → Actions*, e por que não podem estar no código.
- **Por que a imagem é construída na EC2** e como o `docker compose up -d` recarrega apenas o que mudou.
- O papel do `actions/checkout` e da *action* de SSH utilizada.

### 3. Demonstração da Entrega Contínua

1. Faça uma **pequena alteração** visível na aplicação — por exemplo, alterar um título ou cabeçalho HTML.
2. Faça `git add`, `git commit` e `git push` no `main`.
3. Na aba **Actions** do GitHub, acompanhe a execução do *workflow* até a conclusão com sucesso (✓).
4. Acesse a aplicação via HTTP (`http://<ip_publico_ec2>`) e mostre que a alteração **já está refletida** na aplicação em execução, sem nenhuma intervenção manual no servidor.

---

## Critérios de avaliação

| Critério | Peso |
|---|---|
| Apresentação do `Dockerfile` e do `docker-compose.yml` da aplicação | 15% |
| Tratamento adequado de dados sensíveis (RDS/SSH fora do repositório) | 10% |
| Explicação detalhada e correta do *workflow* do GitHub Actions | 30% |
| *Workflow* executa com sucesso a partir do evento `push` no `main` | 20% |
| Aplicação acessível via HTTP usando o banco RDS | 10% |
| Alteração feita, *deploy* automático e reflexo demonstrado na aplicação | 15% |

---

## Referências

- Trabalhos anteriores: `TRABALHO_PARTE_01.md` (IaC — EC2 e RDS), `TRABALHO_PARTE_02.md` (Git/GitHub), `TRABALHO_PARTE_03.md` (Docker Compose).
- Slides do módulo GitHub Actions: `github_actions/01_entendendo_github_actions.md`, `github_actions/02_fluxos_de_trabalho.md`, `github_actions/03_exemplo.md`, `github_actions/04_eventos.md`.
- Slides do módulo Docker: `docker/03_composicao_de_conteineres.md`.
- Código de referência da infraestrutura: pasta `iac/`.
- *Action* de SSH — [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
- Documentação oficial — [Encrypted secrets no GitHub Actions](https://docs.github.com/actions/security-guides/encrypted-secrets)
- Modelos de *workflow* — [actions/starter-workflows](https://github.com/actions/starter-workflows)
