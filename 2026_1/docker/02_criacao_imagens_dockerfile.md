# Criação de Imagens e Dockerfile

## Motivação

- Se já existem imagens prontas, por que criar nossas próprias imagens?
  - Transformar nossas próprias aplicações em contêineres.
  - Customizar serviços de imagens existentes para nossas necessidades.
- Em teoria, poderíamos personalizar nossas imagens manualmente, executando comando por comando.
- O problema é que se uma nova imagem base é lançada, você queria que baixá-la e executar a sequência de comandos novamente.
- Para evitar o retrabalho, usaremos arquivos *Dockerfile*.

## Como Criar uma Imagem

- Usamos um arquivo chamado *Dockerfile*.
- Ele define o **contexto de construção**.
- Uma analogia é que o *Dockerfile* é o código fonte da imagem; o Docker "compila" ou "constrói" o arquivo para uma imagem.
- Começamos criando um diretório e colocando apenas o arquivo *Dockerfile* dentro:

```bash
ubuntu@devops:~$ mkdir meu-primeiro-conteiner
ubuntu@devops:~$ cd meu-primeiro-conteiner
ubuntu@devops:~/meu-primeiro-conteiner$ touch Dockerfile
```

Conteúdo do Dockerfile:

```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y iputils-ping
```

Para construir, dentro do diretório:

```bash
ubuntu@devops:~/meu-primeiro-conteiner$ docker build -t meu-primeiro-conteiner:v1 .
```

Saída esperada do `docker build`:

```
[+] Building 65.9s (6/6) FINISHED                                       docker:default
 => [internal] load build definition from Dockerfile                              0.0s
 => => transferring dockerfile: 108B                                              0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                  0.0s
 => [internal] load .dockerignore                                                 0.0s
 => => transferring context: 2B                                                   0.0s
 => [1/2] FROM docker.io/library/ubuntu:latest                                    0.0s
 => [2/2] RUN apt-get update && apt install iputils-ping -y                      65.7s
 => exporting to image                                                            0.1s
 => => exporting layers                                                           0.1s
 => => writing image sha256:f8dd137fd9cda60c76231d6c8dd4497d03fd63679ef912ad498…  0.0s
 => => naming to docker.io/library/meu-primeiro-conteiner:v1                      0.0s
```

Listando as imagens e executando o contêiner:

```bash
$ docker image ls
REPOSITORY               TAG    IMAGE ID       CREATED          SIZE
meu-primeiro-conteiner   v1     f8dd137fd9cd   19 minutes ago   141MB
ubuntu                   latest ffb64c9b7e8b   7 weeks ago      101MB

$ docker run -it meu-primeiro-conteiner:v1
root@0acd261c402e:/
```

## Camadas

```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y iputils-ping
```

Cada instrução do *Dockerfile* gera uma **camada** na imagem. O comando `docker history` mostra essas camadas:

```bash
$ docker history meu-primeiro-conteiner:v1
IMAGE          CREATED         CREATED BY                                      SIZE     COMMENT
f8dd137fd9cd   40 minutes ago  RUN /bin/sh -c apt-get update && apt install…   40MB     buildkit.dockerfile.v0
<missing>      7 weeks ago     /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      7 weeks ago     /bin/sh -c #(nop) ADD file:9018302bda8cbdb55…   101MB
<missing>      7 weeks ago     /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      7 weeks ago     /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      7 weeks ago     /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      7 weeks ago     /bin/sh -c #(nop)  ARG RELEASE                  0B
```

## Comandos do Dockerfile

Exemplo com uma aplicação Python:

```bash
$ cat Dockerfile
```

```dockerfile
FROM python:3.10-alpine

WORKDIR /app

RUN apk update

COPY requirements.txt requirements.txt

COPY app.py app.py

RUN pip install -r requirements.txt

CMD [ "python", "app.py" ]
```

```bash
$ docker build -t meu-segundo-conteiner:v1 .
```

### Principais instruções

- **ENV** permite definir uma variável de ambiente que persiste até a execução do contêiner.
- **ARG** cria variáveis que existem apenas durante a construção.
- **USER** indica o usuário que executará os comandos dentro do contêiner.
- **EXPOSE** permite redirecionar portas.
- **ENTRYPOINT** é similar a CMD, mas não pode ser alterado por parâmetros passados na execução por `docker run`.
- **COPY** copia arquivos para a imagem.
- **WORKDIR** define o diretório de trabalho.

### Executando o segundo contêiner

```bash
ubuntu@devops:~/meu-segundo-conteiner$ docker run meu-segundo-conteiner:v1
172.130.38.94
```

- Neste segundo contêiner, executamos uma aplicação Python.
- Usamos uma imagem base diferente, que já tem o ambiente Python instalado.
- As imagens *alpine* são enxutas, contém apenas o básico.

## Registrando a Imagem no *DockerHub*

- *DockerHub* é um registro público mantido pela *Docker Inc.*
- O uso para aprendizado e pessoal é gratuito.
- Acesse <https://hub.docker.com> e faça uma conta, lembrando de configurar uma senha.
- Vá em <https://hub.docker.com/repositories> e crie um novo repositório; iremos usar *devops*.
- Realize o *login* executando `docker login` no terminal e informando usuário e senha.

### Publicando a imagem

```bash
$ docker tag meu-segundo-conteiner:v1 [usuario]/devops:v1
$ docker push [usuario]/devops:v1
The push refers to repository [docker.io/[usuario]/devops]
a5afd0fa91d8: Pushed
c55879f4082e: Pushed
ebbabd0a2b90: Pushed
a73bff0302ce: Pushed
2900185ab309: Pushed
2296e0c77b89: Pushed
69478fe0d228: Pushed
f71bbb7a03cc: Pushed
21dad4165637: Pushed
9110f7b5208f: Pushed
v1: digest: sha256:2485b12f6ded8e21a8a6abd69dc8a0715b8a59a2869c1ea79cc0092450b200c4 size: 2410
```

Substitua `[usuario]` pelo seu usuário no *DockerHub*.

### Boas práticas com *tags*

- Em outra máquina, o comando `docker pull [usuario]/devops:v1` irá baixar a imagem.
- Da mesma forma você poderá executar com `docker run [usuario]/devops:v1`.
- O ideal é criar um repositório por contêiner que você desenvolver, usando as *tags* para indicar versões ou alternativas.
- Você pode rotular a mesma versão com mais de uma *tag*.
- O termo *latest* é usado para rotular a última versão.

## Conclusão

- Construir imagens é basicamente determinar os comandos necessários para configurar sua aplicação e inseri-los no *Dockerfile*.
- Como cada comando cria uma camada, é boa prática unir comandos do sistema operacional com operadores como `&&`.
- *Dockerfile* podem ser distribuídos e reutilizados.
- O *DockerHub* pode ser usado para compartilhar imagens.
