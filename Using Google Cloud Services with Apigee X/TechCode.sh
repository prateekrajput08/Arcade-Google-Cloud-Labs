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

# Check if DEVSHELL_PROJECT_ID is set
if [[ -z "$DEVSHELL_PROJECT_ID" ]]; then
    echo "${RED}${BOLD_TEXT}Error: DEVSHELL_PROJECT_ID is not set${RESET_FORMAT}"
    echo "Please run this script in Google Cloud Shell or set the DEVSHELL_PROJECT_ID variable"
    exit 1
fi

echo "${YELLOW_TEXT}${BOLD}Project ID: $DEVSHELL_PROJECT_ID${RESET_FORMAT}"

# Step 1: Enable required Google Cloud services
echo "${YELLOW}${BOLD}Enabling Required Google Cloud Services${RESET}"
gcloud services enable language.googleapis.com pubsub.googleapis.com logging.googleapis.com

# Step 2: Create a service account for Apigee access
echo "${CYAN}${BOLD}Creating Apigee Service Account${RESET}"
gcloud iam service-accounts create apigee-gc-service-access \
  --display-name "Apigee GC Service Access" \
  --project="$DEVSHELL_PROJECT_ID"

sleep 15

# Step 3: Assign Pub/Sub publisher role to the service account
echo "${MAGENTA}${BOLD}Assigning Pub/Sub Publisher Role${RESET}"
gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
  --member="serviceAccount:apigee-gc-service-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"

# Step 4: Assign Logging Writer role to the service account
echo "${BLUE}${BOLD}Assigning Logging Writer Role${RESET}"
gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
  --member="serviceAccount:apigee-gc-service-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Step 5: Monitor Apigee instance status
echo "${GREEN}${BOLD}Monitoring Apigee Instance Status${RESET}"
export INSTANCE_NAME=eval-instance
export ENV_NAME=eval
export PREV_INSTANCE_STATE=""
echo "Waiting for runtime instance ${INSTANCE_NAME} to be active"

while : ; do
    export INSTANCE_STATE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}" | \
        jq -r "select(.state != null) | .state")
    
    [[ "${INSTANCE_STATE}" == "${PREV_INSTANCE_STATE}" ]] || (echo; echo "INSTANCE_STATE=${INSTANCE_STATE}")
    export PREV_INSTANCE_STATE=${INSTANCE_STATE}
    
    [[ "${INSTANCE_STATE}" != "ACTIVE" ]] || break
    echo -n "."
    sleep 5
done

echo
echo "Instance created, waiting for environment ${ENV_NAME} to be attached to instance"

while : ; do
    export ATTACHMENT_DONE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}/attachments" | \
        jq -r "select(.attachments != null) | .attachments[] | select(.environment == \"${ENV_NAME}\") | .environment")
    
    [[ "${ATTACHMENT_DONE}" != "${ENV_NAME}" ]] || break
    echo -n "."
    sleep 5
done

echo "***ORG IS READY TO USE***"

# Step 6: Create a Pub/Sub topic
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Pub/Sub Topic: apigee-services-v1-delivery-reviews${RESET_FORMAT}"
gcloud pubsub topics create apigee-services-v1-delivery-reviews --project="$DEVSHELL_PROJECT_ID"
echo
# Step 7: Display final instructions
echo "${YELLOW_TEXT}${BOLD_TEXT}Final Instructions${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Go to this link to create an Apigee proxy: ${RESET_FORMAT}""https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Copy this service account: ${RESET_FORMAT}""apigee-gc-service-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"
echo

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
