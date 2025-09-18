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


export REGION=$LOCATION

gcloud services enable healthcare.googleapis.com


bq --location=$REGION mk --dataset --description HCAPI-dataset $PROJECT_ID:$DATASET_ID

bq --location=$REGION mk --dataset --description HCAPI-dataset-de-id $PROJECT_ID:de_id


gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.dataEditor
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.jobUser


gcloud healthcare datasets create $DATASET_ID \
--location=$LOCATION


gcloud pubsub topics create fhir-topic


gcloud healthcare fhir-stores create ${FHIR_STORE_ID} --project=$DEVSHELL_PROJECT_ID --dataset=${DATASET_ID} --location=${LOCATION} --version=R4 --pubsub-topic=projects/${PROJECT_ID}/topics/${TOPIC} --enable-update-create --disable-referential-integrity


gcloud healthcare fhir-stores create de_id --project=$DEVSHELL_PROJECT_ID --dataset=${DATASET_ID} --location=${LOCATION} --version=R4 --pubsub-topic=projects/${PROJECT_ID}/topics/${TOPIC} --enable-update-create --disable-referential-integrity


gcloud healthcare fhir-stores import gcs $FHIR_STORE_ID \
--dataset=$DATASET_ID \
--location=$LOCATION \
--gcs-uri=gs://spls/gsp457/fhir_devdays_gcp/fhir1/* \
--content-structure=BUNDLE_PRETTY


gcloud healthcare fhir-stores export bq $FHIR_STORE_ID \
--dataset=$DATASET_ID \
--location=$LOCATION \
--bq-dataset=bq://$PROJECT_ID.$DATASET_ID \
--schema-type=analytics

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo ""

echo "https://console.cloud.google.com/healthcare/browser/locations/$REGION/datasets/dataset1/datastores?invt=AbuLrg&project=$DEVSHELL_PROJECT_ID"

echo ""

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
