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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}Enter the IAP_NETWORK_TAG: ${RESET_FORMAT}" IAP_NETWORK_TAG
read -p "${YELLOW_TEXT}Enter the INTERNAL_NETWORK_TAG: ${RESET_FORMAT}" INTERNAL_NETWORK_TAG
read -p "${YELLOW_TEXT}Enter the HTTP_NETWORK_TAG: ${RESET_FORMAT}" HTTP_NETWORK_TAG


# Export variables after collecting input
export IAP_NETWORK_TAG INTERNAL_NETWORK_TAG HTTP_NETWORK_TAG

gcloud auth list


export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")


gcloud compute firewall-rules delete open-access --quiet


gcloud compute instances start bastion --zone=$ZONE --project=$DEVSHELL_PROJECT_ID


gcloud compute firewall-rules create ssh-ingress --allow=tcp:22 --source-ranges 35.235.240.0/20 --target-tags $IAP_NETWORK_TAG --network acme-vpc


gcloud compute instances add-tags bastion --tags=$IAP_NETWORK_TAG --zone=$ZONE
 

gcloud compute firewall-rules create http-ingress --allow=tcp:80 --source-ranges 0.0.0.0/0 --target-tags $HTTP_NETWORK_TAG --network acme-vpc
 

gcloud compute instances add-tags juice-shop --tags=$HTTP_NETWORK_TAG --zone=$ZONE
 

gcloud compute firewall-rules create internal-ssh-ingress --allow=tcp:22 --source-ranges 192.168.10.0/24 --target-tags $INTERNAL_NETWORK_TAG --network acme-vpc
 

gcloud compute instances add-tags juice-shop --tags=$INTERNAL_NETWORK_TAG --zone=$ZONE
 


timeout 45 gcloud compute ssh bastion --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --quiet --command="gcloud compute ssh juice-shop --zone=$ZONE --internal-ip --quiet"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
