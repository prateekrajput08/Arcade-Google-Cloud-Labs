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


#!/bin/bash

# Automatically set REGION from ZONE and define tag template labels
export REGION="${ZONE%-*}"
export KEY_1=domain_type
export VALUE_1=source_data

# Step 1: Create Cloud Storage Bucket
gsutil mb -p $DEVSHELL_PROJECT_ID -l $REGION -b on gs://$DEVSHELL_PROJECT_ID-bucket/

# Step 2: Create Dataplex Lake
gcloud alpha dataplex lakes create customer-lake \
  --display-name="Customer-Lake" \
  --location=$REGION \
  --labels="key_1=$KEY_1,value_1=$VALUE_1"

# Step 3: Create Dataplex Zone
gcloud dataplex zones create public-zone \
  --lake=customer-lake \
  --location=$REGION \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --display-name="Public-Zone"

# Step 4: Replace environment creation with Entry Group creation
read -p "Enter Entry Group Name: " ENTRY_GROUP_NAME

# Use default if user presses Enter
if [ -z "$ENTRY_GROUP_NAME" ]; then
  ENTRY_GROUP_NAME="custom-entry-group"
fi

gcloud dataplex entry-groups create $ENTRY_GROUP_NAME \
  --project=$DEVSHELL_PROJECT_ID \
  --location=$REGION \
  --description="Custom entry group created in place of dataplex environment" \
  --display-name="Custom Entry Group"

# Step 5: Create a Data Catalog Tag Template
gcloud data-catalog tag-templates create customer_data_tag_template \
  --location=$REGION \
  --display-name="Customer Data Tag Template" \
  --field=id=data_owner,display-name="Data Owner",type=string,required=TRUE \
  --field=id=pii_data,display-name="PII Data",type='enum(Yes|No)',required=TRUE



# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
