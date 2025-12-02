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

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Function to validate zone format
validate_zone() {
  local zone=$1
  if [[ "$zone" =~ ^[a-z]+-[a-z]+[0-9]-[a-z]$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt user for zone input
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1: Set the zone for your GKE cluster${RESET_FORMAT}"
echo "${YELLOW_TEXT}Please enter your preferred zone (e.g., us-central1-a):${RESET_FORMAT}"
read -p "Zone: " ZONE

# Validate zone input
while ! validate_zone "$ZONE"; do
  echo "${RED}${BOLD_TEXT}Invalid zone format. Please enter a valid zone (e.g., us-central1-a)${RESET_FORMAT}"
  read -p "Zone: " ZONE
done

export ZONE
REGION="${ZONE%-*}"
export REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Using Zone: ${WHITE}${BOLD}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Derived Region: ${WHITE}${BOLD}$REGION${RESET_FORMAT}"
echo

# Create GKE cluster
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating GKE cluster 'echo-cluster' in zone $ZONE...${RESET_FORMAT}"
gcloud beta container --project "$DEVSHELL_PROJECT_ID" clusters create "echo-cluster" \
--zone "$ZONE" \
--no-enable-basic-auth \
--cluster-version "latest" \
--release-channel "regular" \
--machine-type "e2-standard-2" \
--image-type "COS_CONTAINERD" \
--disk-type "pd-balanced" \
--disk-size "100" \
--metadata disable-legacy-endpoints=true \
--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
--num-nodes "3" \
--logging=SYSTEM,WORKLOAD \
--monitoring=SYSTEM \
--enable-ip-alias \
--network "projects/$DEVSHELL_PROJECT_ID/global/networks/default" \
--subnetwork "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/subnetworks/default" \
--no-enable-intra-node-visibility \
--default-max-pods-per-node "110" \
--security-posture=standard \
--workload-vulnerability-scanning=disabled \
--no-enable-master-authorized-networks \
--addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
--enable-autoupgrade \
--enable-autorepair \
--max-surge-upgrade 1 \
--max-unavailable-upgrade 0 \
--enable-managed-prometheus \
--enable-shielded-nodes \
--node-locations "$ZONE"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}GKE cluster created successfully${RESET_FORMAT}"
echo

# Get project ID
export PROJECT_ID=$(gcloud info --format='value(config.project)')
echo "${YELLOW_TEXT}${BOLD_TEXT}Using Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET_FORMAT}"

# Download and extract application files
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading application files...${RESET_FORMAT}"
gsutil cp gs://${PROJECT_ID}/echo-web.tar.gz .
tar -xvzf echo-web.tar.gz

# Build and push Docker image
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Building and pushing Docker image...${RESET_FORMAT}"
cd echo-web
docker build -t echo-app:v1 .
docker tag echo-app:v1 gcr.io/${PROJECT_ID}/echo-app:v1
docker push gcr.io/${PROJECT_ID}/echo-app:v1

# Deploy to GKE
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying application to GKE cluster...${RESET_FORMAT}"
gcloud container clusters get-credentials echo-cluster --zone=$ZONE
kubectl create deployment echo-app --image=gcr.io/${PROJECT_ID}/echo-app:v1

# Expose the deployment
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating service for the deployment...${RESET_FORMAT}"
kubectl expose deployment echo-app --name echo-web \
   --type LoadBalancer --port 80 --target-port 8000

# Get service details
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting service details...${RESET_FORMAT}"
kubectl get service echo-web


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
