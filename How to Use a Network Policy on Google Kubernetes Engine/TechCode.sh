#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

RESET_FORMAT=$'\033[0m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Fetching Project Configuration...${RESET_FORMAT}"
echo

gcloud config set project $(gcloud projects list \
  --format='value(PROJECT_ID)' \
  --filter='qwiklabs-gcp')

export PROJECT_ID=$(gcloud config get-value project)

export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo "${GREEN_TEXT}Project ID : ${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}Region     : ${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone       : ${ZONE}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Downloading Lab Resources...${RESET_FORMAT}"
echo

rm -rf ~/gke-network-policy-demo

gsutil cp -r gs://spls/gsp480/gke-network-policy-demo ~

cd ~/gke-network-policy-demo || exit 1

chmod -R 755 *

echo
echo "${GREEN_TEXT}Lab files downloaded successfully.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting Up Project APIs & Terraform Variables...${RESET_FORMAT}"
echo

printf "y\n" | make setup-project

sleep 15

echo
echo "${GREEN_TEXT}Project setup completed.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Provisioning Infrastructure using Terraform...${RESET_FORMAT}"
echo "${YELLOW_TEXT}This process may take several minutes...${RESET_FORMAT}"
echo

cd terraform || exit 1

terraform init

terraform apply -auto-approve

cd ..

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe${RESET_FORMAT}"
echo
rm -f TechCode.sh
