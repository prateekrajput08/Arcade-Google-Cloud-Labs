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

# ========================= PROJECT INFO =========================
PROJECT_ID=$(gcloud config get-value project)

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

REGION=${ZONE%-*}
AUTH_DOMAIN="${PROJECT_ID}.uc.r.appspot.com"

echo "${YELLOW_TEXT}Project ID : ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Zone       : ${WHITE_TEXT}${ZONE}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Region     : ${WHITE_TEXT}${REGION}${RESET_FORMAT}"
echo "${YELLOW_TEXT}AuthDomain : ${WHITE_TEXT}${AUTH_DOMAIN}${RESET_FORMAT}"
echo "${CYAN_TEXT}----------------------------------------------------${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}========================= CLONE REPO =========================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Cloning lab repository...${RESET_FORMAT}"
cd ~
rm -rf user-authentication-with-iap
git clone https://github.com/googlecodelabs/user-authentication-with-iap.git
cd user-authentication-with-iap

# ========================= TASK 1 =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Task 1 – Deploy HelloWorld App${RESET_FORMAT}"

cd 1-HelloWorld

sed -i 's/runtime: python38/runtime: python310/' app.yaml

echo "${TEAL_TEXT}Creating App Engine application...${RESET_FORMAT}"
gcloud app create --region=$REGION || true

echo "${TEAL_TEXT}Deploying application...${RESET_FORMAT}"
gcloud app deploy --quiet

echo "${GREEN_TEXT}${BOLD_TEXT}Task 1 Deployment Complete${RESET_FORMAT}"
gcloud app browse

cd ..

# ========================= MANUAL IAP STEPS =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}⚠️  MANUAL STEPS REQUIRED – DO NOT SKIP${RESET_FORMAT}"
echo "${WHITE_TEXT}1. Enable Identity-Aware Proxy API${RESET_FORMAT}"
echo "${WHITE_TEXT}2. OAuth Consent Screen → Internal${RESET_FORMAT}"
echo "${WHITE_TEXT}3. Create OAuth Client → Web App${RESET_FORMAT}"
echo "${WHITE_TEXT}4. Authorized Redirect URI:${RESET_FORMAT}"
echo "${GOLD_TEXT}   https://${AUTH_DOMAIN}/_gcp_iap/handleRedirect${RESET_FORMAT}"
echo "${WHITE_TEXT}5. Enable IAP for App Engine${RESET_FORMAT}"
echo "${WHITE_TEXT}6. Add User → IAP-secured Web App User${RESET_FORMAT}"
echo "${CYAN_TEXT}----------------------------------------------------${RESET_FORMAT}"
read -p "$(echo -e "${BLINK_TEXT}${YELLOW_TEXT}Press ENTER after completing ALL steps...${RESET_FORMAT}")"

# ========================= TASK 2 =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Task 2 – Deploy HelloUser App${RESET_FORMAT}"

cd 2-HelloUser

sed -i 's/runtime: python38/runtime: python310/' app.yaml

echo "${TEAL_TEXT}Deploying updated app...${RESET_FORMAT}"
gcloud app deploy --quiet

echo "${GREEN_TEXT}${BOLD_TEXT}Task 2 Deployment Complete${RESET_FORMAT}"
gcloud app browse

# ========================= FINISH =========================
echo "${YELLOW_TEXT}If access denied persists, clear IAP cookie:${RESET_FORMAT}"
echo "${GOLD_TEXT}https://${AUTH_DOMAIN}/_gcp_iap/clear_login_cookie${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
