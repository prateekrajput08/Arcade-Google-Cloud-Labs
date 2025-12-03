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
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMA}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Check if zone is already set
if [ -z "$ZONE" ]; then
  read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter your zone (e.g., us-central1-a): ${RESET}" ZONE
  export ZONE
  echo "${GREEN_TEXT}${BOLD_TEXT}Zone set to: $ZONE${RESET}"
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Using pre-configured zone: $ZONE${RESET}"
  echo "${YELLOW_TEXT}To change zone, run: export ZONE=your-new-zone${RESET}"
fi
echo

# Step 1: Download files
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Downloading application files...${RESET}"
gsutil cp gs://$DEVSHELL_PROJECT_ID/echo-web-v2.tar.gz . & spinner
echo "${GREEN_TEXT}Download complete!${RESET}"
echo

# Step 2: Extract files
echo "${YELLOW_TEXT}${BOLD}Step 2: Extracting application files...${RESET}"
tar -xzvf echo-web-v2.tar.gz & spinner
echo "${GREEN_TEXT}Extraction complete!${RESET}"
echo

# Step 3: Build container
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Building container image...${RESET}"
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/echo-app:v2 . & spinner
echo "${GREEN_TEXT}Build complete!${RESET}"
echo

# Step 4: Get cluster credentials
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4: Connecting to GKE cluster...${RESET}"
gcloud container clusters get-credentials echo-cluster --zone=$ZONE & spinner
echo "${GREEN_TEXT}Cluster connection established!${RESET}"
echo

# Step 5: Create deployment
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5: Creating deployment...${RESET}"
kubectl create deployment echo-web --image=gcr.io/qwiklabs-resources/echo-app:v2 & spinner
echo "${GREEN_TEXT}Deployment created!${RESET}"
echo

# Step 6: Expose service
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Exposing service...${RESET}"
kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000 & spinner
echo "${GREEN_TEXT}Service exposed!${RESET}"
echo

# Step 7: Scale deployment
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 7: Scaling deployment...${RESET}"
kubectl scale deploy echo-web --replicas=2 & spinner
echo "${GREEN_TEXT}Deployment scaled to 2 replicas!${RESET}"
echo

# Get service URL
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting service URL...${RESET}"
SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
while [ -z "$SERVICE_IP" ]; do
  echo "${YELLOW_TEXT}Waiting for external IP...${RESET}"
  sleep 5
  SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
done
echo "${GREEN_TEXT}Your application is now available at: http://$SERVICE_IP${RESET}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Dont forget to Like, Share and Subscribe for more Videos ${RESET_FORMAT}"
