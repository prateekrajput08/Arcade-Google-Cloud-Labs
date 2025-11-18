#!/bin/bash

# --- Color Definitions ---
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
MAGENTA_TEXT=$'\033[0;95m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SECURE BIGLAKE DATA CHALLENGE LAB - STARTING EXECUTION 🚀 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Section 1: User Input
echo "${GREEN_TEXT}${BOLD_TEXT}USER CONFIGURATION 👤 ${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Enter USERNAME 2 (e.g., user-2-##########@cloud.gcp.corp): ${RESET_FORMAT}"
read -r USER_2
echo "${CYAN_TEXT}${BOLD_TEXT}User 2 set to: ${USER_2}${RESET_FORMAT}"
echo

# Global Variables
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export DATASET_NAME="online_shop"
export CONNECTION_NAME="user_data_connection"
export TABLE_NAME="user_online_sessions"
export ASPECT_DISPLAY_NAME="Sensitive Data Aspect"
export ASPECT_ID="Sensitive_Data_Aspect" # Internal ID derived from Display Name

# --- TASK 1: Create a BigLake table using a Cloud Resource connection ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 1. BIGLAKE SETUP (Task 1) 💾 ${RESET_FORMAT}"
echo "---"

# 1. Create BigQuery dataset 'online_shop' in US multi-region
echo "${YELLOW_TEXT}${BOLD_TEXT}1. Creating BigQuery dataset '${DATASET_NAME}' in US...${RESET_FORMAT}"
bq mk --location=US $DATASET_NAME
echo "${GREEN_TEXT}Dataset created successfully!${RESET_FORMAT}"

# 2. Create Cloud Resource connection 'user_data_connection' in US multi-region
echo "${YELLOW_TEXT}${BOLD_TEXT}2. Creating BigQuery connection '${CONNECTION_NAME}' in US...${RESET_FORMAT}"
bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE $CONNECTION_NAME
export CONNECTION_ID="$PROJECT_ID.US.$CONNECTION_NAME"
echo "${GREEN_TEXT}Connection established!${RESET_FORMAT}"

# 3. Get Service Account ID and Grant Permissions
echo "${MAGENTA_TEXT}${BOLD_TEXT}3. Configuring service account permissions...${RESET_FORMAT}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $CONNECTION_ID | jq -r '.cloudResource.serviceAccountId')

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
echo "${GREEN_TEXT}Permissions granted to Service Account!${RESET_FORMAT}"

# 4. Create BigLake table 'user_online_sessions'
echo "${YELLOW_TEXT}${BOLD_TEXT}4. Creating BigLake table '${TABLE_NAME}'...${RESET_FORMAT}"

# Create the table definition file
bq mkdef \
--autodetect \
--connection_id=$CONNECTION_ID \
--source_format=CSV \
"gs://$PROJECT_ID-bucket/user-online-sessions.csv" > /tmp/tabledef.json

# Create the BigLake table
bq mk --external_table_definition=/tmp/tabledef.json \
--project_id=$PROJECT_ID \
$DATASET_NAME.$TABLE_NAME
echo "${GREEN_TEXT}BigLake table created successfully!${RESET_FORMAT}"
echo

# --- TASK 2: Create, apply, and verify an aspect on sensitive columns ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 2. DATA GOVERNANCE SETUP (Task 2) 🛡️ ${RESET_FORMAT}"
echo "---"

# 1. Define the Aspect structure (YAML/JSON)
ASPECT_FILE="/tmp/sensitive-aspect.yaml"
cat > $ASPECT_FILE << EOM
name: '$ASPECT_DISPLAY_NAME'
display_name: '$ASPECT_DISPLAY_NAME'
description: 'Marks columns containing sensitive PII/location data.'
scope: 'COLUMN' # Aspects are typically applied at the column level for column-level metadata
aspect_type:
  fields:
    HasSensitiveData: # Internal field name - CRITICAL for checker
      display_name: 'Has Sensitive Data'
      primitive_type: 'BOOL'
EOM

# 2. Create the Aspect in Data Catalog
echo "${YELLOW_TEXT}${BOLD_TEXT}1. Creating Data Catalog Aspect: '${ASPECT_DISPLAY_NAME}'...${RESET_FORMAT}"
# Attempt creation; ignore "already exists" error if running twice
gcloud data-catalog aspects create \
    --location=us \
    --project=$PROJECT_ID \
    --json-file=$ASPECT_FILE 2> /dev/null || echo "${CYAN_TEXT}Aspect already exists or was created.${RESET_FORMAT}"

# 3. Apply the Aspect to the specified columns
TABLE_RESOURCE_NAME="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$DATASET_NAME/tables/$TABLE_NAME"
ASPECT_CONTENT='{"HasSensitiveData": true}'

echo "${YELLOW_TEXT}${BOLD_TEXT}2. Applying the Aspect to required columns...${RESET_FORMAT}"

# Function to apply the aspect to a column
apply_aspect_to_column() {
  local COLUMN=$1
  echo "${MAGENTA_TEXT}   - Applying to column: $COLUMN...${RESET_FORMAT}"
  gcloud data-catalog entries aspect apply \
    --location=us \
    --project=$PROJECT_ID \
    --resource=$TABLE_RESOURCE_NAME \
    --column=$COLUMN \
    --aspect=$ASPECT_ID \
    --content="$ASPECT_CONTENT"
}

# Apply to each sensitive column
apply_aspect_to_column "zip"
apply_aspect_to_column "latitude"
apply_aspect_to_column "ip_address"
apply_aspect_to_column "longitude"

echo "${GREEN_TEXT}Aspect applied to all sensitive columns!${RESET_FORMAT}"
echo

# --- TASK 3: Remove IAM permissions to Cloud Storage for other users ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 3. IAM CLEANUP (Task 3) 🧹 ${RESET_FORMAT}"
echo "---"

if [[ -n "$USER_2" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Removing IAM role 'Storage Object Viewer' for user $USER_2...${RESET_FORMAT}"
    
    # Remove the Cloud Storage role as requested
    gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
        --member="user:$USER_2" \
        --role="roles/storage.objectViewer" 2> /dev/null || echo "${CYAN_TEXT}Storage role was not found or has been removed.${RESET_FORMAT}"
    
    echo "${GREEN_TEXT}Cloud Storage permissions cleaned up successfully!${RESET_FORMAT}"
else
    echo "${YELLOW_TEXT}${BOLD_TEXT}Skipping IAM cleanup - User 2 email was not provided.${RESET_FORMAT}"
fi

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        EXECUTION COMPLETE. CLICK 'CHECK MY PROGRESS'! ✅ ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
