# Infraestrutura como Código

## Introdução

*Infrastructure as Code* (IaC) é a prática de descrever em código os recursos que compõem uma infraestrutura de TI, permitindo sua automação.

- **Provisionamento**: definir quais recursos criar.
- **Configuração**: definir as opções para cada recurso criado.
- Nuvens públicas e privadas oferecem operações através de APIs que permitem a plataformas IaC criar e configurar recursos.

---

## Benefícios da IaC

- **Padronização**: usando o mesmo código para gerar os ambientes de homologação e produção, garantimos que ambos são idênticos.
- **Controle de versão**: é possível controlar a evolução da infraestrutura em um sistema de gerenciamento de código (Git).
- **Integração com CI/CD**: o próprio código pode ser integrado em um *pipeline* de entrega contínua.
- **Agilidade**: implantações que alteram a infraestrutura são mais rápidas e eficientes.
- **Redução de custo**: a possibilidade de analisar o código que instancia a infraestrutura facilita a identificação de desperdícios.

---

## Linguagens IaC

Como a infraestrutura será descrita em código, precisamos de uma linguagem de programação. Existem três categorias:

1. Linguagens de *Scripts*
2. Linguagens Declarativas
3. Linguagens de Programação Tradicionais

Na prática, as três categorias podem ser usadas em conjunto em um mesmo projeto.

---

## Linguagens de *Scripts*

Linguagens como *bash* ou *PowerShell*, que usam comandos para gerar sequências de ações para configurar infraestrutura.

- No caso das nuvens, a maioria disponibiliza uma ferramenta em linha de comando (*CLI*) que pode ser integrada em *scripts*.
- Têm poucas dependências e estão disponíveis na maioria dos sistemas operacionais.
- **Desvantagem**: são de baixo nível — precisam de muitos comandos para realizar as atividades de criação e configuração de infraestrutura.

**Exemplo — criar uma instância EC2 com a AWS CLI:**

```bash
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --count 1 \
  --instance-type t2.micro \
  --key-name MyKeyPair \
  --security-group-ids sg-903004f8 \
  --subnet-id subnet-6e7f829e
```

---

## Linguagens Declarativas

O usuário não informa os comandos para criar os recursos — apenas **declara** quais as características do recurso a ser criado (estado desejado).

Exemplos: **Terraform**, **Ansible**, Puppet, Chef.

- **Vantagem**: as especificações dos recursos que estão sendo criados são explícitas.
- **Desvantagem**: o ambiente de execução é quem realiza as ações, então personalizações específicas exigem trechos em linguagens de *scripts*.

**Exemplo — mesmo recurso EC2, descrito em Terraform (HCL):**

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t2.micro"
  tags = {
    Name = "ExampleInstance"
  }
}
```

---

## Linguagens de Programação Tradicionais

Linguagens já conhecidas pelos desenvolvedores, usadas para criar aplicações: TypeScript, Java, **Python**, Go, C#, etc.

- A infraestrutura é descrita em programas que invocam bibliotecas e *frameworks* para a criação dos recursos.
- **Vantagem**: desenvolvedores podem auxiliar no processo de codificação de infraestrutura, pois já conhecem a linguagem.
- **Desvantagem**: assim como linguagens de *scripts*, o nível de abstração é baixo em relação às linguagens declarativas.

**Exemplo — criar uma instância EC2 com Python e boto3:**

```python
import boto3

def create_ec2_instance():
    ec2 = boto3.resource('ec2', region_name='us-west-2')
    instance = ec2.create_instances(
        ImageId='ami-0abcdef1234567890',
        MinCount=1,
        MaxCount=1,
        InstanceType='t2.micro',
        KeyName='my-key-pair',
        SubnetId='subnet-6e7f829e',
        SecurityGroupIds=['sg-903004f8'],
    )
    print("Created instance", instance[0].id)

create_ec2_instance()
```

---

## Metodologia IaC

### Provisionamento de infraestrutura

É a criação dos recursos, sem configurá-los.

- Exemplo: criar uma máquina virtual com SO e características de *hardware* definidas, mas sem serviços como servidores *web* ou banco de dados configurados.

### Configuração de servidores e modelos

É a configuração do SO e dos serviços que o recurso irá hospedar.

- Exemplo: dado o provisionamento prévio de uma VM, configurar o NGINX com WordPress.
- Modelos pré-existentes podem ser utilizados, também conhecidos como **imagens**.

### Contêineres

Permite a uma mesma instância de VM hospedar aplicações de diferentes pilhas de *software*.

- Exemplo: uma instância pode hospedar uma aplicação Java ao mesmo tempo que executa código Python no Flask *Framework*.
- O provisionamento pode criar uma instância padrão, sendo que a configuração é feita criando imagens de contêineres para cada aplicação.

### Configuração e Implantação no Kubernetes

- Permite a orquestração de contêineres.
- Um *cluster* Kubernetes é a união de vários servidores.
- O sistema permite a distribuição de contêineres nos vários servidores, com alta flexibilidade e adaptabilidade.

> Contêineres serão detalhados em um módulo posterior.

---

## Conclusão

- **Tudo deve ser automatizado em código.**
- O código deve estar no Git, de preferência junto com o código da aplicação.
- Separar em uma hierarquia de diretórios de acordo com a infraestrutura.
- Integrar o código de infraestrutura ao *pipeline* CI/CD.
- O código deve ser **idempotente**: só criar os recursos que ainda não existem.
- O código deve ser **modular**.
