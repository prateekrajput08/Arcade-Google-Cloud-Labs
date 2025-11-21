#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =============================
# Task 1: Create BigQuery Dataset (US Multi-Region)
# =============================
bq --location=US mk ecommerce


# =============================
# Task 2: Create Cloud Resource Connection (US Multi-Region)
# =============================

# Enable required APIs
gcloud services enable bigqueryconnection.googleapis.com
gcloud services enable datacatalog.googleapis.com

# Create Cloud Resource Connection
bq mk --connection \
  --connection_type=CLOUD_RESOURCE \
  --location=US \
  --project_id=$DEVSHELL_PROJECT_ID \
  customer_data_connection

# Fetch the connection service account
CONN_SA=$(bq show --connection $DEVSHELL_PROJECT_ID.US.customer_data_connection \
  | grep serviceAccountId \
  | awk -F'"' '{print $4}')

echo "Connection Service Account: $CONN_SA"

# Grant Storage Viewer so BigLake can read the CSV
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:$CONN_SA" \
  --role="roles/storage.objectViewer"

# Create BigLake table with autodetected schema
bq mk \
  --external_table_definition=gs://$DEVSHELL_PROJECT_ID-bucket/customer-online-sessions.csv \
  ecommerce.customer_online_sessions

gcloud data-catalog tag-templates create sensitive_data_template \
    --location=$REGION \
    --display-name="Sensitive Data Template" \
    --field=id=has_sensitive_data,display-name="Has Sensitive Data",type=bool \
    --field=id=sensitive_data_type,display-name="Sensitive Data Type",type='enum(Location Info|Contact Info|None)'

cat > tag_file.json << EOF
  {
    "has_sensitive_data": TRUE,
    "sensitive_data_type": "Location Info"
  }
EOF

ENTRY_NAME=$(gcloud data-catalog entries lookup '//bigquery.googleapis.com/projects/'$DEVSHELL_PROJECT_ID'/datasets/ecommerce/tables/customer_online_sessions' --format="value(name)")

gcloud data-catalog tags create --entry=${ENTRY_NAME} \
    --tag-template=sensitive_data_template --tag-template-location=$REGION --tag-file=tag_file.json

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
