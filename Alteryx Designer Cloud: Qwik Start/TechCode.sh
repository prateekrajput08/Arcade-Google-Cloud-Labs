#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          SUBSCRIBE TECH & CODE - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Bucket...${RESET_FORMAT}"
PROJECT_ID="$(gcloud config get-value project)"
BUCKET_NAME="$(gcloud config get-value project)-bucket"

gcloud storage buckets create gs://$BUCKET_NAME \
    --location=US \

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Initializing Dataprep...${RESET_FORMAT}"

gcloud beta services identity create \
    --service=dataprep.googleapis.com

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Open the following link and complete the setup:${RESET_FORMAT}"
echo "https://console.cloud.google.com/terms/service/dataprep?project=${PROJECT_ID}&next=%2Fdataprep"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
