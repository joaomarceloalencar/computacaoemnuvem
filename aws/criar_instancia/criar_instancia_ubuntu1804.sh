#!/bin/bash -e

# A única coisa que precisa ser fornecida é o nome da chave que deseja usar
KEYNAME=$1

# Recuperar o ID de uma imagem
AMIID=$(aws ec2 describe-images --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-????????" "Name=architecture,Values=x86_64" --query 'Images[0].[ImageId]' --output text)
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

# Liberar acesso à porta 22 e 80 (TCP)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 80 --cidr 0.0.0.0/0

# Script para executar na instância:
cat<<EOF > script.sh
#!/bin/bash
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
echo "Teste de Script." > /var/www/html/index.html
EOF

# Criar a instância
INSTANCEID=$(aws ec2 run-instances --image-id $AMIID --key-name $KEYNAME --instance-type t2.micro --security-group-ids $SGID --subnet-id $SUBNETID  --user-data file://script.sh --query "Instances[0].InstanceId" --output text)
rm script.sh

echo "Aguardando a criação da instância $INSTANCEID..."
aws ec2 wait instance-running --instance-ids $INSTANCEID

# Recuperando endereço público da instância
PUBLICNAME=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)
echo "Conexões SSH permitidas na instância $INSTANCEID no endereço $PUBLICNAME."
echo "Abra outro terminal e execute:"
echo "ssh -i $KEYNAME.pem ubuntu@$PUBLICNAME"
echo "Ou acess a página:"
echo "http://$PUBLICNAME"
read -p "Aperte [Enter] para finalizar a instância..."

# Finalizando a instância
aws ec2 terminate-instances --instance-ids $INSTANCEID 
echo "Finalizando a instância $INSTANCEID."
aws ec2 wait instance-terminated --instance-ids $INSTANCEID
aws ec2 delete-security-group --group-id $SGID



