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

# Enable necessary Google Cloud services for Dataplex, Data Catalog, and Dataproc
gcloud services enable \
  dataplex.googleapis.com \
  datacatalog.googleapis.com \
  dataproc.googleapis.com

# Set environment variables for project ID, zone, and region
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

# Create a Dataplex lake named "sales-lake" in the specified region
gcloud dataplex lakes create sales-lake \
  --location=$REGION \
  --display-name="Sales Lake" \
  --description="Lake for sales data"

# Create a raw data zone within the "sales-lake"
gcloud dataplex zones create raw-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --resource-location-type=SINGLE_REGION \
  --display-name="Raw Customer Zone" \
  --discovery-enabled \
  --discovery-schedule="0 * * * *" \
  --type=RAW

# Create a curated data zone within the "sales-lake"
gcloud dataplex zones create curated-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --resource-location-type=SINGLE_REGION \
  --display-name="Curated Customer Zone" \
  --discovery-enabled \
  --discovery-schedule="0 * * * *" \
  --type=CURATED

# Create an asset representing customer engagement data in the raw zone
gcloud dataplex assets create customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --display-name="Customer Engagements" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-online-sessions \
  --discovery-enabled

# Create an asset representing customer order data in the curated zone
gcloud dataplex assets create customer-orders \
  --lake=sales-lake \
  --zone=curated-customer-zone \
  --location=$REGION \
  --display-name="Customer Orders" \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders \
  --discovery-enabled

###############################################################################
# REPLACED TAG TEMPLATE WITH ASPECT TYPE
###############################################################################

# Create Dataplex Aspect Type instead of Data Catalog Tag Template
gcloud dataplex aspect-types create protected_customer_data_aspect \
  --location=$REGION \
  --display-name="Protected Customer Data Aspect" \
  --description="Aspect defining customer protected data fields" \
  --fields=raw_data_flag=ENUM,protected_contact_information_flag=ENUM \
  --enum-values=raw_data_flag:Yes,No \
  --enum-values=protected_contact_information_flag:Yes,No

###############################################################################

# Grant "dataWriter" role to user $USER_2 on the "customer-engagements" asset
gcloud dataplex assets add-iam-policy-binding customer-engagements \
    --location=$REGION \
    --lake=sales-lake \
    --zone=raw-customer-zone \
    --role=roles/dataplex.dataWriter \
    --member=user:$USER_2

# Create a YAML file named "dq-customer-orders.yaml" with the following content:
cat > dq-customer-orders.yaml <<EOF_CP
metadata_registry_defaults:
  dataplex:
    projects: $DEVSHELL_PROJECT_ID
    locations: $REGION
    lakes: sales-lake
    zones: curated-customer-zone
row_filters:
  NONE:
    filter_sql_expr: |-
      True
rule_dimensions:
  - completeness
rules:
  NOT_NULL:
    rule_type: NOT_NULL
    dimension: completeness
rule_bindings:
  VALID_CUSTOMER:
    entity_uri: bigquery://projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: user_id
    row_filter_id: NONE
    rule_ids:
      - NOT_NULL
  VALID_ORDER:
    entity_uri: bigquery://projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: order_id
    row_filter_id: NONE
    rule_ids:
      - NOT_NULL
EOF_CP

# Copy the YAML file to a Cloud Storage bucket
gsutil cp dq-customer-orders.yaml gs://$DEVSHELL_PROJECT_ID-dq-config

echo "${GREEN_TEXT}${BOLD_TEXT}Click here: "${RESET}""${BLUE_TEXT}${BOLD_TEXT}"https://console.cloud.google.com/dataplex/search?project=$DEVSHELL_PROJECT_ID&qSystems=DATAPLEX""${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}Click here: "${RESET}""${BLUE_TEXT}${BOLD_TEXT}""https://console.cloud.google.com/dataplex/process/create-task/data-quality?project=$DEVSHELL_PROJECT_ID"""${RESET_FORMAT}"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
