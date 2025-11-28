#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

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

# Step 1: Fetch the default region for resources
echo "${GREEN_TEXT}${BOLD_TEXT}Fetch the default region for resources${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Enable the IAP (Identity-Aware Proxy) service
echo "${YELLOW_TEXT}${BOLD_TEXT}Enable the IAP (Identity-Aware Proxy) service${RESET_FORMAT}"
gcloud services enable iap.googleapis.com

# Step 3: Set the project in gcloud configuration
echo "${MAGENTA_TEXT}${BOLD_TEXT}Set the project in gcloud configuration${RESET_FORMAT}"
gcloud config set project $DEVSHELL_PROJECT_ID

# Step 4: Clone the Python sample application repository
echo "${CYAN_TEXT}${BOLD_TEXT}Clone the Python sample application repository${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

# Step 5: Navigate to the hello_world directory
echo "${RED_TEXT}${BOLD_TEXT}Navigate to the hello_world directory${RESET_FORMAT}"
cd python-docs-samples/appengine/standard_python3/hello_world/

# Step 6: Create an App Engine application
echo "${BLUE_TEXT}${BOLD_TEXT}Create an App Engine application${RESET_FORMAT}"
gcloud app create --project=$(gcloud config get-value project) --region=$REGION

# Step 7: Deploy the application
echo "${MAGENTA_TEXT}${BOLD_TEXT}Deploy the application${RESET_FORMAT}"
gcloud app deploy --quiet

# Step 8: Configure the authentication domain
echo "${GREEN_TEXT}${BOLD_TEXT}Configure the authentication domain${RESET_FORMAT}"
export AUTH_DOMAIN=$(gcloud config get-value project).uc.r.appspot.com

# Step 9: Fetch the developer email and prepare details file
echo "${CYAN_TEXT}${BOLD_TEXT}Fetch the developer email and prepare details file${RESET_FORMAT}"
EMAIL="$(gcloud config get-value core/account)"

cat > details.json << EOF
  App name: drabhishek
  Authorized domains: $AUTH_DOMAIN
  Developer contact email: $EMAIL
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}Details saved in details.json:${RESET_FORMAT}"
cat details.json

# Step 10: Provide links for consent screen and IAP configuration
echo "${YELLOW_TEXT}${BOLD_TEXT}Provide links for consent screen and IAP configuration${RESET_FORMAT}"

echo -e "\n"  # Adding one blank line

echo "${WHITE_TEXT}${BOLD_TEXT}Configure the OAuth consent screen:${RESET}"
echo "${YELLOW_TEXT}${BOLD_TEXT}https://console.cloud.google.com/apis/credentials/consent?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo "${WHITE_TEXT}${BOLD_TEXT}Configure IAP:${RESET}"
echo "${YELLOW_TEXT}${BOLD_TEXT}https://console.cloud.google.com/security/iap?tab=applications&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
