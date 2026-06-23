# Trabalho Prático — CI/CD com GitHub Actions, Docker e AWS — 2,5 pontos na Terceira Nota

**Data de entrega:** 01/07/2026

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando um *pipeline* de **Entrega Contínua** completo: uma aplicação *web* de **lista de tarefas** (*to-do list*), conteinerizada com Docker, é automaticamente reimplantada em uma infraestrutura AWS sempre que uma alteração é enviada ao *branch* `main` do repositório no GitHub.

Este trabalho é um **fechamento** do semestre: ele exige o domínio dos assuntos dos trabalhos anteriores — Infraestrutura como Código (Parte 01), Git e GitHub (Parte 02), Docker e Docker Compose (Parte 03) — e adiciona a camada de CI/CD com GitHub Actions.

A escolha da aplicação é **livre**: a equipe deve partir de um exemplo de lista de tarefas disponível na Internet (em qualquer linguagem de programação) e adaptá-lo para execução via `docker-compose.yml`, usando o banco de dados RDS para persistência.

Este trabalho reaproveita o *pipeline* construído na aula `github_actions/05_exemplo_calculadora.md` (dois *jobs*: `build-and-test` e `deploy` via `rsync`/SSH). A **novidade** em relação àquela aula é trocar a aplicação trivial e sem estado por uma aplicação **com persistência em banco de dados real (RDS)** e tratar os segredos de conexão com o banco.

---

## Infraestrutura alvo

A infraestrutura **já deve estar implantada** (reaproveite o resultado dos trabalhos anteriores). O vídeo **não** precisa demonstrar o provisionamento dela.

```
  ┌────────────┐   git push main   ┌──────────────────────────────┐
  │  Estação   │ ────────────────▶ │   GitHub (repo)              │
  │  do aluno  │                   │   .github/workflows/         │
  └────────────┘                   └───────────────┬──────────────┘
                                                   │ evento: push
                                                   ▼
                              ┌──────────────────────────────────┐
                              │  Job 1: build-and-test           │
                              │   • docker build (valida imagem) │
                              │   • testes da aplicação          │
                              └───────────────┬──────────────────┘
                                              │ sucesso
                                              ▼
                              ┌──────────────────────────────────┐
                              │  Job 2: deploy (rsync + SSH)     │
                              │   • copia código → EC2           │
                              │   • docker compose up -d --build │
                              └───────────────┬──────────────────┘
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
3. **Job `build-and-test`:** o *runner* constrói a imagem Docker (validando o `Dockerfile`) e executa os testes da aplicação. Só prossegue se tudo passar.
4. **Job `deploy`:** o *runner* copia o código mais recente para a EC2 via `rsync`/SSH (chave privada guardada em *GitHub Secrets*) e, na EC2, **constrói a nova imagem** e recarrega os contêineres com `docker compose up -d --build`.
5. A nova versão fica imediatamente acessível via HTTP no IP público da EC2, persistindo os dados no RDS.

---

## O que deve aparecer no vídeo

### 1. A aplicação e sua conteinerização (apresentação rápida)

Mostre brevemente:

- A aplicação de lista de tarefas escolhida e adaptada (cite a fonte do exemplo usado).
- O **`Dockerfile`** da aplicação.
- O **`docker-compose.yml`**, destacando:
  - O serviço da aplicação e a porta `80` publicada.
  - As variáveis de ambiente de conexão com o **RDS** (*host*/endpoint, usuário, senha, base) — que **não** devem estar versionadas em texto puro no repositório.

> A senha do banco e o *endpoint* do RDS devem vir de um arquivo `.env` que vive **na EC2** (fora do controle de versão), nunca diretamente no `docker-compose.yml` enviado ao GitHub. Por isso o `rsync` do *deploy* exclui o `.env`: o arquivo de segredos da instância é preservado a cada implantação.

### 2. O fluxo de trabalho do GitHub Actions (explicação detalhada)

Esta é a parte central do trabalho. Reaproveite o padrão de **dois *jobs*** da aula `05_exemplo_calculadora.md` e adapte-o à sua aplicação. Mostre o arquivo em `.github/workflows/` e **explique em detalhes** cada parte. Exemplo de referência:

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD To-Do

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
        run: docker build -t todo-app:ci .

      - name: Executar os testes da aplicação
        run: docker run --rm todo-app:ci <comando de teste da sua linguagem>

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
          rsync -avz --delete --exclude='.git' --exclude='.env' \
            -e "ssh -i ~/.ssh/id_rsa" \
            ./ "${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }}:~/todo-app/"

      - name: Construir a imagem e recarregar a aplicação
        run: |
          ssh -i ~/.ssh/id_rsa "${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }}" \
            "cd ~/todo-app && docker compose up -d --build"
```

Pontos que a explicação deve cobrir:

- **`on: push`/`pull_request` no `main`** — por que o gatilho restringe ao `main`.
- **Job `build-and-test`** — como o `docker build` valida o `Dockerfile` e como os testes da aplicação rodam **dentro da imagem recém-construída**.
- **`needs: build-and-test` e `if: github.ref == ...`** — por que só implantamos quando os testes passam e apenas em `push` no `main` (e não em *pull request*).
- **`secrets`** — como os dados sensíveis (IP, usuário, chave SSH, segredos do banco) ficam protegidos em *Settings → Secrets and variables → Actions*, e por que não podem estar no código.
- **Por que a imagem é construída na EC2** com `docker compose up -d --build`, e por que o `rsync` exclui o `.env` (para **não sobrescrever** o arquivo de segredos do RDS que vive na instância).

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
| Explicação detalhada e correta do *workflow* (dois *jobs*) do GitHub Actions | 25% |
| Job `build-and-test` constrói a imagem e executa os testes com sucesso | 15% |
| Job `deploy` executa com sucesso a partir do evento `push` no `main` | 15% |
| Aplicação acessível via HTTP usando o banco RDS | 10% |
| Alteração feita, *deploy* automático e reflexo demonstrado na aplicação | 10% |

---

## Referências

- **Base direta deste trabalho:** `github_actions/05_exemplo_calculadora.md` — *pipeline* de dois *jobs* (`build-and-test` + `deploy` via `rsync`/SSH). Reaproveite o padrão e adapte para uma aplicação com banco de dados.
- Trabalhos anteriores: `TRABALHO_PARTE_01.md` (IaC — EC2 e RDS), `TRABALHO_PARTE_02.md` (Git/GitHub), `TRABALHO_PARTE_03.md` (Docker Compose).
- Slides do módulo GitHub Actions: `github_actions/01_entendendo_github_actions.md`, `github_actions/02_fluxos_de_trabalho.md`, `github_actions/03_exemplo.md`, `github_actions/04_eventos.md`.
- Slides do módulo Docker: `docker/03_composicao_de_conteineres.md`.
- Código de referência da infraestrutura: pasta `iac/`.
- Documentação oficial — [Encrypted secrets no GitHub Actions](https://docs.github.com/actions/security-guides/encrypted-secrets)
- Modelos de *workflow* — [actions/starter-workflows](https://github.com/actions/starter-workflows)
