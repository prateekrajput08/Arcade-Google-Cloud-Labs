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


export REGION="${ZONE%-*}"
export KEY_1=domain_type
export VALUE_1=source_data

gsutil mb -p $DEVSHELL_PROJECT_ID -l $REGION -b on gs://$DEVSHELL_PROJECT_ID-bucket/

gcloud alpha dataplex lakes create customer-lake \
--display-name="Customer-Lake" \
 --location=$REGION \
 --labels="key_1=$KEY_1,value_1=$VALUE_1"

gcloud dataplex zones create public-zone \
    --lake=customer-lake \
    --location=$REGION \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --display-name="Public-Zone"


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
