# Trabalho Prático — Controle de Versão com Git e GitHub — 2,5 pontos na Terceira Nota

**Data de entrega:** 17/06/2026

## Descrição

Produzir um **vídeo de até 5 minutos** demonstrando o uso do Git em linha de comando Linux para simular uma situação real de conflito entre dois desenvolvedores trabalhando no mesmo repositório.

---

## Cenário

Dois usuários (`usuario1` e `usuario2`) compartilham um repositório no GitHub. Ambos fazem pull, alteram o mesmo trecho de um mesmo arquivo e tentam submeter via push. O `usuario2` recebe uma mensagem de conflito e precisa resolvê-lo antes de submeter a versão final.

Toda a atividade é feita em **linha de comando Linux**. Não é permitido o uso de IDEs como Visual Studio Code. O editor de texto deve ser **nano** ou **vim**.

---

## Pré-requisitos

- Um repositório criado no GitHub (pode ter sido criado anteriormente).
- `usuario1` é o dono do repositório.
- `usuario2` é um colaborador adicionado em *Settings → Collaborators*.
- Ambos os usuários têm acesso via **SSH com chave pública/privada** configurada.

---

## O que deve aparecer no vídeo

### 1. Acesso via SSH

Demonstre que o acesso ao repositório é feito por chave SSH, não por senha. É suficiente que um push seja realizado sem solicitação de senha, evidenciando a autenticação por chave.

### 2. `usuario1` atualiza o repositório

`usuario1` faz pull, edita um arquivo, registra as alterações com commit e envia para o repositório remoto com push.

### 3. `usuario2` tenta enviar alterações conflitantes

`usuario2` já havia feito pull antes do push do `usuario1`, portanto seu repositório local está desatualizado. Ele edita a mesma parte do mesmo arquivo, registra com commit e tenta fazer push — a mensagem de conflito do Git deve aparecer no vídeo.

### 4. `usuario2` resolve o conflito

`usuario2` sincroniza com o repositório remoto, abre o arquivo com os marcadores de conflito inseridos pelo Git, edita manualmente para chegar à versão final, e registra a resolução com um novo commit e push.

### 5. Verificação final

Mostre o histórico de commits, evidenciando as contribuições dos dois usuários e o commit de resolução do conflito.

---

## Critérios de avaliação

| Critério | Peso |
|---|---|
| Acesso via SSH com chave demonstrado | 20% |
| `usuario1` faz pull, altera, commit e push com sucesso | 20% |
| `usuario2` tenta push e recebe mensagem de conflito | 25% |
| `usuario2` resolve o conflito e faz push com sucesso | 25% |
| Histórico de commits exibido ao final | 10% |

---

## Referências

- Slides: `git/01_controle_de_versao.md`, `git/02_github.md`, `git/03_ferramenta_git.md`, `git/05_integracao_git.md`.
- Seção "Exemplo: Dois Desenvolvedores em Paralelo" em `git/05_integracao_git.md`.
