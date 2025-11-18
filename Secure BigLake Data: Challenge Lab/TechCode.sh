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

# Section 1: User Input
echo "${GREEN_TEXT}${BOLD_TEXT}USER CONFIGURATION {RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Enter USERNAME 2 (for IAM cleanup): ${RESET_FORMAT}"
read -r USER_2
echo "${CYAN_TEXT}${BOLD_TEXT}User input received${RESET_FORMAT}"
echo

# Section 2: Taxonomy Setup
echo "${GREEN_TEXT}${BOLD_TEXT}TAXONOMY SETUP ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Fetching taxonomy details...${RESET_FORMAT}"
export TAXONOMY_NAME=$(gcloud data-catalog taxonomies list \
  --location=us \
  --project=$DEVSHELL_PROJECT_ID \
  --format="value(displayName)" \
  --limit=1)

export TAXONOMY_ID=$(gcloud data-catalog taxonomies list \
  --location=us \
  --format="value(name)" \
  --filter="displayName=$TAXONOMY_NAME" | awk -F'/' '{print $6}')

export POLICY_TAG=$(gcloud data-catalog taxonomies policy-tags list \
  --location=us \
  --taxonomy=$TAXONOMY_ID \
  --format="value(name)" \
  --limit=1)

echo "${CYAN_TEXT}${BOLD_TEXT}Taxonomy Name: ${WHITE_TEXT}$TAXONOMY_NAME${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Policy Tag: ${WHITE_TEXT}$POLICY_TAG${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Taxonomy details retrieved successfully!${RESET_FORMAT}"
echo

# Section 3: BigQuery Setup
echo "${GREEN_TEXT}${BOLD_TEXT} BIGQUERY SETUP ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating BigQuery dataset 'online_shop'${RESET_FORMAT}"
bq mk online_shop
echo "${GREEN_TEXT}${BOLD_TEXT}Dataset created successfully!${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating BigQuery connection${RESET_FORMAT}"
bq mk --connection --location=US --project_id=$DEVSHELL_PROJECT_ID --connection_type=CLOUD_RESOURCE user_data_connection
echo "${GREEN_TEXT}${BOLD_TEXT}Connection established!${RESET_FORMAT}"
echo

# Section 4: Permissions
echo "${GREEN_TEXT}${BOLD_TEXT}PERMISSIONS SETUP ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Configuring service account permissions${RESET_FORMAT}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $DEVSHELL_PROJECT_ID.US.user_data_connection | jq -r '.cloudResource.serviceAccountId')

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
echo "${GREEN_TEXT}${BOLD_TEXT}Permissions granted successfully!${RESET_FORMAT}"
echo

# Section 5: Table Configuration
echo "${GREEN_TEXT}${BOLD_TEXT}TABLE CONFIGURATION${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating table definition from Cloud Storage${RESET_FORMAT}"
bq mkdef \
--autodetect \
--connection_id=$DEVSHELL_PROJECT_ID.US.user_data_connection \
--source_format=CSV \
"gs://$DEVSHELL_PROJECT_ID-bucket/user-online-sessions.csv" > /tmp/tabledef.json
echo "${CYAN_TEXT}${BOLD_TEXT}Definition saved to /tmp/tabledef.json${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating BigLake table 'user_online_sessions'${RESET_FORMAT}"
bq mk --external_table_definition=/tmp/tabledef.json \
--project_id=$DEVSHELL_PROJECT_ID \
online_shop.user_online_sessions
echo "${GREEN_TEXT}${BOLD_TEXT}Table created successfully!${RESET_FORMAT}"
echo

# Section 6: Schema Management
# The entire original Task 2 implementation, which was located here, is now REMOVED.
echo "${GREEN_TEXT}${BOLD_TEXT}SCHEMA MANAGEMENT (NOTE: Task 2 implementation steps removed as requested)${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Skipping Aspect creation and application.${RESET_FORMAT}"
echo

# Section 7: Data Query
echo "${GREEN_TEXT}${BOLD_TEXT}DATA QUERY (Skipping query that uses policy-tagged columns)${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Query execution skipped.${RESET_FORMAT}"
echo

# Section 8: Cleanup
echo "${GREEN_TEXT}${BOLD_TEXT}CLEANUP${RESET_FORMAT}"
if [[ -n "$USER_2" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Removing IAM policy binding for user $USER_2${RESET_FORMAT}"
    gcloud projects remove-iam-policy-binding ${DEVSHELL_PROJECT_ID} \
        --member="user:$USER_2" \
        --role="roles/storage.objectViewer"
    echo "${GREEN_TEXT}${BOLD_TEXT}Permissions cleaned up successfully!${RESET_FORMAT}"
else
    echo "${YELLOW_TEXT}${BOLD_TEXT}Skipping IAM cleanup - no username provided${RESET_FORMAT}"
fi

# Final message
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              LAB EXECUTION COMPLETE (Task 2 excluded) ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
