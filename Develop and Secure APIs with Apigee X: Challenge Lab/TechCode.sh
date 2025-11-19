#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

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

echo "Starting Apigee configuration..."
echo ""

# Display current project
echo "${YELLOW_TEXT}${BOLD_TEXT}Current Project Configuration:${RESET_FORMAT}"
gcloud auth list
echo ""

# Enable Translate API
echo "Enabling Translate API..."
gcloud services enable translate.googleapis.com --project=$DEVSHELL_PROJECT_ID

# Create service account
echo "Creating Apigee Proxy Service Account..."
gcloud iam service-accounts create apigee-proxy \
  --display-name "Apigee Proxy Service"

# List service accounts
echo "Available Service Accounts:"
gcloud iam service-accounts list --project=$DEVSHELL_PROJECT_ID

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo ""

# Add IAM policy binding
echo "Assigning Logging Role..."
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:apigee-proxy@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Create translate product JSON
echo "Creating Translate API Product Configuration..."
cat > translate-product.json <<EOF_CP
{
  "name": "translate-product",
  "displayName": "translate-product",
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
  "description": "API product for translation services",
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "translate-v1",
        "operations": [
          {
            "resource": "/",
            "methods": [
              "GET",
              "POST"
            ]
          }
        ],
        "quota": {
          "limit": "10",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_CP

# Create API product
echo "Creating API Product..."
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @translate-product.json

echo ""
echo "API Product created successfully!"
echo ""

# Create developer
echo "Creating Developer Account..."
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/developers" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Joe",
    "lastName": "Developer",
    "userName": "joe",  
    "email": "joe@example.com"
  }'

echo ""
echo "Developer account created successfully!"
echo ""

# Wait for instance to be active
echo "Setting up Apigee Runtime Instance..."
echo "This may take a few minutes..."
export INSTANCE_NAME=eval-instance
export ENV_NAME=eval
export PREV_INSTANCE_STATE=""

echo "Waiting for runtime instance ${INSTANCE_NAME} to be active"
while : ; do
  export INSTANCE_STATE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}" | jq "select(.state != null) | .state" --raw-output)
  [[ "${INSTANCE_STATE}" == "${PREV_INSTANCE_STATE}" ]] || (echo; echo "INSTANCE_STATE=${INSTANCE_STATE}")
  export PREV_INSTANCE_STATE=${INSTANCE_STATE}
  [[ "${INSTANCE_STATE}" != "ACTIVE" ]] || break
  echo -n "."
  sleep 5
done

echo ""
echo "Instance created, waiting for environment ${ENV_NAME} to be attached to instance"

while : ; do
  export ATTACHMENT_DONE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}/attachments" | jq "select(.attachments != null) | .attachments[] | select(.environment == \"${ENV_NAME}\") | .environment" --join-output)
  [[ "${ATTACHMENT_DONE}" != "${ENV_NAME}" ]] || break
  echo -n "."
  sleep 5
done

# Important links and information
echo "${YELLOW_TEXT}${BOLD_TEXT}Create an Apigee proxy:${RESET_FORMAT}https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"
echo "${YELLOW_TEXT}${BOLD_TEXT}Translate API Endpoint:${RESET_FORMAT}https://translation.googleapis.com/language/translate/v2"
echo "${YELLOW_TEXT}${BOLD_TEXT}Service Account Email:${RESET_FORMAT} apigee-proxy@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
