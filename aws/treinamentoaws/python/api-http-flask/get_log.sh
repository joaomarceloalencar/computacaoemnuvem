#!/bin/bash
NAME=$1

ID=$(aws logs describe-log-streams --log-group-name /aws/lambda/$NAME --order-by LastEventTime --descending --max-items 1 | jq .logStreams[0].logStreamName | sed 's/\"//g')

aws logs get-log-events --log-group-name /aws/lambda/$NAME --log-stream-name $ID
