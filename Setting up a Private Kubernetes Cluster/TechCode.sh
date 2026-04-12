#!/bin/bash

# Color Configuration
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
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


# Get Zone and determine Region
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Please enter the Zone (e.g., us-central1-a):${RESET_FORMAT}"
read ZONE
REGION="${ZONE%-*}"

echo -e "${CYAN_TEXT}Setting zone to $ZONE and region to $REGION...${RESET_FORMAT}"
gcloud config set compute/zone "$ZONE" --quiet

# Task 2: Create a private cluster
echo -e "${GREEN_TEXT}${BOLD_TEXT}Task 2: Creating the first private cluster (private-cluster)...${RESET_FORMAT}"
gcloud beta container clusters create private-cluster \
    --enable-private-nodes \
    --master-ipv4-cidr 172.16.0.16/28 \
    --enable-ip-alias \
    --create-subnetwork "" \
    --zone "$ZONE" \
    --quiet

# Task 4: Enable master authorized networks
echo -e "${TEAL_TEXT}${BOLD_TEXT}Task 4: Creating source-instance VM to test connectivity...${RESET_FORMAT}"
gcloud compute instances create source-instance \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --scopes 'https://www.googleapis.com/auth/cloud-platform' \
    --quiet

echo -e "${MAGENTA_TEXT}Fetching the NAT IP of source-instance...${RESET_FORMAT}"
NAT_IP=$(gcloud compute instances describe source-instance \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo -e "${BLUE_TEXT}Source Instance NAT IP: ${NAT_IP}${RESET_FORMAT}"

echo -e "${PURPLE_TEXT}Authorizing external address range for private-cluster...${RESET_FORMAT}"
gcloud container clusters update private-cluster \
    --enable-master-authorized-networks \
    --master-authorized-networks "${NAT_IP}/32" \
    --zone "$ZONE" \
    --quiet

# Task 5: Clean Up
echo -e "${RED_TEXT}${BOLD_TEXT}Task 5: Deleting the private-cluster...${RESET_FORMAT}"
gcloud container clusters delete private-cluster --zone="$ZONE" --quiet

# Task 6: Create a private cluster that uses a custom subnetwork
echo -e "${GOLD_TEXT}${BOLD_TEXT}Task 6: Creating custom subnetwork (my-subnet)...${RESET_FORMAT}"
gcloud compute networks subnets create my-subnet \
    --network default \
    --range 10.0.4.0/22 \
    --enable-private-ip-google-access \
    --region="$REGION" \
    --secondary-range my-svc-range=10.0.32.0/20,my-pod-range=10.4.0.0/14 \
    --quiet

echo -e "${GREEN_TEXT}${BOLD_TEXT}Creating private-cluster2 using the custom subnetwork...${RESET_FORMAT}"
gcloud beta container clusters create private-cluster2 \
    --enable-private-nodes \
    --enable-ip-alias \
    --master-ipv4-cidr 172.16.0.32/28 \
    --subnetwork my-subnet \
    --services-secondary-range-name my-svc-range \
    --cluster-secondary-range-name my-pod-range \
    --zone="$ZONE" \
    --quiet

echo -e "${PURPLE_TEXT}Authorizing external address range for private-cluster2...${RESET_FORMAT}"
gcloud container clusters update private-cluster2 \
    --enable-master-authorized-networks \
    --master-authorized-networks "${NAT_IP}/32" \
    --zone="$ZONE" \
    --quiet

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
