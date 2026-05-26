"""
Exemplo de criação de instância EC2 via boto3 (Módulo 01 — Linguagens Tradicionais)
Substitua os valores de ImageId, KeyName, SubnetId e SecurityGroupIds
conforme sua conta no AWS Academy Learner Lab.

Instalação: pip install boto3
"""

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
