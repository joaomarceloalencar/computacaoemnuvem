#!/bin/bash
NAME=$1
ROLE=$2
aws lambda create-function --function "$NAME" --runtime python3.7 --role $ROLE --handle lambda_function.lambda_handler --zip-file fileb://function.zip
