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

# ===============================
# Enable Required Services
# ===============================
gcloud services enable \
  dataplex.googleapis.com \
  datacatalog.googleapis.com \
  dataproc.googleapis.com

# ===============================
# Set Environment Variables
# ===============================
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "${GREEN_TEXT}${BOLD_TEXT}Project: $PROJECT_ID | Region: $REGION | Zone: $ZONE ${RESET_FORMAT}"
sleep 1

echo "${YELLOW_TEXT}${BOLD_TEXT}Tech & Code - https://www.youtube.com/@TechCode9${RESET_FORMAT}"
sleep 1

# ===============================
# TASK 1 — Create Lake, Zones, Assets
# ===============================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Dataplex Lake, Zones and Assets...${RESET_FORMAT}"

gcloud dataplex lakes create sales-lake \
  --location=$REGION \
  --display-name="Sales Lake"

gcloud dataplex zones create raw-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Raw Customer Zone" \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"

gcloud dataplex zones create curated-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Curated Customer Zone" \
  --type=CURATED \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"

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

echo "${GREEN_TEXT}${BOLD_TEXT}Task 1 Completed Successfully!${RESET_FORMAT}"
echo

# ===============================
# TASK 2 — Manual Step
# ===============================
echo "${MAGENTA_TEXT}${BOLD_TEXT}⚠️  DO TASK 2 MANUALLY NOW (Aspect Type + Apply Aspect)${RESET_FORMAT}"
read -p "Press Y and hit ENTER once you finish Task 2 manually: " CONFIRM

# ===============================
# TASK 3 — IAM Role Assignment
# ===============================
read -p "Enter User 2 email (User 2 ID): " USER_2
echo "${BLUE_TEXT}${BOLD_TEXT}Assigning roles/dataplex.dataWriter to $USER_2...${RESET_FORMAT}"

gcloud dataplex assets add-iam-policy-binding customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --member=user:$USER_2 \
  --role=roles/dataplex.dataWriter

echo "${GREEN_TEXT}${BOLD_TEXT}Task 3 Completed Successfully!${RESET_FORMAT}"
echo

# ===============================
# TASK 4 — Create YAML for Data Quality
# ===============================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Data Quality YAML...${RESET_FORMAT}"

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

echo "${GREEN_TEXT}${BOLD_TEXT}Uploading YAML to Cloud Storage...${RESET_FORMAT}"
gsutil cp dq-customer-orders.yaml gs://$PROJECT_ID-dq-config/

echo "${GREEN_TEXT}${BOLD_TEXT}Task 4 Completed Successfully!${RESET_FORMAT}"

# ===============================
# TASK 5 — AUTOMATED DATA QUALITY SCAN (UPDATED!)
# ===============================
echo "${BLUE_TEXT}${BOLD_TEXT}Running Dataplex Data Quality Scan (Task 5)...${RESET_FORMAT}"

gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
    --project=$PROJECT_ID \
    --location=$REGION \
    --data-source-resource="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items" \
    --data-quality-spec-file="gs://$PROJECT_ID-dq-config/dq-customer-orders.yaml"

echo "${GREEN_TEXT}${BOLD_TEXT}Task 5 Completed Successfully!${RESET_FORMAT}"

# ===============================
# FINAL MESSAGE
# ===============================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        ALL TASKS COMPLETED — LAB READY TO SUBMIT       ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe!${RESET_FORMAT}"

