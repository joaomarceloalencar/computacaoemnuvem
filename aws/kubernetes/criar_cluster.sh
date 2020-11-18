#!/bin/bash
# Este script criará um cluster Kubernetes na nuvem da AWS de acordo com o tutorial https://github.com/kelseyhightower/kubernetes-the-hard-way
# Pré-requisito
# - Ter a linha de comando da AWS instalada e configurada
# - Utilizar a região us-east-1

# Funções auxiliares
logger() 
{
    DATA=$(date "+%d/%m/%Y %H:%M:%S")
    echo "[$DATA] $1"
}

copiar()  
{
    scp -o "LogLevel=ERROR" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" $1 ubuntu@$2:~/
}

executar() 
{
    ssh -o "LogLevel=ERROR" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" ubuntu@"$1" "$2" 
}

# O primeiro parâmetro é o caminho completo do diretório onde serão guardados os arquivos de configuração locais. 
BASE_DIR=$(pwd)
KUBE_CONFIG_DIR=$1

# Etapa 01 - Instalar as ferramentas clientes
logger "Etapa 01 - Instalar as ferramentas clientes"
cd $KUBE_CONFIG_DIR
 
if [ \( ! -f $KUBE_CONFIG_DIR/bin/cfssl \) -o \( ! -f $KUBE_CONFIG_DIR/bin/cfssljson \) -o \( ! -f $KUBE_CONFIG_DIR/bin/kubectl \) ];
then 
    logger "Baixando os as ferramentas clientes."
    [ -d $KUBE_CONFIG_DIR/bin ] || mkdir bin/
    wget -q --show-progress --https-only --timestamping \
        https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
        https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson \
        https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl
    chmod +x cfssl cfssljson kubectl
    mv cfssl cfssljson kubectl bin/
else
    logger "Ferramentas clientes já estão presentes, partindo para verificação."
fi
export PATH=$KUBE_CONFIG_DIR/bin:$PATH
logger "Testando a saída dos programas."
set -x
cfssl version
cfssljson --version
kubectl version --client
set +x 
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 02 - Criar as máquinas virtuais (necessário ter o arquivo cluster.yaml no mesmo diretório)
logger "Etapa 02 - Criar as máquinas virtuais"
STACK_NAME="KUBERNETESHARDWAY"
aws cloudformation create-stack --stack-name "$STACK_NAME" --template-body file://$BASE_DIR/cluster.yaml
STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[*].StackStatus' --output text)
while [ \( "$STATUS" != "CREATE_COMPLETE" \) -a \( "$STATUS" != "ROLLBACK_IN_PROGRESS" \) ]
do
    STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[*].StackStatus' --output text)
    logger "Cluster Kubernetes em criação... STATUS: $STATUS"
    sleep 10
done

CONTROLLER_IP_PUBLICO=()
CONTROLLER_IP_PRIVADO=()
WORKER_IP_PUBLICO=()
WORKER_IP_PRIVADO=()


for instance in 0 1 2 
do
    CONTROLLER_IP_PUBLICO[$instance]=$(aws cloudformation describe-stacks --stack-name KUBERNETESHARDWAY --query "Stacks[].Outputs[?OutputKey=='EnderecoPublicoController$instance'].OutputValue" --output text)
    CONTROLLER_IP_PRIVADO[$instance]=$(aws cloudformation describe-stacks --stack-name KUBERNETESHARDWAY --query "Stacks[].Outputs[?OutputKey=='EnderecoPrivadoController$instance'].OutputValue" --output text)
    logger "Controller $instance IP público ${CONTROLLER_IP_PUBLICO[$instance]}"
    logger "Controller $instance IP privado ${CONTROLLER_IP_PRIVADO[$instance]}"

    WORKER_IP_PUBLICO[$instance]=$(aws cloudformation describe-stacks --stack-name KUBERNETESHARDWAY --query "Stacks[].Outputs[?OutputKey=='EnderecoPublicoWorker$instance'].OutputValue" --output text)
    WORKER_IP_PRIVADO[$instance]=$(aws cloudformation describe-stacks --stack-name KUBERNETESHARDWAY --query "Stacks[].Outputs[?OutputKey=='EnderecoPrivadoWorker$instance'].OutputValue" --output text)

    logger "Worker $instance IP público ${WORKER_IP_PUBLICO[$instance]}"
    logger "Worker $instance IP privado ${WORKER_IP_PRIVADO[$instance]}"
done
KUBERNETES_PUBLIC_ADDRESS=$(aws cloudformation describe-stacks --stack-name KUBERNETESHARDWAY --query "Stacks[].Outputs[?OutputKey=='EnderecoPublicoKubernetes'].OutputValue" --output text)
logger "KUBERNETES_PUBLIC_ADDRESS=$KUBERNETES_PUBLIC_ADDRESS"
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 03 - Configurar a Autoridade Certificadora (CA) e gerar os certificados para cada serviço
logger "Etapa 03 - Configurar a Autoridade Certificadora (CA) e gerar os certificados para cada serviço"
CERT_CONF_DIR=$BASE_DIR/cert_config
[ -d $KUBE_CONFIG_DIR/certs ] && rm -rf $KUBE_CONFIG_DIR/certs
mkdir $KUBE_CONFIG_DIR/certs

