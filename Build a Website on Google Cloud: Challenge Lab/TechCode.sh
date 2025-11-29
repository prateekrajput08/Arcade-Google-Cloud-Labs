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

# Get user input for required variables
echo "${PINK_TEXT}${BOLD_TEXT}Please provide the following configuration values:${RESET_FORMAT}"
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter your zone (e.g., us-central1-a): ${RESET_FORMAT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter monolith identifier (e.g., monolith): ${RESET_FORMAT}" MON_IDENT
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter cluster name (e.g., fancy-cluster): ${RESET_FORMAT}" CLUSTER
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter orders service identifier (e.g., orders): ${RESET_FORMAT}" ORD_IDENT
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter products service identifier (e.g., products): ${RESET_FORMAT}" PROD_IDENT
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter frontend identifier (e.g., frontend): ${RESET_FORMAT}" FRONT_IDENT

# Export variables
export ZONE
export MON_IDENT
export CLUSTER
export ORD_IDENT
export PROD_IDENT
export FRONT_IDENT
export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${GREEN_TEXT}Configuration set:${RESET_FORMAT}"
echo "Zone: $ZONE"
echo "Monolith: $MON_IDENT"
echo "Cluster: $CLUSTER"
echo "Orders: $ORD_IDENT"
echo "Products: $PROD_IDENT"
echo "Frontend: $FRONT_IDENT"
echo "Project: $PROJECT_ID"
echo

# Initialize project settings
echo "${CYAN_TEXT}${BOLD_TEXT}Configuring Project Settings${RESET_FORMAT}"
gcloud config set compute/zone $ZONE
gcloud services enable cloudbuild.googleapis.com container.googleapis.com
echo "${GREEN_TEXT}Project configuration completed${RESET_FORMAT}"
echo

# Clone repository and setup
echo "${CYAN_TEXT}${BOLD_TEXT}Setting Up Application${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh
echo "${GREEN_TEXT}Application setup completed${RESET_FORMAT}"
echo

# Build and deploy monolith
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying Monolith Application${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/${MON_IDENT}:1.0.0 .
gcloud container clusters create $CLUSTER --num-nodes 3
kubectl create deployment $MON_IDENT --image=gcr.io/${PROJECT_ID}/$MON_IDENT:1.0.0
kubectl expose deployment $MON_IDENT --type=LoadBalancer --port 80 --target-port 8080
echo "${GREEN_TEXT}Monolith deployed${RESET_FORMAT}"
echo

# Build and deploy microservices
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying Microservices${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$ORD_IDENT:1.0.0 .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$PROD_IDENT:1.0.0 .

kubectl create deployment $ORD_IDENT --image=gcr.io/${PROJECT_ID}/$ORD_IDENT:1.0.0
kubectl expose deployment $ORD_IDENT --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PROD_IDENT --image=gcr.io/${PROJECT_ID}/$PROD_IDENT:1.0.0
kubectl expose deployment $PROD_IDENT --type=LoadBalancer --port 80 --target-port 8082
echo "${GREEN_TEXT}Microservices deployed${RESET}"
echo

# Deploy frontend
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying Frontend Service${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$FRONT_IDENT:1.0.0 .
kubectl create deployment $FRONT_IDENT --image=gcr.io/${PROJECT_ID}/$FRONT_IDENT:1.0.0
kubectl expose deployment $FRONT_IDENT --type=LoadBalancer --port 80 --target-port 8080
echo "${GREEN_TEXT}Frontend deployed${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
