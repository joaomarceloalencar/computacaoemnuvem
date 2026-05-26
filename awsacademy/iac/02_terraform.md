# Usando Terraform para Provisionamento de Infraestrutura

## Introdução

O Terraform permite escrever definições declarativas para implantar infraestrutura usando a *Hashicorp Configuration Language* (**HCL**), com sintaxe semelhante a arquivos JSON.

Neste módulo vamos:

- Instalar e configurar o Terraform.
- Escrever código HCL para criar infraestrutura na AWS.
- Entender as opções de linha de comando do Terraform.
- Conhecer boas práticas para organização dos arquivos.

---

## Instalação

Considerando Ubuntu como distribuição Linux, usando o gerenciador de pacotes `apt`:

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
```

> Consulte as instruções atualizadas em [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install).
> Você também pode utilizar o script `instalar_terraform.sh` disponível no repositório da disciplina.

---

## Etapas

1. Configurar o acesso à AWS.
2. Configurar o provedor Terraform para AWS.
3. Escrever código para criar infraestrutura na AWS:
   - Separar em arquivos diferentes.
   - Usar variáveis.
4. Usar comandos Terraform para gerenciar a infraestrutura.

---

## Configuração da AWS

Instale a ferramenta de linha de comando da AWS:

```bash
# Opção 1 — pacote oficial
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Opção 2 — apt
sudo apt install awscli
```

Configure as credenciais com as informações do **AWS Academy** (aba *AWS Details / AWS CLI*):

```bash
# Copie o bloco para ~/.aws/credentials, ou exporte as variáveis:
export AWS_ACCESS_KEY_ID="ASIAUJ4YYQBU23PEVH54"
export AWS_SECRET_ACCESS_KEY="vyhiFCRzdCeI+qraqwP6JRpY9gkNWZ0BA7iLwE5X"
export AWS_SESSION_TOKEN="FwoGZXIvYXdzEI...."
```

> **Atenção:** As credenciais do AWS Academy expiram. Exporte as variáveis novamente sempre que iniciar uma nova sessão do Learner Lab.

---

## Exemplo de Arquivo Terraform

### `provider.tf` — definir o provedor e a região

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
```

> Começamos definindo qual provedor vamos utilizar e configuramos a região desejada.

### `securitygroup.tf` — criar um Security Group

```hcl
resource "aws_security_group" "devops" {
  name        = "devops"
  description = "Grupo de Segurança da Disciplina DevOps"
  tags = {
    Name = "devops"
  }
}

resource "aws_vpc_security_group_ingress_rule" "permitir_ssh_ipv4" {
  security_group_id = aws_security_group.devops.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
```

> Criamos um grupo de segurança (*firewall*) e adicionamos uma regra para liberar o acesso SSH.

### `main.tf` — criar uma instância EC2

```hcl
resource "aws_instance" "app_server" {
  ami             = "ami-0c7217cdde317cfec"   # específico da região us-east-1
  instance_type   = "t2.micro"
  key_name        = "vockey"
  security_groups = ["devops"]

  tags = {
    Name = "InstanciaDevOps"
  }
}
```

> Referenciamos o Security Group criado anteriormente pelo nome.

---

## Comandos e Desenvolvimento Local

O fluxo básico de trabalho com Terraform:

```
Arquivos .tf
    │
    ├─► terraform fmt       → formata os arquivos .tf
    │       │
    │       └─► terraform init      → baixa os plugins do provedor (diretório .terraform/)
    │               │
    │               └─► terraform validate  → valida a sintaxe dos arquivos
    │                       │
    │                       └─► terraform plan   → gera o plano de execução
    │                               │
    │                               └─► terraform apply  → aplica as mudanças na nuvem
```

| Comando | O que faz |
|---|---|
| `terraform fmt` | Formata os arquivos `.tf` seguindo o estilo padrão |
| `terraform init` | Inicializa o diretório e baixa os plugins do provedor |
| `terraform validate` | Verifica se os arquivos `.tf` são válidos |
| `terraform plan` | Mostra o que será criado/modificado/destruído |
| `terraform apply` | Executa o plano e aplica as mudanças |
| `terraform destroy` | Remove todos os recursos gerenciados pelo código |

---

## Integração Contínua

Em um fluxo de Integração Contínua, os mantenedores enviam os arquivos `.tf` para um sistema de controle de versão (Git). Um servidor de CI executa automaticamente a pipeline:

```
Mantenedores → Git → Servidor de CI: fmt → init → validate → plan → apply → Recursos na Nuvem
```

---

## Boas Práticas

### Organização em múltiplos arquivos

Em vez de um único `main.tf`, divida em arquivos por responsabilidade:

```
├── provider.tf       # configuração do provedor e backend
├── variables.tf      # declaração de variáveis
├── main.tf           # recursos principais
├── securitygroup.tf  # regras de firewall
└── outputs.tf        # valores de saída (IPs, IDs, etc.)
```

### Usar variáveis

Declare variáveis em `variables.tf` para aumentar a flexibilidade do código:

```hcl
variable "regiao" {
  description = "Região AWS"
  default     = "us-east-1"
}
```

### Salvar o plano de execução

```bash
terraform plan -out=plano.tfplan
terraform apply plano.tfplan
```

O arquivo `plano.tfplan` pode ser aplicado a partir de outra estação de trabalho ou no servidor de CI — semelhante a uma compilação.

### Armazenar o estado remoto (backend S3)

O arquivo `terraform.tfstate` contém o estado da infraestrutura. Para times, é essencial que todos acessem o mesmo estado. Armazene-o em um *bucket* S3:

```bash
# Crie um bucket (o nome precisa ser único globalmente)
aws s3 mb s3://devops20240222
```

Adicione o *backend* ao `provider.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "devops20240222"
    key    = "state"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
```

> O arquivo `terraform.tfstate.lock.info` garante a sincronização quando várias pessoas trabalham simultaneamente.

---

## Conclusão

- Terraform permite usar uma linguagem declarativa para descrever recursos de nuvem.
- É uma tecnologia nativa da nuvem para gerenciar infraestrutura.
- O uso de *backend* remoto (S3) facilita o desenvolvimento colaborativo da infraestrutura.
- Terraform pode ser usado tanto na linha de comando das estações de trabalho dos mantenedores quanto em um servidor de CI/CD.
