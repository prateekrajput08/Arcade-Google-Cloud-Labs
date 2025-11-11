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
    echo "${RED}${BOLD}Error: DEVSHELL_PROJECT_ID is not set${RESET}"
    echo "Please run this script in Google Cloud Shell or set the DEVSHELL_PROJECT_ID variable"
    exit 1
fi

echo "${YELLOW}${BOLD}Project ID: $DEVSHELL_PROJECT_ID${RESET}"

# Step 1: Get the region information from gcloud
echo "${CYAN}${BOLD}Fetching Region Information${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" \
--project="$DEVSHELL_PROJECT_ID")

echo "${GREEN}Detected Region: $REGION${RESET}"

export INSTANCE_NAME=eval-instance

# Step 2: Wait for instance to become active
echo "${MAGENTA}${BOLD}Waiting for runtime instance ${INSTANCE_NAME} to Become Active${RESET}"
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

# Step 3: Create the 'bank-readonly' configuration file
echo "${GREEN}${BOLD}Creating 'bank-readonly' API Product${RESET}"
cat > bank-readonly.json <<EOF_END
{
  "name": "bank-readonly",
  "displayName": "bank (read-only)",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    }
  ],
  "description": "allows read-only access to bank API",
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "bank-v1",
        "operations": [
          {
            "resource": "/**",
            "methods": [
              "GET"
            ]
          }
        ],
        "quota": {}
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_END

curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @bank-readonly.json

# Check if the API product was created successfully
if [ $? -eq 0 ]; then
    echo "${GREEN}API Product 'bank-readonly' created successfully${RESET}"
else
    echo "${RED}Failed to create API Product${RESET}"
fi

# Step 4: Create a new developer
echo "${MAGENTA}${BOLD}Creating New Developer${RESET}"
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/developers" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Joe",
    "lastName": "Developer",
    "userName": "joe",  
    "email": "joe@example.com"
  }'

# Check if the developer was created successfully
if [ $? -eq 0 ]; then
    echo "${GREEN}Developer 'joe@example.com' created successfully${RESET}"
else
    echo "${RED}Failed to create developer${RESET}"
fi

echo

# Step 5: Provide final instructions
echo "${CYAN}${BOLD}Final Instructions${RESET}"
echo

echo -e "${BLUE}${BOLD}Go to this link to create an Apigee proxy: ${RESET}""https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"
echo

# Get the backend URL
BACKEND_URL=$(gcloud run services describe simplebank-rest --platform managed --region "$REGION" --format='value(status.url)' --project="$DEVSHELL_PROJECT_ID" 2>/dev/null || echo "Service not found or error retrieving URL")

echo -e "${YELLOW}${BOLD}Backend URL: ${RESET}""$BACKEND_URL"
echo
echo -e "${CYAN}${BOLD}Copy this service account: ${RESET}""apigee-internal-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"
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
