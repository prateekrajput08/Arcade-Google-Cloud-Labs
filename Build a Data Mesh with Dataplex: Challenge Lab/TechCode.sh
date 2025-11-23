#!/bin/bash

# ===============================
# Color Variables (Kept as Provided)
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

# RAW zone asset
gcloud dataplex assets create customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --display-name="Customer Engagements" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID-customer-online-sessions \
  --discovery-enabled

# CURATED zone asset
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
echo "${YELLOW_TEXT}${BOLD_TEXT}Tech & Code - https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo

# ===============================
# PAUSE BEFORE TASK 2
# ===============================
echo "${MAGENTA_TEXT}${BOLD_TEXT}⚠️  NOW DO TASK 2 MANUALLY IN THE LAB UI:${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Create Aspect Type → Apply Aspect to Raw Zone${RESET_FORMAT}"
echo
read -p "Press Y and hit ENTER once you finish Task 2 manually: " CONFIRM

# ===============================
# TASK 3 — Assign IAM to User 2
# ===============================
echo
read -p "Enter User 2 email (User 2 ID from lab): " USER_2
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
# TASK 4 — Create Data Quality Spec
# ===============================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Data Quality YAML...${RESET_FORMAT}"

cat > dq-customer-orders.yaml <<EOF
metadata_registry_defaults:
  dataplex:
    projects: $PROJECT_ID
    locations: $REGION
    lakes: sales-lake
    zones: curated-customer-zone

rule_dimensions:
  - completeness

row_filters:
  NONE:
    filter_sql_expr: True

rules:
  NOT_NULL:
    rule_type: NOT_NULL
    dimension: completeness

rule_bindings:
  VALID_USER:
    entity_uri: bigquery://projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: user_id
    row_filter_id: NONE
    rule_ids: [NOT_NULL]

  VALID_ORDER:
    entity_uri: bigquery://projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: order_id
    row_filter_id: NONE
    rule_ids: [NOT_NULL]

EOF

echo "${GREEN_TEXT}${BOLD_TEXT}Uploading YAML to Cloud Storage...${RESET_FORMAT}"
gsutil cp dq-customer-orders.yaml gs://$PROJECT_ID-dq-config/

echo "${GREEN_TEXT}${BOLD_TEXT}Task 4 Completed Successfully!${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Tech & Code - https://www.youtube.com/@TechCode9${RESET_FORMAT}"

# ===============================
# TASK 5 — Data Quality Job Setup
# ===============================
echo "${BLUE_TEXT}${BOLD_TEXT}Go to Dataplex → Data Quality → Create Job${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Use dq-customer-orders.yaml from GCS bucket${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Link:${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataplex/process/create-task/data-quality?project=$PROJECT_ID${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe${RESET_FORMAT}"

