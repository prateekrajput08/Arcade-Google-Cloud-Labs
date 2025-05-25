#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Instruction for setting the zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Set the zone for your GCP resources.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}Please enter ZONE:${RESET_FORMAT}"
read -p "Zone: " ZONE
export ZONE=$ZONE

echo
echo "${GREEN_TEXT}Zone set to: ${ZONE}${RESET_FORMAT}"
echo

# Set the compute zone
gcloud config set compute/zone $ZONE

# Derive the region from the zone
export REGION=${ZONE%-*}

echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Creating a private GKE cluster...${RESET_FORMAT}"
echo "${CYAN_TEXT}This may take a few minutes.${RESET_FORMAT}"
echo

# Create a private GKE cluster
gcloud beta container clusters create private-cluster \
    --enable-private-nodes \
    --master-ipv4-cidr 172.16.0.16/28 \
    --enable-ip-alias \
    --create-subnetwork ""

echo
echo "${GREEN_TEXT}Private cluster created successfully!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Creating a source instance...${RESET_FORMAT}"
echo

# Create a source instance
gcloud compute instances create source-instance --zone=$ZONE --scopes 'https://www.googleapis.com/auth/cloud-platform'

# Get the NAT IP of the source instance
NAT_IAP=$(gcloud compute instances describe source-instance --zone=$ZONE | grep natIP | awk '{print $2}')

echo
echo "${GREEN_TEXT}Source instance created with NAT IP: ${NAT_IAP}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Updating the private cluster to allow master-authorized networks...${RESET_FORMAT}"
echo

# Update the private cluster to allow master-authorized networks
gcloud container clusters update private-cluster \
    --enable-master-authorized-networks \
    --master-authorized-networks $NAT_IAP/32

echo
echo "${GREEN_TEXT}Master-authorized networks updated successfully!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Deleting the private cluster...${RESET_FORMAT}"
echo

# Delete the private cluster
gcloud container clusters delete private-cluster --zone=$ZONE --quiet

echo
echo "${GREEN_TEXT}Private cluster deleted successfully!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Creating a custom subnet...${RESET_FORMAT}"
echo

# Create a custom subnet
gcloud compute networks subnets create my-subnet \
    --network default \
    --range 10.0.4.0/22 \
    --enable-private-ip-google-access \
    --region=$REGION \
    --secondary-range my-svc-range=10.0.32.0/20,my-pod-range=10.4.0.0/14

echo
echo "${GREEN_TEXT}Custom subnet created successfully!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Creating a second private GKE cluster...${RESET_FORMAT}"
echo

# Create a second private GKE cluster
gcloud beta container clusters create private-cluster2 \
    --enable-private-nodes \
    --enable-ip-alias \
    --master-ipv4-cidr 172.16.0.32/28 \
    --subnetwork my-subnet \
    --services-secondary-range-name my-svc-range \
    --cluster-secondary-range-name my-pod-range \
    --zone=$ZONE

echo
echo "${GREEN_TEXT}Second private cluster created successfully!${RESET_FORMAT}"
echo

# Get the NAT IP of the source instance again
NAT_IAP_Cloud=$(gcloud compute instances describe source-instance --zone=$ZONE | grep natIP | awk '{print $2}')

echo "${BLUE_TEXT}${BOLD_TEXT}Step 8: Updating the second private cluster to allow master-authorized networks...${RESET_FORMAT}"
echo

# Update the second private cluster to allow master-authorized networks
gcloud container clusters update private-cluster2 \
    --enable-master-authorized-networks \
    --zone=$ZONE \
    --master-authorized-networks $NAT_IAP_Cloud/32

echo
echo "${GREEN_TEXT}Master-authorized networks updated for the second cluster!${RESET_FORMAT}"
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
