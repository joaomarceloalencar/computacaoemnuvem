#!/bin/bash
NAME=$1
./create_package.sh
aws lambda update-function-code --function-name $NAME --zip-file fileb://function.zip
