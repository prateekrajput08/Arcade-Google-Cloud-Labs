#!/bin/bash

# Color and text format codes
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Starting GSP053: Managing Deployments Using Kubernetes Engine Lab...${RESET_FORMAT}"
echo

# Prompt for compute zone
echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Enter your desired compute zone (e.g., us-central1-a):${RESET_FORMAT}"
read -p "Zone: " ZONE
export ZONE
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Setting compute zone to ${ZONE}...${RESET_FORMAT}"
gcloud config set compute/zone "$ZONE"
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating Kubernetes cluster 'bootcamp'...${RESET_FORMAT}"
gcloud container clusters create bootcamp --zone "$ZONE" --machine-type e2-small --num-nodes 3 --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
echo

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Waiting for cluster to be ready (60 seconds)...${RESET_FORMAT}"
sleep 60
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Deploying auth service...${RESET_FORMAT}"
kubectl apply -f deployments/auth.yaml
kubectl apply -f services/auth.yaml
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Deploying hello service...${RESET_FORMAT}"
kubectl apply -f deployments/hello.yaml
kubectl apply -f services/hello.yaml
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating secrets and configmaps...${RESET_FORMAT}"
kubectl create secret generic tls-certs --from-file tls/ --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf --dry-run=client -o yaml | kubectl apply -f -
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Deploying frontend service...${RESET_FORMAT}"
kubectl apply -f deployments/frontend.yaml
kubectl apply -f services/frontend.yaml
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Scaling hello deployment to 5 replicas...${RESET_FORMAT}"
kubectl scale deployment hello --replicas=5
sleep 15
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Scaling hello deployment down to 3 replicas...${RESET_FORMAT}"
kubectl scale deployment hello --replicas=3
sleep 15
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Performing rolling update on hello deployment (version 2.0)...${RESET_FORMAT}"
kubectl set image deployment/hello hello=gcr.io/google-samples/hello-app:2.0 --record
sleep 30
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Rolling back hello deployment to previous revision...${RESET_FORMAT}"
kubectl rollout undo deployment/hello
sleep 30
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Displaying rollout history for hello deployment...${RESET_FORMAT}"
kubectl rollout history deployment/hello
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Listing all pods for verification...${RESET_FORMAT}"
kubectl get pods
echo

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Lab completed successfully!${RESET_FORMAT}"
