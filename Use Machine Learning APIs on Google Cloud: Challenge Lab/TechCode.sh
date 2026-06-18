#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'
clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}            SUBSCRIBE TECH & CODE- INITIATING EXECUTION...        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -e "${BOLD_MAGENTA}Please enter the following configuration details:${RESET_FORMAT}"

read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}ENTER LANGUAGE (e.g., en, fr, es): ${RESET_FORMAT}")" LANGUAGE
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}ENTER LOCAL (e.g., ja, en_US): ${RESET_FORMAT}")" LOCAL
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}ENTER BIGQUERY ROLE (roles/bigquery.admin): ${RESET_FORMAT}")" BIGQUERY_ROLE
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}ENTER CLOUD STORAGE ROLE (roles/storage.admin): ${RESET_FORMAT}")" CLOUD_STORAGE_ROLE

echo ""

SA_NAME="sample-sa"
SA_EMAIL="${SA_NAME}@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="sample-sa-key.json"
SCRIPT_NAME="analyze-images-v2.py"

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Enabling required APIs (Vision, Translate, BigQuery)...${RESET_FORMAT}"
gcloud services enable \
  vision.googleapis.com \
  translate.googleapis.com \
  bigquery.googleapis.com \
  --quiet
echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ APIs enabled${RESET_FORMAT}\n"

if gcloud iam service-accounts list --filter="email:${SA_EMAIL}" --format="value(email)" | grep -q "${SA_EMAIL}"; then
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Service account already exists: ${SA_EMAIL}${RESET_FORMAT}"
else
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Creating service account '${SA_NAME}'...${RESET_FORMAT}"
  gcloud iam service-accounts create ${SA_NAME} \
    --display-name="ML APIs Challenge Lab SA"
  echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Service account created${RESET_FORMAT}"
fi
echo ""

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Assigning IAM roles...${RESET_FORMAT}"

for ROLE in "${BIGQUERY_ROLE}" "${CLOUD_STORAGE_ROLE}" "roles/serviceusage.serviceUsageConsumer"; do
  gcloud projects add-iam-policy-binding ${DEVSHELL_PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --quiet
done

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ IAM roles assigned${RESET_FORMAT}\n"

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Waiting 2 minutes for IAM propagation...${RESET_FORMAT}"
for i in {1..120}; do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}${i}/120 seconds elapsed...\r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

if [ ! -f "${KEY_FILE}" ]; then
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Creating service account key...${RESET_FORMAT}"
  gcloud iam service-accounts keys create ${KEY_FILE} \
    --iam-account="${SA_EMAIL}"
  echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Key file created${RESET_FORMAT}"
else
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Key file already exists: ${KEY_FILE}${RESET_FORMAT}"
fi

export GOOGLE_APPLICATION_CREDENTIALS="${PWD}/${KEY_FILE}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ GOOGLE_APPLICATION_CREDENTIALS exported${RESET_FORMAT}\n"

if [ ! -f "${SCRIPT_NAME}" ]; then
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Copying analyze-images-v2.py from Cloud Storage...${RESET_FORMAT}"
  gsutil cp gs://${DEVSHELL_PROJECT_ID}/${SCRIPT_NAME} .
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Script copied successfully${RESET_FORMAT}"
else
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Script already exists: ${SCRIPT_NAME}${RESET_FORMAT}"
fi

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Downloading image analysis script...${RESET_FORMAT}"
wget https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py
echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Script downloaded successfully${RESET_FORMAT}"
echo ""

echo -e ${YELLOW_TEXT}${BOLD_TEXT}→ Updating script locale to $"${YELLOW_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py
echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Locale updated successfully${RESET_FORMAT}"
echo ""

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Running image analysis...${RESET_FORMAT}"
python3 analyze-images-v2.py
python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID
echo -e "${YELLOW_TEXT}${BOLD_TEXT}✓ Image analysis completed${RESET_FORMAT}"
echo ""

echo -e "${YELLOW_TEXT}${BOLD_TEXT}→ Querying locale distribution from BigQuery...${RESET_FORMAT}"
bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"
echo ""

echo -e "${YELLOW_TEXT}→ Verification Summary${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}Project:${RESET_FORMAT} ${DEVSHELL_PROJECT_ID}"
echo -e "${YELLOW_TEXT}Service Account:${RESET_FORMAT} ${SA_EMAIL}"
echo -e "${YELLOW_TEXT}Credentials:${RESET_FORMAT} ${GOOGLE_APPLICATION_CREDENTIALS}"
echo -e "${YELLOW_TEXT}Script:${RESET_FORMAT} ${SCRIPT_NAME}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
