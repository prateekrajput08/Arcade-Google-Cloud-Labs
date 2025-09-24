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


gcloud services enable \
  dataplex.googleapis.com --project=$DEVSHELL_PROJECT_ID

gcloud dataplex lakes create ecommerce --location=$REGION --display-name="Ecommerce" --description="subscribe to techcode"

gcloud dataplex zones create orders-curated-zone --location=$REGION --lake=ecommerce --display-name="Orders Curated Zone" --resource-location-type=SINGLE_REGION --type=CURATED --discovery-enabled --discovery-schedule="0 * * * *"

bq mk --location=$REGION --dataset orders 

gcloud dataplex assets create orders-curated-dataset --location=$REGION --lake=ecommerce --zone=orders-curated-zone --display-name="Orders Curated Dataset" --resource-type=BIGQUERY_DATASET --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/orders --discovery-enabled 

gcloud dataplex assets delete orders-curated-dataset --location=$REGION --zone=orders-curated-zone --lake=ecommerce --quiet

gcloud dataplex zones delete orders-curated-zone --location=$REGION --lake=ecommerce --quiet

gcloud dataplex lakes delete ecommerce --location=$REGION --quiet 


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
