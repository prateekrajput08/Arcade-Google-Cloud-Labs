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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo -e "${BOLD_MAGENTA}Please enter the following configuration details:${RESET_FORMAT}"
read -p "$(echo -e "${YELLOW_TEXT}ENTER LANGUAGE (e.g., en, fr, es): ${RESET_FORMAT}")" LANGUAGE
read -p "$(echo -e "${YELLOW_TEXT}ENTER LOCAL (e.g., en_US, fr_FR): ${RESET_FORMAT}")" LOCAL
read -p "$(echo -e "${YELLOW_TEXT}ENTER BIGQUERY_ROLE (e.g., roles/bigquery.admin): ${RESET_FORMAT}")" BIGQUERY_ROLE
read -p "$(echo -e "${YELLOW_TEXT}ENTER CLOUD_STORAGE_ROLE (e.g., roles/storage.admin): ${RESET_FORMAT}")" CLOUD_STORAGE_ROLE
echo ""

echo -e "${BLUE_TEXT→ Creating service account 'sample-sa'...${RESET_FORMAT}"
gcloud iam service-accounts create sample-sa
echo ""

echo -e "${BLUE_TEXT}→ Assigning IAM roles to service account...${RESET_FORMAT}"
echo -e "${_TEXT}  - BigQuery Role: ${BOLD_WHITE}$BIGQUERY_ROLE${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$BIGQUERY_ROLE

echo -e "${CYAN_TEXT}  - Cloud Storage Role: ${BOLD_WHITE}$CLOUD_STORAGE_ROLE${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$CLOUD_STORAGE_ROLE

echo -e "${CYAN_TEXT}  - Service Usage Consumer Role${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/serviceusage.serviceUsageConsumer
echo ""

echo -e "${BLUE_TEXT}→ Waiting 2 minutes for IAM changes to propagate...${RESET_FORMAT}"
for i in {1..120}; do
    echo -ne "${YELLOW_TEXT}${i}/120 seconds elapsed...\r${RESET_FORMAT}"
    sleep 1
done
echo -e "\n"

echo -e "${BLUE_TEXT}→ Creating service account key...${RESET_FORMAT}"
gcloud iam service-accounts keys create sample-sa-key.json --iam-account sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/sample-sa-key.json
echo -e "${GREEN_TEXT}Key created and exported to environment${RESET_FORMAT}"
ech

echo -e "${BLUE_TEXT}→ Downloading image analysis script...${RESET_FORMAT}"
wget https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py
echo -e "${GREEN_TEXT}Script downloaded successfully${RESET_FORMAT}"
echo ""

echo -e "${BLUE_TEXT}→ Updating script locale to ${BOLD_WHITE}${LOCAL}${BOLD_BLUE}...${RESET_FORMAT}"
sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py
echo -e "${GREEN_TEXT}Locale updated successfully${RESET_FORMAT}"
echo ""

echo -e "${BLUE_TEXT}→ Running image analysis...${RESET_FORMAT}"
python3 analyze-images-v2.py
python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID
echo -e "${GREEN_TEXT}Image analysis completed${RESET_FORMAT}"
echo ""

echo -e "${CYAN_TEXT}→ Querying locale distribution from BigQuery...${RESET_FORMAT}"
bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"
echo ""

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
