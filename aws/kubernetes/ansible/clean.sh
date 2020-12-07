#/bin/bash
aws cloudformation delete-stack --stack-name kubernetes 
rm -r kubernetes/certs/*
rm -r kubernetes/config/*
