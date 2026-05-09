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
TEAL=$'\033[38;5;50m'

# Define text formatting variables
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

echo
echo "${YELLOW_TEXT}Fetching active project...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED_TEXT}No active project found.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}Project ID:${RESET_FORMAT} ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Fetching default region/zone...${RESET_FORMAT}"

REGION=$(gcloud config get-value dataproc/region 2>/dev/null)

if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
    REGION=$(gcloud config get-value compute/region 2>/dev/null)
fi

if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
    echo "${YELLOW_TEXT}Region could not be auto detected.${RESET_FORMAT}"
    read -rp "$(echo -e "${CYAN_TEXT}Enter Region:${RESET_FORMAT} ")" REGION
fi

echo "${GREEN_TEXT}Using Region:${RESET_FORMAT} ${WHITE_TEXT}$REGION${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Enabling required APIs...${RESET_FORMAT}"

gcloud services enable dataplex.googleapis.com \
    dataproc.googleapis.com \
    bigquery.googleapis.com \
    storage.googleapis.com \
    --quiet

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}API enable failed.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}APIs enabled.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating Dataplex Lake...${RESET_FORMAT}"

gcloud dataplex lakes create ecommerce-lake \
    --location="$REGION" \
    --display-name="Ecommerce Lake" \
    --quiet

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}Lake creation failed or already exists.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}Waiting for lake activation...${RESET_FORMAT}"
sleep 20

echo
echo "${YELLOW_TEXT}Creating Zone...${RESET_FORMAT}"

gcloud dataplex zones create customer-contact-raw-zone \
    --location="$REGION" \
    --lake=ecommerce-lake \
    --display-name="Customer Contact Raw Zone" \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --quiet

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}Zone creation failed or already exists.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}Waiting for zone activation...${RESET_FORMAT}"
sleep 30

echo
echo "${YELLOW_TEXT}Fetching customers dataset location...${RESET_FORMAT}"

BQ_LOCATION=$(bq show --format=prettyjson "${PROJECT_ID}:customers" | grep location | awk -F '"' '{print $4}')

echo "${GREEN_TEXT}BigQuery Dataset Location:${RESET_FORMAT} ${WHITE_TEXT}$BQ_LOCATION${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating Dataplex Asset...${RESET_FORMAT}"

gcloud dataplex assets create contact-info \
    --location="$REGION" \
    --lake=ecommerce-lake \
    --zone=customer-contact-raw-zone \
    --resource-type=BIGQUERY_DATASET \
    --resource-name="projects/${PROJECT_ID}/datasets/customers" \
    --display-name="Contact Info" \
    --quiet

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}Asset creation failed or already exists.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}Running sample BigQuery validation query...${RESET_FORMAT}"

bq query --use_legacy_sql=false "
SELECT * FROM \`${PROJECT_ID}.customers.contact_info\`
ORDER BY id
LIMIT 10
"

echo
echo "${YELLOW_TEXT}Creating Data Quality YAML file...${RESET_FORMAT}"

cat > dq-customer-raw-data.yaml <<EOF
rules:
- nonNullExpectation: {}
  column: id
  dimension: COMPLETENESS
  threshold: 1

- regexExpectation:
    regex: '^[^@]+[@]{1}[^@]+$'
  column: email
  dimension: CONFORMANCE
  ignoreNull: true
  threshold: .85

postScanActions:
  bigqueryExport:
    resultsTable: projects/${PROJECT_ID}/datasets/customers_dq_dataset/tables/dq_results
EOF

echo "${GREEN_TEXT}YAML file created.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Checking for bucket...${RESET_FORMAT}"

BUCKET_NAME="${PROJECT_ID}-bucket"

gsutil ls "gs://${BUCKET_NAME}" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo "${YELLOW_TEXT}Bucket not found. Creating bucket...${RESET_FORMAT}"

    gsutil mb -l "$REGION" "gs://${BUCKET_NAME}"

    if [[ $? -ne 0 ]]; then
        echo "${RED_TEXT}Bucket creation failed.${RESET_FORMAT}"
        exit 1
    fi
fi

echo "${GREEN_TEXT}Using Bucket:${RESET_FORMAT} ${WHITE_TEXT}${BUCKET_NAME}${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Uploading YAML specification file...${RESET_FORMAT}"

gsutil cp dq-customer-raw-data.yaml "gs://${BUCKET_NAME}/"

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}File upload failed.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}YAML uploaded successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating Data Quality Scan...${RESET_FORMAT}"

gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --data-source-resource="//bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/customers/tables/contact_info" \
    --data-quality-spec-file="gs://${BUCKET_NAME}/dq-customer-raw-data.yaml" \
    --quiet

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}Datascan creation failed or already exists.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}Triggering Data Quality Scan...${RESET_FORMAT}"

gcloud dataplex datascans run customer-orders-data-quality-job \
    --location="$REGION"

if [[ $? -ne 0 ]]; then
    echo "${RED_TEXT}Datascan execution failed.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}Waiting for scan execution...${RESET_FORMAT}"
sleep 40

echo
echo "${YELLOW_TEXT}Fetching scan results...${RESET_FORMAT}"

gcloud dataplex datascans jobs list \
    --datascan=customer-orders-data-quality-job \
    --location="$REGION"

echo
echo "${YELLOW_TEXT}Checking dq_results table...${RESET_FORMAT}"

bq query --use_legacy_sql=false "
SELECT
  rule_name,
  rule_type,
  passed,
  null_count,
  failed_records_query
FROM \`${PROJECT_ID}.customers_dq_dataset.dq_results\`
LIMIT 10
"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
