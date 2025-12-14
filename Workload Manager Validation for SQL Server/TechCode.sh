
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

SECRET_NAME="qwiklabs"
SECRET_VALUE="LabP@ssw0rd!"
EVALUATION_NAME="sqlserver-evaluation"
VM_NAME="qlab-win-sql01"
SQL_USER="sqluser"
SQL_PASSWORD="LabP@ssw0rd!"

PROJECT_ID=$(gcloud config get-value project)
ZONE=$(gcloud compute instances list \
  --filter="name=$VM_NAME" \
  --format="value(zone)")

echo -e "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Secret Manager secret...${RESET_FORMAT}"

if gcloud secrets describe $SECRET_NAME &>/dev/null; then
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}Secret already exists. Skipping.${RESET_FORMAT}"
else
  echo -n "$SECRET_VALUE" | \
  gcloud secrets create $SECRET_NAME \
    --replication-policy=automatic \
    --data-file=-
  echo -e "${GREEN_TEXT}${BOLD_TEXT}Secret created.${RESET_FORMAT}"
fi

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
