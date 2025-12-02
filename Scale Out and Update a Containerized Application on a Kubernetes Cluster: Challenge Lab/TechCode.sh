#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT_FORMAT}"
echo

# Check if zone is already set
if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}No default zone configured.${RESET_FORMAT}"
  echo "${BLUE_TEXT}Available zones:${RESET_FORMAT}"
  gcloud compute zones list --format="value(name)" | sort
  echo
  read -p "${CYAN_TEXT}${BOLD_TEXT}Enter your zone (e.g., us-central1-a): ${RESET_FORMAT}" ZONE
  export ZONE
  echo "${GREEN_TEXT}${BOLD_TEXT}Zone set to: $ZONE${RESET_FORMAT}"
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Using pre-configured zone: $ZONE${RESET_FORMAT}"
  echo "${YELLOW_TEXT}To change zone, run: export ZONE=your-new-zone${RESET_FORMAT}"
fi
echo

# Step 1: Download files
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Downloading application files...${RESET_FORMAT}"
gsutil cp gs://$DEVSHELL_PROJECT_ID/echo-web-v2.tar.gz . & spinner
echo "${GREEN_TEXT}Download complete!${RESET_FORMAT}"
echo

# Step 2: Extract files
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Extracting application files...${RESET_FORMAT}"
tar -xzvf echo-web-v2.tar.gz & spinner
echo "${GREEN_TEXT}Extraction complete!${RESET_FORMAT}"
echo

# Step 3: Build container
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Building container image...${RESET_FORMAT}"
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/echo-app:v2 . & spinner
echo "${GREEN_TEXT}Build complete!${RESET_FORMAT}"
echo

# Step 4: Get cluster credentials
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Connecting to GKE cluster...${RESET_FORMAT}"
gcloud container clusters get-credentials echo-cluster --zone=$ZONE & spinner
echo "${GREEN_TEXT}Cluster connection established!${RESET_FORMAT}"
echo

# Step 5: Create deployment
echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Creating deployment...${RESET_FORMAT}"
kubectl create deployment echo-web --image=gcr.io/qwiklabs-resources/echo-app:v2 & spinner
echo "${GREEN_TEXT}Deployment created!${RESET_FORMAT}"
echo

# Step 6: Expose service
echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Exposing service...${RESET_FORMAT}"
kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000 & spinner
echo "${GREEN_TEXT}Service exposed!${RESET_FORMAT}"
echo

# Step 7: Scale deployment
echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Scaling deployment...${RESET_FORMAT}"
kubectl scale deploy echo-web --replicas=2 & spinner
echo "${GREEN_TEXT}Deployment scaled to 2 replicas!${RESET_FORMAT}"
echo

# Get service URL
echo "${BLUE_TEXT}${BOLD_TEXT}Getting service URL...${RESET_FORMAT}"
SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
while [ -z "$SERVICE_IP" ]; do
  echo "${YELLOW_TEXT}Waiting for external IP...${RESET_FORMAT}"
  sleep 5
  SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
done
echo "${GREEN_TEXT}Your application is now available at: http://$SERVICE_IP${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
