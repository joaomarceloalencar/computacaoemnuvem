# Eventos

## Introdução

- Já vimos a execução de um fluxo de trabalho a partir de um *commit* feito em um *branch*.
- Os gatilhos de fluxo de trabalho são definidos na linguagem do GitHub Actions usando a chave `on`.
- Podemos configurar vários eventos para disparar *workflows*.
- Filtros permitem configurar os eventos com detalhes específicos.

## Acionadores de Fluxos de Trabalho

- Os eventos acionadores de fluxos de trabalho podem ser:
  - Eventos que ocorrem no repositório.
  - Eventos externos ao GitHub, mas que disparam um evento `repository_dispatch`.
  - Horários agendados.
  - Disparo manual.
- Na demonstração, configuramos a execução para ocorrer quando um *push* é feito usando `on: [push]`.

Como funciona internamente:

- Um evento ocorre no seu repositório. Esse evento tem um *hash* SHA de *commit* associado a uma referência de Git.
- O GitHub pesquisa no diretório `.github/workflows` os arquivos de *workflows* presentes no SHA do *commit* associado.
- A execução é disparada para todos os fluxos que têm valores `on:` correspondentes ao evento do gatilho. Ou seja, mais de um fluxo pode ser disparado.
- Quando um fluxo é executado, as variáveis `GITHUB_SHA` e `GITHUB_REF` são definidas no ambiente do executor.

## Usando Eventos

- **Evento único:**

  ```yaml
  on: push
  ```

- **Eventos múltiplos:**

  ```yaml
  on: [push, fork]
  ```

  - Apenas um dos eventos precisa ocorrer para disparar o fluxo.
  - Se vários eventos ocorrerem ao mesmo tempo, várias execuções do fluxo são acionadas.

- **Usando tipos e filtros:**

  ```yaml
  on:
    label:          # evento em que uma etiqueta é criada
      types:
        - created
    push:           # evento em que um push é feito no main
      branches:
        - main
  ```

### Filtrando por *branch*

```yaml
on:
  pull_request:     # executa em pull requests no branch main, mona/octocat
    branches:       # e qualquer branch que comece com releases
      - main
      - 'mona/octocat'
      - 'releases/**'
```

```yaml
on:
  pull_request:           # executa em qualquer pull request exceto nos branches
    branches-ignore:      # mona/octocat ou que comecem com releases
      - 'mona/octocat'
      - 'releases/**'
```

### Filtrando por caminho de arquivo

```yaml
on:
  push:             # executa sempre que houver um push em um arquivo JavaScript
    paths:
      - '**.js'
```

```yaml
on:
  push:             # alterações na pasta de documentação não disparam workflows
    paths-ignore:
      - 'docs/**'
```

## Condições

É possível restringir a execução de um *job* com a chave `if`. Útil, por exemplo, para **evitar a execução em forks**:

```yaml
name: example-workflow
on: [push]
jobs:
  production-deploy:
    if: github.repository == 'octo-org/octo-repo-prod'  # só executa se o repositório for exatamente o informado
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '14'
      - run: npm install -g bats
```

Também podemos criar **dependências entre jobs** com a chave `needs`:

```yaml
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: build
        run: |
          echo 'building'
  publish:
    needs: [build]      # só executa se o job build terminar com sucesso
    runs-on: ubuntu-latest
    steps:
      - name: publish
        run: |
          echo 'publishing'
```

## Exemplos de Eventos

- **`create`:**
  - Executa o fluxo quando alguém cria um *branch* ou *tag* no repositório.
  - O evento `delete` é equivalente na remoção de um *branch* ou *tag*.
- **`deployment`:**
  - Executa o fluxo quando alguém cria uma implantação no repositório do fluxo de trabalho.
- **`fork`:**
  - Executa o fluxo quando alguém bifurca (*fork*) um repositório.
- **`issues`:**
  - Executa o fluxo quando um problema no repositório é criado ou modificado.
  - Aceita atividades como `opened`, `edited`, `closed`, etc.
- **`pull_request`:**
  - Executa o fluxo quando ocorre uma atividade em uma *pull request* no repositório.
  - Aceita atividades como `assigned`, `opened`, `locked`, etc.
- **`push`:**
  - Executa o fluxo quando você efetua *push* em um *commit* ou *tag*.
- **`repository_dispatch`:**
  - Executa quando é disparada uma invocação à API do GitHub Actions.
- **`schedule`:**
  - Execução agendada.

## Conclusão

- Eventos controlam o ciclo de vida dos *workflows*.
- Podemos especificar tipos, filtros e condições para que o evento dispare um fluxo de trabalho.
- Também podemos criar dependências entre os trabalhos em um fluxo.
- Existem mais de 20 tipos de eventos disponíveis, mas nem todos são utilizados com frequência.
