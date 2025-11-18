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
echo "${CYAN_TEXT}${BOLD_TEXT}      SECURE BIGLAKE DATA CHALLENGE LAB - INITIATING...   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Section 1: User Input
echo "${GREEN_TEXT}${BOLD_TEXT}USER CONFIGURATION ⚙️ ${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Enter USERNAME 2 (e.g., user-2-##########@cloud.gcp.corp): ${RESET_FORMAT}"
read -r USER_2
echo "${CYAN_TEXT}${BOLD_TEXT}User input received: ${USER_2}${RESET_FORMAT}"
echo

# Automatically get Project ID from the environment
export PROJECT_ID=$DEVSHELL_PROJECT_ID

# --- TASK 1: Create a BigLake table using a Cloud Resource connection ---
echo "${GREEN_TEXT}${BOLD_TEXT}TASK 1: BIGLAKE SETUP 💾 ${RESET_FORMAT}"

# 1. Create BigQuery dataset 'online_shop' in US multi-region
echo "${YELLOW_TEXT}${BOLD_TEXT}1. Creating BigQuery dataset 'online_shop' in US...${RESET_FORMAT}"
bq mk --location=US online_shop
echo "${GREEN_TEXT}${BOLD_TEXT}Dataset created successfully!${RESET_FORMAT}"

# 2. Create Cloud Resource connection 'user_data_connection' in US multi-region
echo "${YELLOW_TEXT}${BOLD_TEXT}2. Creating BigQuery connection 'user_data_connection' in US...${RESET_FORMAT}"
bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE user_data_connection
echo "${GREEN_TEXT}${BOLD_TEXT}Connection established!${RESET_FORMAT}"
export CONNECTION_ID="$PROJECT_ID.US.user_data_connection"

# 3. Get Service Account ID and Grant Permissions
echo "${MAGENTA_TEXT}${BOLD_TEXT}3. Configuring service account permissions...${RESET_FORMAT}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $CONNECTION_ID | jq -r '.cloudResource.serviceAccountId')

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
echo "${GREEN_TEXT}${BOLD_TEXT}Permissions granted successfully to $SERVICE_ACCOUNT!${RESET_FORMAT}"

# 4. Create BigLake table 'user_online_sessions'
echo "${YELLOW_TEXT}${BOLD_TEXT}4. Creating BigLake table 'user_online_sessions' with auto-detection...${RESET_FORMAT}"

# Create the table definition file
bq mkdef \
--autodetect \
--connection_id=$CONNECTION_ID \
--source_format=CSV \
"gs://$PROJECT_ID-bucket/user-online-sessions.csv" > /tmp/tabledef.json

# Create the BigLake table
bq mk --external_table_definition=/tmp/tabledef.json \
--project_id=$PROJECT_ID \
online_shop.user_online_sessions
echo "${GREEN_TEXT}${BOLD_TEXT}BigLake table created successfully!${RESET_FORMAT}"
echo
# --- TASK 2: Create, apply, and verify an aspect on sensitive columns ---
echo "${GREEN_TEXT}${BOLD_TEXT}TASK 2: DATA CATALOG ASPECT SETUP 🛡️ ${RESET_FORMAT}"

# 1. Define the Aspect structure (YAML/JSON)
# Aspect Name: Sensitive Data Aspect
# Field: Has Sensitive Data (Boolean)
ASPECT_FILE="/tmp/sensitive-aspect.yaml"
cat > $ASPECT_FILE << EOM
name: 'Sensitive Data Aspect'
display_name: 'Sensitive Data Aspect'
description: 'Marks columns containing sensitive PII/location data.'
scope: 'TABLE' # Aspect can be applied to Table or Column
aspect_type:
  fields:
    HasSensitiveData:
      display_name: 'Has Sensitive Data'
      primitive_type: 'BOOL'
EOM

# 2. Create the Aspect in Data Catalog (uses the gcloud data-catalog aspects create command)
echo "${YELLOW_TEXT}${BOLD_TEXT}1. Creating Data Catalog Aspect: 'Sensitive Data Aspect' in US...${RESET_FORMAT}"
gcloud data-catalog aspects create --location=us --project=$PROJECT_ID --json-file=$ASPECT_FILE
export ASPECT_ID="Sensitive_Data_Aspect" # The ID generated from the display name

# 3. Apply the Aspect to the specified columns
# Columns: zip, latitude, ip_address, longitude
TABLE_RESOURCE_NAME="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/online_shop/tables/user_online_sessions"

# Aspect content for the boolean field
ASPECT_CONTENT='{"HasSensitiveData": true}'

echo "${YELLOW_TEXT}${BOLD_TEXT}2. Applying the Aspect to columns (zip, latitude, ip_address, longitude)...${RESET_FORMAT}"

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

echo "${GREEN_TEXT}${BOLD_TEXT}Aspect applied to all sensitive columns!${RESET_FORMAT}"
echo

# --- TASK 3: Remove IAM permissions to Cloud Storage for other users ---
echo "${GREEN_TEXT}${BOLD_TEXT}TASK 3: IAM CLEANUP 🧹 ${RESET_FORMAT}"

if [[ -n "$USER_2" ]]; then
    # The lab specifies removing the IAM role for Cloud Storage for User 2.
    # The common Cloud Storage viewer role is roles/storage.objectViewer.
    echo "${RED_TEXT}${BOLD_TEXT}Removing IAM policy binding for user $USER_2 (roles/storage.objectViewer)...${RESET_FORMAT}"
    
    gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
        --member="user:$USER_2" \
        --role="roles/storage.objectViewer"
    
    echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Storage permissions cleaned up successfully for $USER_2!${RESET_FORMAT}"
else
    echo "${YELLOW_TEXT}${BOLD_TEXT}Skipping IAM cleanup - no username provided. Please manually enter User 2's email to proceed.${RESET_FORMAT}"
fi

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        ALL CHALLENGE TASKS ATTEMPTED! ✅              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
