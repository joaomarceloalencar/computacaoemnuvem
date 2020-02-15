#!/bin/bash

ROLENAME="S3LambdaTeste"
S3POLICY="Permissoes-Acesso-S3"
LAMBDAPOLICY="Permissoes-Execucao-Lambda"

# Verify if role exists
if aws iam get-role --role-name $ROLENAME &> /dev/null
then
   echo "Removing role $ROLENAME and attached policies."
   aws iam delete-role-policy --role-name "$ROLENAME" --policy-name "$S3POLICY"
   aws iam delete-role-policy --role-name "$ROLENAME" --policy-name "$LAMBDAPOLICY"
   aws iam delete-role --role-name "$ROLENAME"
else
   echo "There is no such role..."
fi

