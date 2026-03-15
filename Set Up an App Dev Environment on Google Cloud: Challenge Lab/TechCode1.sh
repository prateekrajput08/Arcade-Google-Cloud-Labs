#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter required values:${RESET_FORMAT}"

echo read -p "${YELLOW_TEXT}Enter User Email to Remove (USER_2): ${WHITE_TEXT}${BOLD_TEXT}" 
USER_2 echo -e "${RESET_FORMAT}" read -p "${YELLOW_TEXT}Enter Zone (e.g. us-central1-a): ${WHITE_TEXT}${BOLD_TEXT}" 
ZONE echo -e "${RESET_FORMAT}" read -p "${YELLOW_TEXT}Enter Pub/Sub Topic Name (TOPIC): ${WHITE_TEXT}${BOLD_TEXT}" 
TOPIC echo -e "${RESET_FORMAT}" read -p "${YELLOW_TEXT}Enter Cloud Function Name (FUNCTION): ${WHITE_TEXT}${BOLD_TEXT}" 
FUNCTION echo -e "${RESET_FORMAT}" 

export USER_2 
export ZONE 
export TOPIC 
export FUNCTION 
# Compute region from zone 
export REGION="${ZONE%-*}" 

# =============================== # SERVICES ENABLE # =============================== 
gcloud services enable \ 
  artifactregistry.googleapis.com \ 
  cloudfunctions.googleapis.com \ 
  cloudbuild.googleapis.com \ 
  eventarc.googleapis.com \ 
  run.googleapis.com \ 
  logging.googleapis.com \ 
  pubsub.googleapis.com 
  
sleep 90
  
PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)') 
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \ 
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \ 
  --role=roles/eventarc.eventReceiver 
  
sleep 20 

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $DEVSHELL_PROJECT_ID)" 
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \ 
  --member="serviceAccount:${SERVICE_ACCOUNT}" \ 
  --role='roles/pubsub.publisher' 

sleep 20 

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \ 
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \ 
  --role=roles/iam.serviceAccountTokenCreator 
  
sleep 20 

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket 
gcloud pubsub topics create $TOPIC


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                   RUN SECOND COMMAND                  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
