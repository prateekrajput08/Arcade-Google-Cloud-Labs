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
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo



gcloud auth list

gsutil mb -p $GOOGLE_CLOUD_PROJECT \
    -c standard    \
    -l us \
    gs://$GOOGLE_CLOUD_PROJECT-vcm/

export BUCKET=$GOOGLE_CLOUD_PROJECT-vcm

gsutil -m cp -r gs://spls/gsp223/images/* gs://${BUCKET}

gsutil cp gs://spls/gsp223/data.csv .

sed -i -e "s/placeholder/${BUCKET}/g" ./data.csv

gsutil cp ./data.csv gs://${BUCKET}

echo -e "\033[1;33mOpen this link\033[0m \033[1;34mhttps://console.cloud.google.com/vertex-ai/datasets?project=$DEVSHELL_PROJECT_ID\033[0m"


# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
