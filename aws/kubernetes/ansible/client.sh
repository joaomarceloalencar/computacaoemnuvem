#!/bin/bash
KUBE_CONFIG_DIR=$1
KUBERNETES_PUBLIC_ADDRESS=$2

export PATH=${KUBE_CONFIG_DIR}/bin:$PATH
rm ~/.kube/config

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


