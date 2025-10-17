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
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute instances list alloydb-client --format 'csv[no-heading](zone)')

export REGION="${ZONE%-*}"

gcloud beta alloydb clusters create lab-cluster \
    --password=Change3Me \
    --network=peering-network \
    --region=$REGION \
    --project=$DEVSHELL_PROJECT_ID

gcloud beta alloydb instances create lab-instance \
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region=$REGION  \
    --cluster=lab-cluster \
    --project=$DEVSHELL_PROJECT_ID

gcloud alloydb instances create lab-instance-rp1 \
  --cluster=lab-cluster \
  --region=$REGION \
  --instance-type=READ_POOL \
  --cpu-count=2 \
  --read-pool-node-count=2

gcloud beta alloydb backups create lab-backup --region=$REGION  --cluster=lab-cluster

gcloud compute ssh alloydb-client --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
