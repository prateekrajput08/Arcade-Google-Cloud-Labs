
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

echo "${YELLOW_TEXT}================= ASK USER FOR REGION =================${RESET_FORMAT}"
read "${YELLOW}${BOLD}Enter your GCP REGION (example: us-central1, asia-south1): " REGION

echo "${GREEN_TEXT}${BOLD}Using REGION: ${RESET_FORMAT}$REGION"
echo "--------------------------------------------"

echo "${YELLOW}${BOLD}================= CREATE GCS BUCKET =================${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID

echo "${YELLOW}${BOLD}================= DOWNLOAD CSV FILES =================${RESET_FORMAT}"
curl -L -o start_station_name.csv \
https://raw.githubusercontent.com/Arcade-helper/Solutions/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/start_station_name.csv

curl -L -o end_station_name.csv \
https://raw.githubusercontent.com/Arcade-helper/Solutions/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/end_station_name.csv

echo "${YELLOW}${BOLD}================= UPLOAD FILES TO GCS =================${RESET_FORMAT}"
gsutil cp start_station_name.csv gs://$DEVSHELL_PROJECT_ID/
gsutil cp end_station_name.csv gs://$DEVSHELL_PROJECT_ID/

echo "${YELLOW}${BOLD}================= CREATE CLOUD SQL INSTANCE =================${RESET_FORMAT}"
gcloud sql instances create my-demo \
    --database-version=MYSQL_8_0 \
    --region=$REGION \
    --tier=db-f1-micro \
    --root-password=arcadehelper

echo "${YELLOW}${BOLD}================= CREATE DATABASE =================${RESET_FORMAT}"
gcloud sql databases create bike --instance=my-demo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
