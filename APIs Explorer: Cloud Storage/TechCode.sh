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
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Creating Buckets
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Creating Cloud Storage Buckets${RESET_FORMAT}"  
gsutil mb gs://$DEVSHELL_PROJECT_ID
gsutil mb gs://$DEVSHELL_PROJECT_ID-2
echo "${GREEN_TEXT}Buckets created successfully${RESET_FORMAT}"

# Step 2: Downloading Images
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Downloading Demo Images${RESET_FORMAT}"
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image1.png
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image2.png
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image1-copy.png
echo "${SUCCESS_COLOR}Images downloaded successfully${RESET_FORMAT}"

# Step 3: Uploading Images
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Uploading Images to Cloud Storage${RESET_FORMAT}"
gsutil cp demo-image1.png gs://$DEVSHELL_PROJECT_ID/demo-image1.png
gsutil cp demo-image2.png gs://$DEVSHELL_PROJECT_ID/demo-image2.png
gsutil cp demo-image1-copy.png gs://$DEVSHELL_PROJECT_ID-2/demo-image1-copy.png
echo "${GREEN_TEXT}Files uploaded successfully${RESET_FORMAT}"

# Cleanup
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Performing Cleanup${RESET_FORMAT}"
SCRIPT_NAME="cloud-storage-lab.sh"
if [ -f "$SCRIPT_NAME" ]; then
    rm -- "$SCRIPT_NAME"
    echo "${GREEN_TEXT}Temporary files cleaned up${RESET_FORMAT}"
fi

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
