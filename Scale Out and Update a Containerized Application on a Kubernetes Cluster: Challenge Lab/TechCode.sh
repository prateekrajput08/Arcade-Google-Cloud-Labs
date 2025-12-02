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
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Check if zone is already set
if [ -z "$ZONE" ]; then
  read -p "${CYAN}${BOLD}Enter your zone (e.g., us-central1-a): ${RESET}" ZONE
  export ZONE
  echo "${GREEN}${BOLD}Zone set to: $ZONE${RESET}"
else
  echo "${GREEN}${BOLD}Using pre-configured zone: $ZONE${RESET}"
  echo "${YELLOW}To change zone, run: export ZONE=your-new-zone${RESET}"
fi
echo

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"
echo

# Step 1: Download files
echo "${BLUE}${BOLD}Step 1: Downloading application files...${RESET}"
gsutil cp gs://$DEVSHELL_PROJECT_ID/echo-web-v2.tar.gz . & spinner
echo "${GREEN}Download complete!${RESET}"
echo

# Step 2: Extract files
echo "${BLUE}${BOLD}Step 2: Extracting application files...${RESET}"
tar -xzvf echo-web-v2.tar.gz & spinner
echo "${GREEN}Extraction complete!${RESET}"
echo

# Step 3: Build container
echo "${BLUE}${BOLD}Step 3: Building container image...${RESET}"
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/echo-app:v2 . & spinner
echo "${GREEN}Build complete!${RESET}"
echo

# Step 4: Get cluster credentials
echo "${BLUE}${BOLD}Step 4: Connecting to GKE cluster...${RESET}"
gcloud container clusters get-credentials echo-cluster --zone=$ZONE & spinner
echo "${GREEN}Cluster connection established!${RESET}"
echo

# Step 5: Create deployment
echo "${BLUE}${BOLD}Step 5: Creating deployment...${RESET}"
kubectl create deployment echo-web --image=gcr.io/qwiklabs-resources/echo-app:v2 & spinner
echo "${GREEN}Deployment created!${RESET}"
echo

# Step 6: Expose service
echo "${BLUE}${BOLD}Step 6: Exposing service...${RESET}"
kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000 & spinner
echo "${GREEN}Service exposed!${RESET}"
echo

# Step 7: Scale deployment
echo "${BLUE}${BOLD}Step 7: Scaling deployment...${RESET}"
kubectl scale deploy echo-web --replicas=2 & spinner
echo "${GREEN}Deployment scaled to 2 replicas!${RESET}"
echo

# Get service URL
echo "${BLUE}${BOLD}Getting service URL...${RESET}"
SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
while [ -z "$SERVICE_IP" ]; do
  echo "${YELLOW}Waiting for external IP...${RESET}"
  sleep 5
  SERVICE_IP=$(kubectl get service echo-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --watch=false)
done
echo "${GREEN}Your application is now available at: http://$SERVICE_IP${RESET}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Dont forget to Like, Share and Subscribe for more Videos ${RESET_FORMAT}"
