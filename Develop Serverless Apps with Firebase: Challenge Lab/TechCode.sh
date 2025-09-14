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



gcloud auth list

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export DATASET_SERVICE=netflix-dataset-service

export FRONTEND_STAGING_SERVICE=frontend-staging-service

export FRONTEND_PRODUCTION_SERVICE=frontend-production-service

gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

gcloud firestore databases create --location=$REGION --project=$DEVSHELL_PROJECT_ID

sleep 10

gcloud services enable run.googleapis.com

git clone https://github.com/rosera/pet-theory.git

cd pet-theory/lab06/firebase-import-csv/solution

npm install
node index.js netflix_titles_original.csv

cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install
cd ~/pet-theory/lab06/firebase-rest-api/solution-01

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.1 .

gcloud run deploy $DATASET_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.1 --allow-unauthenticated --max-instances=1 --region=$REGION 

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE --region=$REGION --format 'value(status.url)')

curl -X GET $SERVICE_URL

cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install
cd ~/pet-theory/lab06/firebase-rest-api/solution-02

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.2 .

gcloud run deploy $DATASET_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.2 --region=$REGION --allow-unauthenticated --max-instances=1

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE --region=$REGION --format 'value(status.url)')

curl -X GET $SERVICE_URL/2019

npm install && npm run build

cd ~/pet-theory/lab06/firebase-frontend

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1 .

gcloud run deploy $FRONTEND_STAGING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1 --platform managed --region=$REGION --max-instances 1 --allow-unauthenticated --quiet

gcloud run services describe $FRONTEND_STAGING_SERVICE --region=$REGION --format="value(status.url)"

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-production:0.1
gcloud run deploy $FRONTEND_PRODUCTION_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-production:0.1 --platform managed --region=$REGION --max-instances=1 --quiet


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
