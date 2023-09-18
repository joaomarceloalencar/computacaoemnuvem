#!/bin/bash


REGION=us-east1
ZONE=us-east1-b

gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${ZONE}

# Task 1. Create a project jumphost instance
JUMPHOST="nucleus-host"

gcloud compute instances create ${JUMPHOST} \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud 

read -p "Verify and press enter..."

# Task 2. Create a Kubernetes service cluster
CLUSTER="nucleus-cluster"
PORT=8081
gcloud container clusters create --machine-type=e2-medium --zone=$ZONE ${CLUSTER}
gcloud container clusters get-credentials ${CLUSTER} --zone=$ZONE
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0
kubectl expose deployment hello-server --type=LoadBalancer --port $PORT

read -p "Verify and press enter..."

# Task 3. Set up an HTTP load balancer
# https://cloud.google.com/iap/docs/load-balancer-howto?hl=pt-br#gcloud_1
FIREWALL_RULE=lb-firewall-rule

## Create an instance template.
gcloud compute instance-templates create lb-backend-template \
  --region=${REGION} \
  --network=default \
  --subnet=default \
  --tags=allow-health-check \
  --machine-type=e2-micro \
  --image-family=debian-10 \
  --image-project=debian-cloud \
  --metadata-from-file=startup-script=./startup.sh

## Create a target pool. (I think is not necessary)
#gcloud compute target-pools create www-pool \
#  --region ${REGION} 

## Create a managed instance group.
gcloud compute instance-groups managed create lb-backend-example \
  --template=lb-backend-template \
  --size=2 \
  --zone=${ZONE}

gcloud compute instance-groups set-named-ports lb-backend-example \
  --named-ports http:80 \
  --zone=${ZONE}

## Create a firewall rule named as Firewall rule to allow traffic (80/tcp).
gcloud compute firewall-rules create ${FIREWALL_RULE} \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

## Allocate IP
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --network-tier=PREMIUM \
  --global

IP=$(gcloud compute addresses describe lb-ipv4-1 --format="get(address)" --global)

## Create a health check.
gcloud compute health-checks create http http-basic-check \
  --port 80

## Create a backend service, and attach the managed instance group with named port (http:80).
gcloud compute backend-services create web-backend-service \
  --load-balancing-scheme=EXTERNAL \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-example \
  --instance-group-zone=${ZONE} \
  --global

## Create a URL map, and target the HTTP proxy to route requests to your URL map.
gcloud compute url-maps create web-map-http \
  --default-service web-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
  --url-map web-map-http

## Create a forwarding rule.
gcloud compute forwarding-rules create http-content-rule \
  --load-balancing-scheme=EXTERNAL \
  --address=lb-ipv4-1 \
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80

# Clean
read -p "Press to clean the resources..."
gcloud compute instances delete ${JUMPHOST}

gcloud container clusters delete ${CLUSTER}

gcloud compute instance-templates delete lb-backend-template
gcloud compute target-pools delete www-pool
gcloud compute instance-groups managed delete lb-backend-group
gcloud compute firewall-rules delete ${FIREWALL_RULE}
gcloud compute health-checks delete http-basic-check
gcloud compute backend-services delete web-backend-service 
gcloud compute url-maps delete web-map-http
gcloud compute target-http-proxies delete http-lb-proxy 
gcloud compute addresses delete lb-ipv4-1 --global
gcloud compute forwarding-rules delete http-content-rule