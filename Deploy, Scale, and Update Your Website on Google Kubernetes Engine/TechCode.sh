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

# Step 1: List authenticated accounts
echo -e "${YELLOW_TEXT}[Step 1] Checking authenticated accounts...${RESET_FORMAT}"
gcloud auth list
echo -e "\n"

# Step 2: Set compute zone
echo -e "${YELLOW_TEXT}[Step 2] Setting compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set compute/zone $ZONE
echo -e "${GREEN_TEXT}Zone set to: $ZONE${RESET_FORMAT}"
echo -e "\n"

# Step 3: Enable container API
echo -e "${YELLOW_TEXT}[Step 3] Enabling container API...${RESET_FORMAT}"
gcloud services enable container.googleapis.com
echo -e "\n"

# Step 4: Create GKE cluster
echo -e "${YELLOW_TEXT}[Step 4] Creating GKE cluster...${RESET_FORMAT}"
gcloud container clusters create fancy-cluster --num-nodes 3
echo -e "\n"

# Step 5: List instances
echo -e "${YELLOW_TEXT}[Step 5] Listing compute instances...${RESET_FORMAT}"
gcloud compute instances list
echo -e "\n"

# Step 6: Clone repository
echo -e "${YELLOW_TEXT}[Step 6] Cloning monolith-to-microservices repository...${RESET_FORMAT}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
echo -e "\n"

# Step 7: Run setup script
echo -e "${YELLOW_TEXT}[Step 7] Running setup script...${RESET_FORMAT}"
cd ~/monolith-to-microservices
./setup.sh
echo -e "\n"

# Step 8: Install Node.js LTS
echo -e "${YELLOW_TEXT}[Step 8] Installing Node.js LTS...${RESET_FORMAT}"
nvm install --lts
echo -e "\n"

# Step 9: Enable Cloud Build API
echo -e "${YELLOW_TEXT}[Step 9] Enabling Cloud Build API...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com
echo -e "\n"

# Step 10: Build and deploy monolith
echo -e "${YELLOW_TEXT}[Step 10] Building and deploying monolith...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:1.0.0 .
kubectl create deployment monolith --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:1.0.0
echo -e "\n"

# Step 11: Verify deployment
echo -e "${YELLOW_TEXT}[Step 11] Verifying deployment...${RESET_FORMAT}"
kubectl get all
echo -e "\n"

# Step 12: Expose service
echo -e "${YELLOW_TEXT}[Step 12] Exposing monolith service...${RESET_FORMAT}"
kubectl expose deployment monolith --type=LoadBalancer --port 80 --target-port 8080
kubectl get service
echo -e "\n"

# Step 13: Scale deployment
echo -e "${YELLOW_TEXT}[Step 13] Scaling deployment...${RESET_FORMAT}"
kubectl scale deployment monolith --replicas=3
kubectl get all
echo -e "\n"

# Step 14: Update React app
echo -e "${YELLOW_TEXT}[Step 14] Updating React app...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js
echo -e "\n"

# Step 15: Build React app
echo -e "${YELLOW_TEXT}[Step 15] Building React app...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
npm run build:monolith
echo -e "\n"

# Step 16: Update monolith image
echo -e "${YELLOW_TEXT}[Step 16] Updating monolith image...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0
kubectl get pods
echo -e "\n"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
