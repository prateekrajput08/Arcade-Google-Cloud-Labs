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

# Ask user for required inputs
read -p "${BOLD_TEXT}${YELLOW_TEXT}Enter REGION: ${RESET_FORMAT}" REGION

echo "${BLUE_TEXT}Region: $REGION${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Starting Execution${RESET_FORMAT}"

gcloud services enable dataplex.googleapis.com

gcloud services enable datacatalog.googleapis.com

gcloud dataplex lakes create customer-info-lake \
  --location=$REGION \
  --display-name="Customer Info Lake"

gcloud alpha dataplex zones create customer-raw-zone \
            --location=$REGION --lake=customer-info-lake \
            --resource-location-type=SINGLE_REGION --type=RAW \
            --display-name="Customer Raw Zone"

gcloud dataplex assets create customer-online-sessions --location=$REGION \
            --lake=customer-info-lake --zone=customer-raw-zone \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-bucket \
            --display-name="Customer Online Sessions"

echo "${GREEN_TEXT}${BOLD_TEXT}Click here: "${RESET_FORMAT}""${BLUE}${BOLD_TEXT}"https://console.cloud.google.com/dataplex/secure?resourceName=projects%2F$DEVSHELL_PROJECT_ID%2Flocations%2F$REGION%2Flakes%2Fcustomer-info-lake&project=$DEVSHELL_PROJECT_ID""${RESET_FORMAT}"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
