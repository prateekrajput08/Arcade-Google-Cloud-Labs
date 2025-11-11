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

# Step 1: Retrieve the default compute region
echo "${GREEN}${BOLD}Retrieving Default Compute Region${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" \
--project="$DEVSHELL_PROJECT_ID")

echo "${GREEN}Detected Region: $REGION${RESET}"

# Step 2: Monitor Apigee instance status
echo "${YELLOW}${BOLD}Monitoring Apigee Instance Status${RESET}"
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

# Step 3: Create 'bank-fullaccess' API product
echo "${MAGENTA}${BOLD}Creating 'bank-fullaccess' API Product${RESET}"
cat > bank-fullaccess.json <<EOF_END
{
  "name": "bank-fullaccess",
  "displayName": "bank (full access)",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    },
    {
      "name": "full-access",
      "value": "yes"
    }
  ],
  "description": "allows full access to bank API",
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
              "DELETE",
              "GET",
              "PATCH",
              "POST",
              "PUT"
            ]
          }
        ],
        "quota": {
          "limit": "5",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_END

# Step 4: Upload 'bank-fullaccess' configuration
echo "${BLUE}${BOLD}Uploading 'bank-fullaccess' Configuration${RESET}"
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @bank-fullaccess.json

# Check if the API product was created successfully
if [ $? -eq 0 ]; then
    echo "${GREEN}API Product 'bank-fullaccess' created successfully${RESET}"
else
    echo "${RED}Failed to create API Product 'bank-fullaccess'${RESET}"
fi

# Step 5: Create 'bank-readonly' API product
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

# Step 6: Upload 'bank-readonly' configuration
echo "${YELLOW}${BOLD}Uploading 'bank-readonly' Configuration${RESET}"
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @bank-readonly.json

# Check if the API product was created successfully
if [ $? -eq 0 ]; then
    echo "${GREEN}API Product 'bank-readonly' created successfully${RESET}"
else
    echo "${RED}Failed to create API Product 'bank-readonly'${RESET}"
fi

# Step 7: Create a developer in Apigee
echo "${CYAN}${BOLD}Creating Developer Account${RESET}"
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

# Step 8: Download OpenAPI specification
echo "${MAGENTA}${BOLD}Downloading OpenAPI Specification${RESET}"
curl -LO https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Publishing%20APIs%20with%20Apigee%20X/simplebank-spec.yaml

# Check if download was successful
if [ $? -eq 0 ]; then
    echo "${GREEN}OpenAPI specification downloaded successfully${RESET}"
else
    echo "${RED}Failed to download OpenAPI specification${RESET}"
fi

# Step 9: Update OpenAPI spec with correct URL
echo "${BLUE}${BOLD}Updating OpenAPI Specification with API URL${RESET}"
export IP_ADDRESS=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/envgroups/eval-group" | jq -r '.hostnames[1]')

if [[ -n "$IP_ADDRESS" && "$IP_ADDRESS" != "null" ]]; then
    export URL="https://eval.${IP_ADDRESS}/bank/v1"
    echo "${GREEN}API URL: $URL${RESET}"
    
    # Update the OpenAPI spec
    if [[ -f "simplebank-spec.yaml" ]]; then
        sed -i.bak 's|<URL>|'"$URL"'|g' simplebank-spec.yaml
        echo "${GREEN}OpenAPI specification updated successfully${RESET}"
        
        # Download the file
        cloudshell download simplebank-spec.yaml
    else
        echo "${RED}OpenAPI specification file not found${RESET}"
    fi
else
    echo "${RED}Failed to retrieve IP address from Apigee${RESET}"
fi

echo 

# Step 10: Display final instructions
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
