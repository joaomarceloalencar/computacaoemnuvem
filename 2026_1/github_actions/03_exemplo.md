# Exemplo

## Introdução

- Terminamos este módulo com um exemplo inicial.
- Este exemplo irá nos preparar para avançar ainda mais nos conceitos no próximo módulo.
- Vamos começar com um repositório vazio para não termos distrações com código existente.
- No próximo módulo, vamos abordar a aplicação que já trabalhamos em módulos anteriores, além da integração com a nuvem.

## Fluxo de Trabalho

O *workflow* que vamos construir executa as seguintes etapas:

1. Recupera o código do repositório.
2. Configura o ambiente Python.
3. Instala as dependências.
4. Executa os testes.

## Organização do Repositório

```
meu-primeiro-workflow/
├── .github/
│   └── workflows/
│       └── ci.yml          # Arquivo do GitHub Actions
├── tests/
│   └── test_app.py         # Arquivo de testes
├── app.py                  # Arquivo principal da aplicação Flask
└── requirements.txt        # Arquivo de dependências
```

> Crie um repositório no GitHub e clone-o. Crie essa estrutura no diretório, mas **não submeta de imediato!**

## Aplicação Simples

Arquivo `app.py`:

```python
from flask import Flask

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Olá, Mundo DevOps com Flask e GitHub Actions!'


if __name__ == '__main__':
    app.run(debug=True)
```

## Dependências da Aplicação

Arquivo `requirements.txt`:

```
Flask>=2.0
# Para testes
pytest>=7.0
flake8>=5.0
```

- **Flask** é o *framework web*.
- **pytest** é o pacote de testes.
- **flake8** permite um tipo especial de teste:
  - Analisa o código.
  - Fornece dicas de formatação.

## Testes

Arquivo `tests/test_app.py`:

```python
import pytest
from app import app as flask_app


@pytest.fixture
def app():
    yield flask_app


@pytest.fixture
def client(app):
    return app.test_client()


def test_hello_world(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Ol\xc3\xa1, Mundo DevOps' in response.data
```

## Definição do Fluxo de Trabalho

Arquivo `.github/workflows/ci.yml`:

```yaml
# Nome do Workflow que aparecerá na aba Actions do GitHub
name: CI Python Flask

# Gatilhos: quando este workflow deve ser executado
on:
  push:                 # Executa em pushes
    branches: [ main ]  # Pode restringir a branches específicas, como 'main'
  pull_request:         # Executa em pull requests
    branches: [ main ]

# Trabalhos (Jobs)
jobs:
  build-and-test:
    runs-on: ubuntu-latest   # Usaremos a versão mais recente do Ubuntu Linux

    # Passos (Steps)
    steps:
      # Passo 1: Checkout do código do repositório
      # Usa uma Action pré-feita pela comunidade (actions/checkout)
      - name: Checkout repository code
        uses: actions/checkout@v4

      # Passo 2: Configurar o ambiente Python
      # Usa outra Action pré-feita (actions/setup-python)
      - name: Set up Python environment
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      # Passo 3: Instalar dependências
      # Executa comandos shell diretamente
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      # Passo 4: Lint com flake8 (verificação de estilo)
      - name: Lint with flake8
        run: |
          # --count: mostra o número total de erros
          # --show-source: mostra a linha do código com erro
          # --statistics: mostra contagem de erros/avisos
          flake8 . --count --show-source --statistics
          # Para falhar o workflow se houver erros de lint, não é preciso flag extra.

      # Passo 5: Executar testes com pytest
      - name: Run tests with pytest
        run: |
          export PYTHONPATH=.   # Adiciona o diretório raiz ao PYTHONPATH
          pytest tests/         # Executa os testes na pasta 'tests'
```

## Conclusão

- Basta colocar o código no repositório para verificar a execução do fluxo de trabalho.
- Use um editor de textos como o Visual Studio Code para formatação adequada, pois arquivos `.yml` retornam erro se a quantidade de espaços correta não for observada.
- O *flake8* irá acusar vários erros de estilo. Você pode corrigi-los ou remover a etapa 4.
- Veja que, como Python é interpretada, não há etapa de construção ou compilação.
