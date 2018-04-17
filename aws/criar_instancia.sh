#!/bin/bash -e

# A única coisa que precisa ser fornecida é o nome da chave que deseja usar
KEYNAME=$1

# Recuperar o ID de uma imagem
AMIID=$(aws ec2 describe-images --filter "Name=description,Values=Amazon Linux AMI 2017.09.1.2018*x86_64 HVM EBS" --query "Images[0].ImageId" --output text)
echo "ID da Imagem: $AMIID"

# Recupera o ID de uma rede
VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
echo "ID do VPC: $VPCID"

# Recupera o ID da subrede padrão do VPC
SUBNETID=$(aws ec2 describe-subnets --filter "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
echo "ID da Subnet: $SUBNETID"

# Cria um grupo de segurança
SGID=$(aws ec2 create-security-group --group-name grupodeseguranca_script --description "Grupo de Seguranca para teste de Scripts" --vpc-id $VPCID --output text)
echo "ID do Grupo de Segurança: $SGID"

# Liberar acesso à porta 22 (TCP)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Criar a instância
INSTANCEID=$(aws ec2 run-instances --image-id $AMIID --key-name $KEYNAME --instance-type t2.micro --security-group-ids $SGID --subnet-id $SUBNETID --query "Instances[0].InstanceId" --output text)

echo "Aguardando a criação da instância $INSTANCEID..."
aws ec2 wait instance-running --instance-ids $INSTANCEID

# Recuperando endereço público da instância
PUBLICNAME=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)
echo "Conexões SSH permitidas na instância $INSTANCEID no endereço $PUBLICNAME."
echo "Abra outro terminal e execute:"
echo "ssh -i $KEYNAME.pem ec2-user@$PUBLICNAME"
read -p "Aperte [Enter] para finalizar a instância..."

# Finalizando a instância
aws ec2 terminate-instances --instance-ids $INSTANCEID 
echo "Finalizando a instância $INSTANCEID."
aws ec2 wait instance-terminated --instance-ids $INSTANCEID
aws ec2 delete-security-group --group-id $SGID



