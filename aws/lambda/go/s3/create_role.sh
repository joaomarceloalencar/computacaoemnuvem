#!/bin/bash

ROLENAME="S3LambdaTeste"
S3POLICY="Permissoes-Acesso-S3"
LAMBDAPOLICY="Permissoes-Execucao-Lambda"

# Verify if role exists
if aws iam get-role --role-name $ROLENAME &> /dev/null
then
   echo "Role exists!!! Skipping permissions configuration..."
else
   echo "Creating role and attaching policies..."
   aws iam create-role --role-name "$ROLENAME" --assume-role-policy-document file://"$ROLENAME.json"
   aws iam put-role-policy --role-name "$ROLENAME" --policy-name "$S3POLICY"  --policy-document file://"$S3POLICY.json"
   aws iam put-role-policy --role-name "$ROLENAME" --policy-name "$LAMBDAPOLICY" --policy-document file://"$LAMBDAPOLICY.json"
fi

