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

###############################################
# TASK 1 — Create BigQuery dataset (US)
###############################################

bq --location=US mk ecommerce



###############################################
# TASK 2 — Create Cloud Resource connection
#          and BigLake table
###############################################

# Enable required APIs
gcloud services enable bigqueryconnection.googleapis.com
gcloud services enable datacatalog.googleapis.com

# Create the connection (multi-region US)
bq mk --connection \
  --connection_type=CLOUD_RESOURCE \
  --location=US \
  --project_id=$DEVSHELL_PROJECT_ID \
  customer_data_connection

# Fetch connection service account
CONN_SA=$(bq show --connection $DEVSHELL_PROJECT_ID.US.customer_data_connection \
  | grep serviceAccountId \
  | awk -F'"' '{print $4}')

echo "Connection Service Account: $CONN_SA"

# Grant Storage Viewer so BigLake can read files
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:$CONN_SA" \
  --role="roles/storage.objectViewer"

# Create BigLake table from CSV (schema auto-detected)
bq mk \
  --external_table_definition=gs://$DEVSHELL_PROJECT_ID-bucket/customer-online-sessions.csv \
  ecommerce.customer_online_sessions



###############################################
# TASK 3 — Create Aspect + Apply to table
###############################################

# Create the Aspect Template
gcloud data-catalog aspects templates create sensitive_data_aspect \
  --location=US \
  --display-name="Sensitive Data Aspect" \
  --field=id=Has_Sensitive_Data,display-name="Has Sensitive Data",type=bool \
  --field=id=Sensitive_Data_Type,display-name="Sensitive Data Type",type='enum(Location Info|Contact Info|None)'


# Create aspect data file
cat > aspect.json << EOF
{
  "Has_Sensitive_Data": true,
  "Sensitive_Data_Type": "Location Info"
}
EOF


# Lookup the BigLake table entry
ENTRY=$(gcloud data-catalog entries lookup \
  //bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/ecommerce/tables/customer_online_sessions \
  --format="value(name)")

echo "Entry name: $ENTRY"


# Apply the aspect
gcloud data-catalog aspects create \
  --entry=$ENTRY \
  --aspect-template=sensitive_data_aspect \
  --aspect-template-location=US \
  --aspect-data-file=aspect.json


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
