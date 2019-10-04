#!/bin/bash
# Este script cria um bucket usando um template. Para um caso mais simples da API, veja criar_bucket.sh

VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNETID=$(aws ec2 describe-subnets --filter "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)

aws cloudformation create-stack --stack-name bucketcreate \
--template-body file://bucketcreate.json \
 --capabilities CAPABILITY_IAM \
--parameters \
ParameterKey=KeyName,ParameterValue=computacaoemnuvem \
ParameterKey=VPC,ParameterValue=$VPCID \
ParameterKey=Subnet,ParameterValue=$SUBNETID
