# Ansible para Configuração de Infraestrutura

## Introdução

Mostramos que através do *Terraform* podemos automatizar a criação de máquinas virtuais. Uma vez implantadas, as VMs devem ser **configuradas**: instalação de pacotes, atualização de arquivos de configuração, inicialização de serviços.

**Ansible** é uma solução de configuração mantida pela *Red Hat* que se destaca por:

- Arquivos de configuração em **YAML** ou JSON.
- Poucas dependências — é basicamente apenas um binário executável.
- Usa **SSH** para acessar as VMs, protocolo já disponível nas instâncias criadas nas nuvens.

> *Ansible* também poderia desempenhar o papel do *Terraform*, mas estudamos as duas ferramentas para ter uma visão completa das soluções mais usadas no mercado.

### Conceitos fundamentais

O Ansible tem duas configurações básicas:

- **Inventário (*inventory*)**: quais servidores são alvos das ações de configuração.
- ***Playbook***: as tarefas de configuração a serem executadas.

No inventário, podemos agrupar servidores por função: *web*, banco de dados, *backup*, etc. O *Playbook* permite associar tarefas a um único servidor ou a um grupo de servidores.

---

## Instalação

### Ubuntu

```bash
sudo apt-get update
sudo apt-get install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible python3-boto3
```

### Configuração

O arquivo de configuração geral fica em `/etc/ansible/ansible.cfg`. Ele contém as configurações gerais para todos os usuários.

Neste curso, vamos configurar o Ansible através de **variáveis de ambiente** e dos arquivos de inventário e *playbooks* — abordagem que torna mais fácil compartilhar os arquivos de configuração em repositórios de código.

---

## Inventário

Existem dois tipos de inventário:

### Estático

Servidores listados em um arquivo no formato **INI** ou **YAML**, com IP ou nome registrado em DNS (FQDN).

**Exemplo básico (formato INI):**

```ini
[web]
192.168.0.100
192.168.0.101

[bancodedados]
192.168.0.200
```

> Quando apenas os IPs ou nomes são informados, assume-se que o *login* via SSH sem senha (usando chaves) já está configurado. O usuário e chave padrão podem ser configurados no `/etc/ansible/ansible.cfg`.

**Exemplo com parâmetros explícitos:**

```ini
[web]
servidorweb1 ansible_host=3.81.235.92 ansible_user=ubuntu ansible_private_key_file=~/labuser.pem
servidorweb2 ansible_host=3.81.235.93 ansible_user=ubuntu ansible_private_key_file=~/labuser.pem

[bancodedados]
bancodedados1 ansible_host=54.3.97.17 ansible_user=ubuntu ansible_private_key_file=~/labuser.pem
```

Parâmetros por servidor:
- `ansible_host`: IP do servidor (permite usar apelidos que não sejam FQDN).
- `ansible_user`: usuário para *login* via SSH.
- `ansible_private_key_file`: chave SSH do usuário.
- `ansible_ssh_extra_args`: permite passar opções adicionais para a conexão SSH.

**Verificar conectividade:**

```bash
# Todos os servidores
ansible -i <inventário> all -m ping

# Apenas o grupo web
ansible -i <inventário> web -m ping

# Apenas o grupo bancodedados
ansible -i <inventário> bancodedados -m ping

# Um servidor específico
ansible -i <inventário> servidorweb1 -m ping
```

### Dinâmico

Gerado por um *script* que captura informações da nuvem em tempo real — pode recuperar o endereço ou nome de servidores criados pelo Terraform.

**Arquivo `aws_ec2.yaml` (o nome do arquivo é obrigatório):**

```yaml
---
plugin: amazon.aws.aws_ec2
aws_profile: default
regions:
  - us-east-1
keyed_groups:
  - key: tags
    prefix: tag
```

- O plugin `amazon.aws.aws_ec2` consulta a AWS para listar as instâncias.
- Os grupos de servidores são definidos pelas *tags* das instâncias.
- Se as instâncias tiverem nome (tag `Name`), também podem ser usadas como alvos.

```bash
# Verificar a conexão com a nuvem e listar os recursos existentes
ansible-inventory -i aws_ec2.yaml --graph
```

> Para o inventário dinâmico, a ferramenta de linha de comando da AWS precisa estar configurada.

---

## *Playbook*

O *Playbook* é escrito em **YAML** e lista as tarefas de configuração para cada servidor ou grupo de servidores. Uma tarefa representa uma ação: criar um arquivo, instalar um pacote, iniciar ou interromper um serviço.

Você não precisa escrever comandos *bash* para executar as tarefas — basta usar o **módulo** adequado para o tipo de ação desejada.

