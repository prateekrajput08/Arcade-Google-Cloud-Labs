#!/bin/bash

# ===============================
# Color Variables (Unchanged)
# ===============================
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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        SUBSCRIBE TECH & CODE - INITIATING EXECUTION...           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling Required GCP Services...${RESET_FORMAT}"
gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com dataproc.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}Services Enabled Successfully${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "${BLUE_TEXT}${BOLD_TEXT}Project ID: ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Zone: ${WHITE_TEXT}$ZONE${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Region: ${WHITE_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Dataplex Lake...${RESET_FORMAT}"
gcloud dataplex lakes create sales-lake \
  --location=$REGION \
  --display-name="Sales Lake"
echo "${GREEN_TEXT}${BOLD_TEXT}Dataplex Lake Created${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Raw Customer Zone...${RESET_FORMAT}"
gcloud dataplex zones create raw-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Raw Customer Zone" \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"
echo "${GREEN_TEXT}${BOLD_TEXT}Raw Zone Created${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Curated Customer Zone...${RESET_FORMAT}"
gcloud dataplex zones create curated-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Curated Customer Zone" \
  --type=CURATED \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"
echo "${GREEN_TEXT}${BOLD_TEXT}Curated Zone Created${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Assets...${RESET_FORMAT}"

gcloud dataplex assets create customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --display-name="Customer Engagements" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID-customer-online-sessions \
  --discovery-enabled

gcloud dataplex assets create customer-orders \
  --lake=sales-lake \
  --zone=curated-customer-zone \
  --location=$REGION \
  --display-name="Customer Orders" \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$PROJECT_ID/datasets/customer_orders \
  --discovery-enabled

echo "${GREEN_TEXT}${BOLD_TEXT}All Assets Created Successfully${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Complete Task 2 Manually (Aspects)${RESET_FORMAT}"
read -p "Press Enter when done: "

read -p "Enter User 2 email: " USER_2

echo "${YELLOW_TEXT}${BOLD_TEXT}Applying IAM Policy Binding...${RESET_FORMAT}"
gcloud dataplex assets add-iam-policy-binding customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --member=user:$USER_2 \
  --role=roles/dataplex.dataWriter
echo "${GREEN_TEXT}${BOLD_TEXT}IAM Permission Applied${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Data Quality YAML File...${RESET_FORMAT}"
cat > dq-customer-orders.yaml <<EOF
rules:
- nonNullExpectation: {}
  column: user_id
  dimension: COMPLETENESS
  threshold: 1

- nonNullExpectation: {}
  column: order_id
  dimension: COMPLETENESS
  threshold: 1

postScanActions:
  bigqueryExport:
    resultsTable: projects/$PROJECT_ID/datasets/orders_dq_dataset/tables/results
EOF

gsutil cp dq-customer-orders.yaml gs://$PROJECT_ID-dq-config/
echo "${GREEN_TEXT}${BOLD_TEXT}YAML Uploaded to GCS${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Data Quality Scan...${RESET_FORMAT}"
gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
    --project=$PROJECT_ID \
    --location=$REGION \
    --data-source-resource="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items" \
    --data-quality-spec-file="gs://$PROJECT_ID-dq-config/dq-customer-orders.yaml"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        ALL TASKS COMPLETED — LAB READY TO SUBMIT       ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe!${RESET_FORMAT}"