logger "Gerando Autoridade Certificadora."
cd $KUBE_CONFIG_DIR/certs
cfssl gencert -initca $CERT_CONF_DIR/ca-csr.json | cfssljson -bare ca
logger "Gerando Certificados do Cliente Administrativo."
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -profile=kubernetes \
    $CERT_CONF_DIR/admin-csr.json | cfssljson -bare admin

logger "Gerando Certificados dos Clientes Kubelets."
for instance in 0 1 2
do 
    logger "Certificado para o worker-$instance:"
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=$CERT_CONF_DIR/ca-config.json \
        -hostname=worker-${instance},${WORKER_IP_PUBLICO[$instance]},${WORKER_IP_PRIVADO[$instance]} \
        -profile=kubernetes \
        $CERT_CONF_DIR/worker-$instance-csr.json | cfssljson -bare worker-$instance
done
logger "Gerando Certificado do Kube Controller."
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -profile=kubernetes \
    $CERT_CONF_DIR/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
logger "Gerando Certificado do Kube Proxy."
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -profile=kubernetes \
    $CERT_CONF_DIR/kube-proxy-csr.json | cfssljson -bare kube-proxy
logger "Gerando Certificado do Kube Scheduler."
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -profile=kubernetes \
    $CERT_CONF_DIR/kube-scheduler-csr.json | cfssljson -bare kube-scheduler
logger "Gerando Certificado do Servidor de API."
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
    -profile=kubernetes \
    $CERT_CONF_DIR/kubernetes-csr.json | cfssljson -bare kubernetes
logger "Gerando Certificado do Serviço de Contas."
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=$CERT_CONF_DIR/ca-config.json \
    -profile=kubernetes \
    $CERT_CONF_DIR/service-account-csr.json | cfssljson -bare service-account
