#!/bin/bash
# Exemplo de criação de instância EC2 via AWS CLI (Módulo 01 — Linguagens de Scripts)
# Substitua os valores de AMI, key-name, security-group-ids e subnet-id
# conforme sua conta no AWS Academy Learner Lab.

aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --count 1 \
  --instance-type t2.micro \
  --key-name MyKeyPair \
  --security-group-ids sg-903004f8 \
  --subnet-id subnet-6e7f829e
