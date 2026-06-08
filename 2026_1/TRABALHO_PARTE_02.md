# Trabalho Prático — Controle de Versão com Git e GitHub — 2,5 pontos na Terceira Nota

**Data de entrega:** 17/06/2026

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando o uso do Git em linha de comando Linux para simular uma situação real de conflito entre dois desenvolvedores trabalhando no mesmo repositório.

---

## Cenário

Dois usuários (`usuario1` e `usuario2`) compartilham um repositório no GitHub. Ambos fazem `pull`, alteram o mesmo trecho de um mesmo arquivo e tentam submeter via `push`. O `usuario2` recebe uma mensagem de conflito e precisa resolvê-lo antes de submeter a versão final.

Toda a atividade é feita em **linha de comando Linux**. Não é permitido o uso de IDEs como Visual Studio Code. O editor de texto deve ser **nano** ou **vim**.

---

## Pré-requisitos

- Um repositório criado no GitHub (pode ter sido criado anteriormente).
- `usuario1` é o dono do repositório.
- `usuario2` é um colaborador adicionado em *Settings → Collaborators*.
- Ambos os usuários têm acesso via **SSH com chave pública/privada** configurada.

---

## O que deve aparecer no vídeo

### 1. Acesso via SSH (pelo menos um dos usuários)

Demonstre que o acesso ao repositório é feito por chave SSH, não por senha. Mostre o clone ou o push usando a URL no formato `git@github.com:...`:

```bash
# Verificar configuração da chave
$ cat ~/.ssh/config

# Clonar usando SSH
$ git clone git@github.com:<usuario>/devops.git
```

### 2. `usuario1` faz pull e altera o arquivo

```bash
$ git pull
$ nano README.md        # adiciona uma linha no final do arquivo
$ git add README.md
$ git commit -m "usuario1: atualiza README"
$ git push
```

### 3. `usuario2` faz pull (antes do push do usuario1) e altera o mesmo arquivo

Neste momento, `usuario2` já havia feito o `pull` antes do `push` do `usuario1`, portanto seu repositório local está desatualizado:

```bash
$ git pull              # feito antes do push do usuario1
$ nano README.md        # altera a mesma linha que usuario1 alterou
$ git add README.md
$ git commit -m "usuario2: atualiza README"
$ git push              # CONFLITO: repositório remoto avançou
```

A mensagem de erro do Git deve aparecer no vídeo, indicando que o repositório remoto contém trabalho que o local não possui.

### 4. `usuario2` resolve o conflito

```bash
$ git fetch origin
$ git merge origin/main     # ou git pull
```

O Git abre o arquivo com os marcadores de conflito:

```
<<<<<<< HEAD
Linha alterada pelo usuario2
=======
Linha alterada pelo usuario1
>>>>>>> origin/main
```

`usuario2` edita o arquivo, remove os marcadores e mantém a versão final acordada:

```bash
$ nano README.md            # remove marcadores, deixa a versão final
$ git add README.md
$ git commit -m "usuario2: resolve conflito com usuario1"
$ git push
```

### 5. Verificação final

Mostre que o repositório remoto contém o histórico de commits dos dois usuários e a resolução do conflito:

```bash
$ git log --oneline --graph
```

---

## Critérios de avaliação

| Critério | Peso |
|---|---|
| Acesso via SSH com chave demonstrado | 20% |
| `usuario1` faz pull, altera, commit e push com sucesso | 20% |
| `usuario2` tenta push e recebe mensagem de conflito | 25% |
| `usuario2` resolve o conflito e faz push com sucesso | 25% |
| Histórico de commits exibido com `git log` ao final | 10% |

---

## Referências

- Slides: `git/01_controle_de_versao.md`, `git/02_github.md`, `git/03_ferramenta_git.md`, `git/05_integracao_git.md`.
- Seção "Exemplo: Dois Desenvolvedores em Paralelo" em `git/05_integracao_git.md`.
