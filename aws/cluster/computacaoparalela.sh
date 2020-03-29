#!/bin/bash -e

#Quantidade de processadores por nó.
N=$1

if [ -z "$N" ]
then
	echo "Este script cria um cluster com dois nós."
	echo "O usuário pode especificar a quantidade de núcleos por nó."
	echo "Valores válidos são N = 1, 2, 4 e 8."
	echo "Uso: $0 N"
	exit 0
fi

INSTANCETYPE=""
case "$N" in
1) INSTANCETYPE="t2.micro" ;;
2) INSTANCETYPE="t2.medium" ;;
4) INSTANCETYPE="t2.xlarge" ;;
8) INSTANCETYPE="t2.2xlarge" ;;
*) echo "Valor inválido para N (1, 2, 4 ou 8 são aceitos)" 
   exit 1
   ;;
esac


# Nome da chave que deseja usar
KEYNAME=computacaoparalela
echo "Chave a ser utilizada: $KEYNAME"

# Recupera o ID de uma rede
VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
echo "ID do VPC: $VPCID"

# Recupera o ID da subrede padrão do VPC
SUBNETID=$(aws ec2 describe-subnets --filter "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
echo "ID da Subnet: $SUBNETID"

# Gera nome único para a pilha
STACKNAME="cluster"`date +%H%M%S`

aws cloudformation create-stack --stack-name "$STACKNAME" --template-body file://computacaoparalela.yaml --parameters \
ParameterKey=InstanceTypeParameter,ParameterValue=$INSTANCETYPE \
ParameterKey=ClusterKeyNameParameter,ParameterValue=$KEYNAME \
ParameterKey=ClusterAvailabilityZoneParameter,ParameterValue=us-east-1a \
ParameterKey=ClusterVPCParameter,ParameterValue=$VPCID \
ParameterKey=ClusterPublicSubnetParameter,ParameterValue=$SUBNETID 

STATUS=$(aws cloudformation describe-stacks --stack-name "$STACKNAME" --query 'Stacks[*].StackStatus' --output text)
while [ "$STATUS" != "CREATE_COMPLETE" ]
do
    STATUS=$(aws cloudformation describe-stacks --stack-name "$STACKNAME" --query 'Stacks[*].StackStatus' --output text)
    echo "Cluster em criação..."
    sleep 10
done

PUBLICIP=$(aws cloudformation describe-stacks --stack-name "$STACKNAME"  --query 'Stacks[*].Outputs[*].OutputValue' --output text)

#HOSTS=1
#while [ "$HOSTS" -eq 1 ]
#do
#    HOSTS=$(ssh -oStrictHostKeyChecking=no -i "$KEYNAME".pem ubuntu@"$PUBLICIP" wc -l /home/hostfile | awk '{print $1}')
#    echo "Estabelecendo ligação entre os nós..."
#    sleep 10
#done

echo "Cluster criado."
echo "Acesse em outro terminal por:"
echo "ssh -i $KEYNAME.pem ubuntu@$PUBLICIP"

echo "Aperte [enter] duas vezes para finalizar o cluster."
read -p "Primeira vez."
read -p "Segunda vez."
aws cloudformation delete-stack --stack-name $STACKNAME

