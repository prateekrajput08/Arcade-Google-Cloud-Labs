#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud auth list
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

cat > server.js <<EOF_CP
var http = require('http');
var handleRequest = function(request, response) {
  response.writeHead(200);
  response.end("Hello World!");
}
var www = http.createServer(handleRequest);
www.listen(8080);
EOF_CP

cat > Dockerfile <<EOF_CP
FROM node:6.9.2
EXPOSE 8080
COPY server.js .
CMD node server.js
EOF_CP

docker build -t gcr.io/$PROJECT_ID/hello-node:v1 .

docker run -d -p 8080:8080 gcr.io/$PROJECT_ID/hello-node:v1

curl http://localhost:8080

ID=$(docker ps --format '{{.ID}}')

docker stop $ID

gcloud auth configure-docker --quiet

docker push gcr.io/$PROJECT_ID/hello-node:v1

gcloud config set project $PROJECT_ID

gcloud container clusters create hello-world --zone="$ZONE" --num-nodes 2 --machine-type n1-standard-1

kubectl create deployment hello-node --image=gcr.io/$PROJECT_ID/hello-node:v1

sleep 5

kubectl get deployments

sleep 5

kubectl get pods

kubectl cluster-info

kubectl config view

kubectl get events

kubectl expose deployment hello-node --type="LoadBalancer" --port=8080
sleep 7
kubectl get services
kubectl scale deployment hello-node --replicas=4
sleep 5
kubectl get deployment
sleep 7
kubectl get pods

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
