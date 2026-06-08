# Utilizando o GitHub

## GitHub

- Ambiente de hospedagem de código:
  - Suporte ao protocolo Git.
  - Auxilia no planejamento e rastreamento da evolução de projetos de *software*.
- Incentiva a colaboração *open source*:
  - Permite replicar repositórios existentes (*forking*).
  - Após alterações, o desenvolvedor pode submeter suas melhorias ao repositório original (*pull request*).
  - O mantenedor original revisa alterações, permitindo integrá-las no projeto (*merge*).
- Toda a interação de colaboração ocorre no GitHub, sem a necessidade de outras formas de comunicação (e-mail, *chat*, etc).

## Conta no GitHub

- Mesmo sem participar de projetos *open source*, você pode criar uma conta pessoal:
  - Seus repositórios podem ser privados.
  - Entretanto, manter repositórios públicos é uma boa maneira de divulgar suas habilidades a possíveis recrutadores e outros desenvolvedores.
- Há mais de 36 milhões de desenvolvedores cadastrados no GitHub.
- A versão empresarial do GitHub oferece mais opções de segurança e suporte *online*.

### Criando uma Conta

1. Acesse https://github.com.
2. No canto superior direito, escolha *Sign Up*.
3. Irá surgir um formulário dinâmico:
   1. Forneça seu e-mail.
   2. Forneça uma senha.
   3. Forneça um nome de usuário.
   4. Opte por receber ou não e-mails do GitHub.
4. Em seguida, haverá uma série de *captchas* para verificar se é um usuário de fato criando a conta, não um *bot*.
5. Informe o código enviado por e-mail.
6. Selecione a opção *Student* e afirme que só você usará a conta (*Just me*).
7. Escolha que irá usar a conta como *Automation and CI/CD*.
8. Escolha *Continue for Free*. Depois é possível cadastrar para os benefícios de estudante.

## Criação de Repositório

- Na página inicial, clique em *Create repository* no lado esquerdo da tela, ou clique no símbolo `+` no canto superior direito e selecione *New repository*.
- No formulário de criação:
  - Informe o nome do repositório (ex: `devops`).
  - Escolha se será **Public** ou **Private**.
  - Marque *Add a README file*.
  - Escolha uma licença (ex: Apache License 2.0).
  - Clique em *Create repository*.
- O repositório será criado e você verá a interface *web*, através da qual pode realizar a maioria das operações de inserção de código, criação de *branchs*, etc.
- Para integrar em *pipelines* CI/CD, é importante configurar o acesso através da linha de comando no Linux.
- O GitHub usa o protocolo SSH para comunicação segura:
  - Apesar do SSH suportar *login* por senha, não é uma solução passível de automação.
  - A opção correta é configurar a autenticação por arquivos de chave pública e privada.

## Criação de Chaves SSH

Na linha de comando Linux, instalar os pacotes caso já não estejam presentes:

```bash
$ sudo apt install git openssh-client
```

Entrar no diretório de configuração do SSH do usuário:

```bash
$ cd ~/.ssh
```

Gerar as chaves pública e privada:

```bash
$ ssh-keygen -N "" -f devops
```

São criados os arquivos *devops* (privada) e *devops.pub* (pública).

### Registrando a Chave no GitHub

1. Acesse https://github.com, clique no ícone do usuário no canto superior direito e selecione *Settings*.
2. Na opções ao lado esquerdo, procure por *SSH and GPG Keys*.
3. Clique em *New SSH key*.
4. Informe `devops` como *Title*, deixe *Key type* como *Authentication Key*, e coloque o conteúdo de *devops.pub* no campo *Key*.
5. Por último, clique em *ADD SSH key*.

## Configurando Acesso por CLI

De volta ao Linux, coloque o seguinte conteúdo no arquivo `~/.ssh/config`:

```
Host github.com
  HostName github.com
  IdentityFile ~/.ssh/devops
  User git
```

Clone o repositório:

```bash
$ cd ~
$ git clone git@github.com:<nome do usuário>/devops.git
```

Dentro do repositório, configure o usuário e e-mail:

```bash
$ cd devops
$ git config user.name <nome de usuário>
$ git config user.email <e-mail>
```

Faça uma atualização no *README.md* para confirmar se está tudo certo:

```bash
$ echo -e "\n## Meu primeiro commit." >> README.md
$ git add README.md
$ git commit -m "Minha primeira submissão."
$ git push
```

## Conclusão

- Configuramos um repositório no GitHub, é o ponto de partida para o controle de versão de código fonte.
- Criamos uma chave e fizemos o registro. O acesso agora é autenticado e a comunicação ocorre através de um canal criptografado.
- Podemos criar várias chaves, sendo que caso uma delas seja comprometida, é possível desativá-la no GitHub.
- A autenticação via chaves pode ser usada por outras ferramentas do *pipeline*, como o Ansible.
