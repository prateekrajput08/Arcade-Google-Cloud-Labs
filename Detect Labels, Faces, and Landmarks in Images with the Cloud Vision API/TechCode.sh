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

# API Key Creation
echo "${BLUE_TEXT}${BOLD}STEP 1: Creating API Key...${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="vision-api-key" || {
    echo "${RED_TEXT}${BOLD}Error: Failed to create API key${RESET_FORMAT}"
    exit 1
}

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-api-key")
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN_TEXT}${BOLD}Success: ${YELLOW_TEXT}API Key created${RESET_FORMAT}"
echo "${WHITE_TEXT}Key: ${CYAN}$API_KEY${RESET_FORMAT}"
echo ""

# Storage Setup
echo "${BLUE_TEXT}${BOLD}STEP 2: Creating Cloud Storage Bucket...${RESET_FORMAT}"
gsutil mb gs://$PROJECT_ID-vision-lab || {
    echo "${RED_TEXT}${BOLD}Error: Bucket creation failed${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD}Success: ${YELLOW_TEXT}Bucket gs://$PROJECT_ID-vision-lab ready${RESET_FORMAT}"
echo ""

# Image Processing
echo "${BLUE_TEXT}${BOLD}STEP 3: Downloading Sample Images...${RESET_FORMAT}"
declare -a IMAGE_FILES=(
    "city.png"
    "donuts.png" 
    "selfie.png"
)

for IMAGE in "${IMAGE_FILES[@]}"; do
    echo "${WHITE_TEXT}Downloading $IMAGE...${RESET_FORMAT}"
    curl -LO "https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-vision/main/samples/$IMAGE" || {
        echo "${RED_TEXT}${BOLD}Download failed for $IMAGE${RESET_FORMAT}"
        continue
    }
    gsutil cp $IMAGE gs://$PROJECT_ID-vision-lab/
    gsutil acl ch -u AllUsers:R gs://$PROJECT_ID-vision-lab/$IMAGE
    echo "${GREEN_TEXT}Uploaded: ${CYAN_TEXT}$IMAGE${RESET_FORMAT}"
done
echo ""


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
