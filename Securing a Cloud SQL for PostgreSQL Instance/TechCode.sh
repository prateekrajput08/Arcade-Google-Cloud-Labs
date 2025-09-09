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
BOLD=`tput bold`
RESET=`tput sgr0`
clear


# Welcome message
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

#!/bin/bash

set -euo pipefail

# === CONFIG ===
CLOUDSQL_INSTANCE="postgres-orders"
DB_VERSION="POSTGRES_13"
DB_ROOT_PASSWORD="supersecret!"
KMS_KEYRING_ID="cloud-sql-keyring"
KMS_KEY_ID="cloud-sql-key"
SQL_SERVICE="sqladmin.googleapis.com"

echo "${MAGENTA_TEXT}${BOLD}Starting Cloud SQL with CMEK automation...${COLOR_RESET}"

# Get the current project
PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# Enable the Cloud SQL Admin API if not already enabled
echo "${MAGENTA_TEXT}${BOLD}Enabling Cloud SQL Admin API...${COLOR_RESET}"
gcloud services enable $SQL_SERVICE

# Create the Cloud SQL service account for CMEK
echo "${MAGENTA_TEXT}${BOLD}Creating Cloud SQL service account identity...${COLOR_RESET}"
gcloud beta services identity create \
  --service=$SQL_SERVICE \
  --project=$PROJECT_ID

# Get ZONE and REGION based on bastion-vm
echo "${MAGENTA_TEXT}${BOLD}Fetching bastion-vm zone and region...${COLOR_RESET}"
ZONE=$(gcloud compute instances list --filter="NAME=bastion-vm" --format=json | jq -r '.[0].zone' | awk -F "/zones/" '{print $NF}')
REGION=${ZONE::-2}
echo "Zone: $ZONE | Region: $REGION"

# Create KMS keyring
echo "${MAGENTA_TEXT}${BOLD}Creating KMS keyring...${COLOR_RESET}"
gcloud kms keyrings create $KMS_KEYRING_ID --location=$REGION || echo "⚠️ Keyring may already exist."

# Create KMS key
echo "${MAGENTA_TEXT}${BOLD}Creating KMS key...${COLOR_RESET}"
gcloud kms keys create $KMS_KEY_ID \
  --location=$REGION \
  --keyring=$KMS_KEYRING_ID \
  --purpose=encryption || echo "⚠️ Key may already exist."

# Bind KMS key to SQL service account
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format 'value(projectNumber)')
echo "${MAGENTA_TEXT}${BOLD}Binding key to service account...${COLOR_RESET}"
gcloud kms keys add-iam-policy-binding $KMS_KEY_ID \
  --location=$REGION \
  --keyring=$KMS_KEYRING_ID \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloud-sql.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Get external IPs
echo "${MAGENTA_TEXT}${BOLD}Getting external IPs...${COLOR_RESET}"
AUTHORIZED_IP=$(gcloud compute instances describe bastion-vm --zone=$ZONE --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
CLOUD_SHELL_IP=$(curl -s ifconfig.me)
echo "Bastion IP: $AUTHORIZED_IP"
echo "Cloud Shell IP: $CLOUD_SHELL_IP"

# Get KMS key full resource name
KEY_NAME=$(gcloud kms keys describe $KMS_KEY_ID \
    --keyring=$KMS_KEYRING_ID --location=$REGION \
    --format='value(name)')

# Create Cloud SQL instance with CMEK enabled
echo "${MAGENTA_TEXT}${BOLD}Creating Cloud SQL instance with CMEK...${COLOR_RESET}"
gcloud sql instances create $CLOUDSQL_INSTANCE \
    --project=$PROJECT_ID \
    --authorized-networks=${AUTHORIZED_IP}/32,${CLOUD_SHELL_IP}/32 \
    --disk-encryption-key=$KEY_NAME \
    --database-version=$DB_VERSION \
    --cpu=1 \
    --memory=3840MB \
    --region=$REGION \
    --root-password=$DB_ROOT_PASSWORD

echo "${MAGENTA_TEXT}${BOLD}Cloud SQL instance created."

# Task 2: Enable pgAudit
echo "${MAGENTA_TEXT}${BOLD}Enabling pgAudit on the SQL instance...${COLOR_RESET}"
gcloud sql instances patch $CLOUDSQL_INSTANCE \
    --database-flags=cloudsql.enable_pgaudit=on,pgaudit.log=all

echo "pgAudit enabled."

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