**Exemplo — instalar e iniciar o NGINX nos servidores web:**

```yaml
---
- hosts: web
  tasks:
    - name: Instalar nginx           # descrição da tarefa
      become: true                   # usar sudo
      apt:                           # módulo apt para instalar pacotes
        name: nginx
        state: latest
        update_cache: true

    - name: Iniciar o nginx
      service:
        name: nginx
        state: started
```

**Exemplo — *playbook* com múltiplos grupos:**

```yaml
---
# Servidores web: instalar NGINX
- hosts: web
  tasks:
    - name: Instalar nginx
      become: true
      apt:
        name: nginx
        state: latest
        update_cache: true
    - name: Iniciar o nginx
      service:
        name: nginx
        state: started

# Servidores de banco de dados: instalar MySQL
- hosts: bancodedados
  tasks:
    - name: Instalar o MySQL Server
      become: true
      apt:
        name: mysql-server
        state: latest
        update_cache: true
    - name: Iniciar o MySQL Server
      service:
        name: mysql
        state: started
```

**Executar o *playbook*:**

```bash
ansible-playbook -i <arquivo do inventário> <arquivo do playbook>
```

---

## Organização com *Roles*

Para projetos maiores, organize as tarefas em **roles** (papéis). Cada role encapsula as tarefas de uma função específica.

**Estrutura de diretórios recomendada (com inventário dinâmico):**

```
.
├── aws.yml              # inventário dinâmico
├── group_vars/
│   └── aws_ec2          # variáveis compartilhadas por grupos
├── host_vars/           # variáveis por host
├── playbook.yml         # playbook principal
└── roles/
    ├── web/
    │   └── tasks/
    │       └── main.yml # tarefas do servidor web
    └── bancodedados/
        └── tasks/
            └── main.yml # tarefas do banco de dados
```

**`group_vars/aws_ec2`** — variáveis SSH aplicadas a todos os hosts do inventário dinâmico:

```yaml
ansible_user: ubuntu
ansible_ssh_private_key_file: ~/labuser.pem
ansible_ssh_extra_args: '-o StrictHostKeyChecking=no'
```

**`playbook.yml`** — associa cada grupo de instâncias à sua *role*:

```yaml
---
- hosts: tag_Name_InstanciaNginx
  roles:
    - web

- hosts: tag_Name_InstanciaMySql
  roles:
    - bancodedados
```

**`roles/web/tasks/main.yml`:**

```yaml
---
- name: Instalar nginx
  become: true
  apt:
    name: nginx
    state: latest
    update_cache: true

- name: Iniciar o nginx
  service:
    name: nginx
    state: started
```

**`roles/bancodedados/tasks/main.yml`:**

```yaml
---
- name: Instalar o MySQL Server
  become: true
  apt:
    name: mysql-server
    state: latest
    update_cache: true

- name: Iniciar o MySQL Server
  service:
    name: mysql
    state: started
```

---

## Execução Completa (Terraform + Ansible)

Fluxo de trabalho integrando provisionamento (Terraform) e configuração (Ansible):

1. Configurar a linha de comando AWS.
2. Criar a infraestrutura com o Terraform (`terraform apply`).
3. Configurar o inventário dinâmico em um arquivo `aws_ec2.yaml`.
4. Configurar a estrutura de diretórios com `playbook.yml` e os *roles*.
5. Executar o *playbook*:

```bash
ansible-playbook -i aws_ec2.yaml playbook.yml
```

---

## Saída da Execução

Ao executar o *playbook*, o Ansible exibe o resultado de cada tarefa:

- ***Gathering Facts***: verifica se os servidores estão acessíveis.
- **`ok`**: execução com sucesso. Se a mudança que a tarefa realizaria já foi feita, também retorna `ok` (idempotência).
- **`changed`**: a execução teve sucesso e fez alterações no recurso.
- **`unreachable`**: a conexão com o servidor falhou no momento da execução.
- **`failed`**: a conexão foi estabelecida, mas a execução da tarefa falhou.
- ***Play Recap***: relatório final com o total de cada status por host.

---

## Conclusão

- Ansible é uma poderosa ferramenta para **configuração de infraestrutura**.
- Através das *tasks* podemos descrever qualquer etapa de configuração: instalar pacotes, configurar arquivos, gerenciar serviços.
- A lista completa de módulos (tasks) está disponível em [docs.ansible.com/ansible/latest/collections/index.html](https://docs.ansible.com/ansible/latest/collections/index.html).
- É possível criar novos *roles* e *playbooks* para cobrir cenários mais complexos.
- O exemplo apresentado apenas instala pacotes, mas é possível configurar toda uma aplicação com suas dependências e arquivos de configuração.