logger "Copiando certificados e chaves para as máquinas."
for instance in 0 1 2
do
    # Workers
    copiar $KUBE_CONFIG_DIR/certs/ca.pem ${WORKER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/worker-$instance-key.pem ${WORKER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/worker-$instance.pem ${WORKER_IP_PUBLICO[$instance]}

    # Controllers
    copiar $KUBE_CONFIG_DIR/certs/ca.pem ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/ca-key.pem ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/kubernetes-key.pem ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/kubernetes.pem ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/service-account-key.pem ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/certs/service-account.pem ${CONTROLLER_IP_PUBLICO[$instance]}
done
    
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."


# Etapa 04 - Gerar os arquivos de configuração para autenticação.
logger "Etapa 04 - Gerar os arquivos de configuração para autenticação."
[ -d $KUBE_CONFIG_DIR/config ] && rm -rf $KUBE_CONFIG_DIR/config
mkdir $KUBE_CONFIG_DIR/config

logger "Gerando Arquivo de Configuração do Kubelet"
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=$KUBE_CONFIG_DIR/config/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=$KUBE_CONFIG_DIR/certs/${instance}.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBE_CONFIG_DIR/config/${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=$KUBE_CONFIG_DIR/config/${instance}.kubeconfig
  kubectl config use-context default --kubeconfig=$KUBE_CONFIG_DIR/config/${instance}.kubeconfig
done

logger "Gerando Arquivo de Configuração do Kube-Proxy"
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=$KUBE_CONFIG_DIR/certs/kube-proxy.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=$KUBE_CONFIG_DIR/config/kube-proxy.kubeconfig

logger "Gerando Arquivo de Configuração do Kube-Controller-Manager"
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=$KUBE_CONFIG_DIR/certs/kube-controller-manager.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=$KUBE_CONFIG_DIR/config/kube-controller-manager.kubeconfig

logger "Gerando Arquivo de Configuração do Kube-Scheduler"
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=$KUBE_CONFIG_DIR/certs/kube-scheduler.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=$KUBE_CONFIG_DIR/config/kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=$KUBE_CONFIG_DIR/config/kube-scheduler.kubeconfig

logger "Gerando Arquivo de Configuração do Kube Admin"
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=$KUBE_CONFIG_DIR/config/admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=$KUBE_CONFIG_DIR/certs/admin.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBE_CONFIG_DIR/config/admin.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=$KUBE_CONFIG_DIR/config/admin.kubeconfig
kubectl config use-context default --kubeconfig=$KUBE_CONFIG_DIR/config/admin.kubeconfig

logger "Copiando as configurações para os Workers."
for instance in 0 1 2
do
    copiar $KUBE_CONFIG_DIR/config/worker-${instance}.kubeconfig ${WORKER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/config/kube-proxy.kubeconfig ${WORKER_IP_PUBLICO[$instance]}
done

logger "Copiando as configurações para os Controllers."
for instance in 0 1 2
do
    copiar $KUBE_CONFIG_DIR/config/admin.kubeconfig ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/config/kube-controller-manager.kubeconfig ${CONTROLLER_IP_PUBLICO[$instance]}
    copiar $KUBE_CONFIG_DIR/config/kube-scheduler.kubeconfig ${CONTROLLER_IP_PUBLICO[$instance]}
done

read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 05 - Gerar as chaves de criptografia de dados
logger "Etapa 05 - Gerar as chaves de criptografia de dados"
cd $KUBE_CONFIG_DIR/certs
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
logger "Copiando a chave de criptografia de dados para os Controllers."
for instance in 0 1 2
do
    copiar encryption-config.yaml ${CONTROLLER_IP_PUBLICO[$instance]}
done
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 06 - Iniciando o Cluster etcd
logger "Etapa 06 - Iniciando o Cluster etcd."
logger "Copiando executando o script para os Controllers."
for instance in 0 1 2
do
    copiar $BASE_DIR/scripts/etcd.sh ${CONTROLLER_IP_PUBLICO[$instance]}
    executar ${CONTROLLER_IP_PUBLICO[$instance]} "chmod +x etcd.sh"
    sleep 1
    executar ${CONTROLLER_IP_PUBLICO[$instance]} "./etcd.sh"
done
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 07 - Inicializando o Control Plane
logger "Etapa 07 - Inicializando o Control Plane."
logger "Copiando executando o script para os Controllers."
for instance in 0 1 2
do
    copiar "$BASE_DIR/scripts/control_plane.sh" "${CONTROLLER_IP_PUBLICO[$instance]}"
    executar "${CONTROLLER_IP_PUBLICO[$instance]}" "chmod +x control_plane.sh"
    sleep 1
    executar "${CONTROLLER_IP_PUBLICO[$instance]}" "./control_plane.sh"
done

logger "Configurando a Autorização RBAC"
copiar "$BASE_DIR/scripts/rbac.sh" "${CONTROLLER_IP_PUBLICO[0]}"
executar "${CONTROLLER_IP_PUBLICO[0]}" "./rbac.sh"
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 08 - Inicializando os Workers
logger "Etapa 08 - Inicializando os Workers."
for instance in 0 1 2
do
    copiar $BASE_DIR/scripts/workers.sh ${WORKER_IP_PUBLICO[$instance]}
    executar ${WORKER_IP_PUBLICO[$instance]} "chmod +x workers.sh"
    sleep 1
    executar ${WORKER_IP_PUBLICO[$instance]} "./workers.sh"
done
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 09 - Configurando cliente local
logger "Etapa 09 - Configurando cliente local."
cat > $KUBE_CONFIG_DIR/env.sh <<EOF
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$KUBE_CONFIG_DIR/certs/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443

kubectl config set-credentials admin \
    --client-certificate=$KUBE_CONFIG_DIR/certs/admin.pem \
    --client-key=$KUBE_CONFIG_DIR/certs/admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

kubectl config use-context kubernetes-the-hard-way
EOF
logger "Execute \"source $KUBE_CONFIG_DIR/env.sh\" em outro terminal para configurar a linha de comando."
read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 10: Configuração das Rotas
# logger "Etapa 10: Configuração das Rotas"
# Vou deixar em branco por enquanto, para testar se devo fazer via route table no VPC ou via ip route nas instâncias
# executar "${CONTROLLER_IP_PUBLICO[0]}" "sudo ip route add 192.168.1.0/24 via 10.240.0.21 dev ens5"
# executar "${CONTROLLER_IP_PUBLICO[0]}" "sudo ip route add 192.168.2.0/24 via 10.240.0.22 dev ens5"

# executar "${CONTROLLER_IP_PUBLICO[1]}" "sudo ip route add 192.168.0.0/24 via 10.240.0.20 dev ens5"
# executar "${CONTROLLER_IP_PUBLICO[1]}" "sudo ip route add 192.168.2.0/24 via 10.240.0.22 dev ens5"

# executar "${CONTROLLER_IP_PUBLICO[2]}" "sudo ip route add 192.168.0.0/24 via 10.240.0.20 dev ens5"
# executar "${CONTROLLER_IP_PUBLICO[2]}"  

read -p "Aperte ENTER para continuar ou CTRL-C em caso de erro."

# Etapa 11: Configurando o DNS
# source $KUBE_CONFIG_DIR/env.sh
# kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.7.0.yaml
# logger "pods criados:"
# kubectl get pods -l k8s-app=kube-dns -n kube-system

# Limpeza 
aws cloudformation delete-stack --stack-name $STACK_NAME
# rm -rf $KUBE_CONFIG_DIR/bin 
rm -rf $KUBE_CONFIG_DIR/certs
rm -rf $KUBE_CONFIG_DIR/config