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

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Fetch zone and region
echo "${YELLOW_TEXT}Getting zone, region, and project details...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$ZONE" ] || [ -z "$REGION" ] || [ -z "$PROJECT_ID" ]; then
    echo "${YELLOW_TEXT}Failed to get Google Cloud configuration. Please check your gcloud setup.${RESET_FORMAT}"
    exit 1
fi

echo "${YELLOW_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo "${YELLOW_TEXT}Region: $REGION${RESET_FORMAT}"
echo "${YELLOW_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}"

# Set compute zone
echo "${YELLOW_TEXT}Setting compute zone...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

# Copy Kubernetes files
echo "${YELLOW_TEXT}Setting up Kubernetes Resources${RESET_FORMAT}"
echo "${YELLOW_TEXT}Copying Kubernetes configuration files...${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp053/kubernetes . &

cd kubernetes

# Create GKE cluster
echo "${YELLOW_TEXT}reating GKE Cluster${RESET_FORMAT}"
echo "${YELLOW_TEXT}Creating Kubernetes cluster with 3 nodes...${RESET_FORMAT}"
gcloud container clusters create bootcamp \
  --machine-type e2-small \
  --num-nodes 3 \
  --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw" &



# TASK 2 - Deployments
echo "${YELLOW_TEXT}TASK 2: Deploying Fortune App (Blue)${RESET_FORMAT}"
echo "${YELLOW_TEXT}Creating deployment and service...${RESET_FORMAT}"
kubectl create -f deployments/fortune-app-blue.yaml &

kubectl create -f services/fortune-app.yaml &


echo "${YELLOW_TEXT}Scaling deployment to 5 replicas...${RESET_FORMAT}"
kubectl scale deployment fortune-app-blue --replicas=5 &

COUNT=$(kubectl get pods | grep fortune-app-blue | wc -l | tr -d ' ')


echo "${YELLOW_TEXT}Scaling deployment to 3 replicas...${RESET_FORMAT}"
kubectl scale deployment fortune-app-blue --replicas=3 &

COUNT=$(kubectl get pods | grep fortune-app-blue | wc -l | tr -d ' ')


# TASK 3 - Confirmation
echo "${YELLOW_TEXT}TASK 3: Canary Deployment${RESET_FORMAT}"
echo "${YELLOW_TEXT} This task will perform a canary deployment strategy${NC}${RESET_FORMAT}"
echo "${CYAN_TEXT}? Do you want to continue with Task 3? ${NC}[${GREEN}Y${NC}/${RED}N${NC}]: ${RESET_FORMAT}"
read CONFIRM

if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" ]]; then
    echo "${YELLOW_TEXT}Task 3 aborted by user.${RESET_FORMAT}"
    exit 0
fi

echo "${YELLOW_TEXT}Updating container image to version 2.0.0...${RESET_FORMAT}"
kubectl set image deployment/fortune-app-blue fortune-app=$REGION-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/fortune-service:2.0.0 &


echo "${YELLOW_TEXT}Setting environment variable...${RESET_FORMAT}"
kubectl set env deployment/fortune-app-blue APP_VERSION=2.0.0 &


echo "${YELLOW_TEXT}Creating canary deployment...${RESET_FORMAT}"
kubectl create deployments/fortune-app-canary.yaml &


# TASK 5 - Blue-Green Deployment
echo "${YELLOW_TEXT}TASK 5: Blue-Green Deployment${RESET_FORMAT}"
echo "${YELLOW_TEXT}Setting up blue service...${RESET_FORMAT}"
kubectl apply services/fortune-app-blue-service.yaml &


echo "${YELLOW_TEXT}Creating green deployment...${RESET_FORMAT}"
kubectl create deployments/fortune-app-green.yaml &


echo "${YELLOW_TEXT}Setting up green service...${RESET_FORMAT}"
kubectl apply services/fortune-app-green-service.yaml &


echo "${YELLOW_TEXT}Updating blue service...${RESET_FORMAT}"
kubectl apply services/fortune-app-blue-service.yaml &


# Final message
echo "${GREEN_TEXT}Lab Completion Status${RESET_FORMAT}"
echo "${GREEN_TEXT} All tasks completed successfully!${RESET_FORMAT}"
echo "${CYAN_TEXT} Current deployments:${RESET_FORMAT}"
kubectl get deployments
echo "${CYAN_TEXT}Current services:${RESET_FORMAT}"
kubectl get services
echo "${CYAN_TEXT}Current pods:${RESET_FORMAT}"
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
