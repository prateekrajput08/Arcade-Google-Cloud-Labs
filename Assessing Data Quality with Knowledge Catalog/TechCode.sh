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
echo "${CYAN_TEXT}${BOLD_TEXT}           SUBSCRIBE TECH & CODE- INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

REGION=$(gcloud config get-value dataplex/region 2>/dev/null)

if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
    REGION=$(gcloud config get-value compute/region 2>/dev/null)
fi

if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
    echo "${YELLOW_TEXT}Region auto-detection failed.${RESET_FORMAT}"
    read -rp "$(echo -e "${CYAN_TEXT}Enter Region:${RESET_FORMAT} ")" REGION
fi

echo "${GREEN_TEXT}Region:${RESET_FORMAT} ${WHITE_TEXT}${REGION}${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED_TEXT}Project ID not found.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}Project:${RESET_FORMAT} ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Enabling APIs...${RESET_FORMAT}"

gcloud services enable \
dataplex.googleapis.com \
dataproc.googleapis.com \
bigquery.googleapis.com \
storage.googleapis.com \
--quiet

echo "${GREEN_TEXT}APIs enabled.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating Dataplex Lake...${RESET_FORMAT}"

gcloud dataplex lakes create ecommerce-lake \
--location="${REGION}" \
--display-name="Ecommerce Lake" \
--quiet

echo
echo "${YELLOW_TEXT}Waiting for lake activation...${RESET_FORMAT}"
sleep 25

echo
echo "${YELLOW_TEXT}Creating Zone...${RESET_FORMAT}"

gcloud dataplex zones create customer-contact-raw-zone \
--location="${REGION}" \
--lake=ecommerce-lake \
--display-name="Customer Contact Raw Zone" \
--type=RAW \
--resource-location-type=SINGLE_REGION \
--quiet

echo
echo "${YELLOW_TEXT}Waiting for zone activation...${RESET_FORMAT}"
sleep 35

echo
echo "${YELLOW_TEXT}Creating BigQuery Asset...${RESET_FORMAT}"

gcloud dataplex assets create contact-info \
--location="${REGION}" \
--lake=ecommerce-lake \
--zone=customer-contact-raw-zone \
--resource-type=BIGQUERY_DATASET \
--resource-name="projects/${PROJECT_ID}/datasets/customers" \
--display-name="Contact Info" \
--quiet

echo "${GREEN_TEXT}Asset created.${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED FOR TASK 2${RESET_FORMAT}"

echo "${CYAN_TEXT}Open BigQuery Console and run:${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}SELECT * FROM \`${PROJECT_ID}.customers.contact_info\`
ORDER BY id
LIMIT 50;${RESET_FORMAT}"

echo
read -rp "$(echo -e "${YELLOW_TEXT}After Task 2 is marked completed press ENTER...${RESET_FORMAT}")"

echo
echo "${YELLOW_TEXT}Creating YAML specification file...${RESET_FORMAT}"

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
echo "${YELLOW_TEXT}Checking bucket...${RESET_FORMAT}"

BUCKET_NAME="${PROJECT_ID}-bucket"

gsutil ls "gs://${BUCKET_NAME}" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then

    echo "${YELLOW_TEXT}Creating bucket...${RESET_FORMAT}"

    gsutil mb -l "${REGION}" "gs://${BUCKET_NAME}"

fi

echo "${GREEN_TEXT}Using Bucket:${RESET_FORMAT} ${WHITE_TEXT}${BUCKET_NAME}${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Uploading YAML file...${RESET_FORMAT}"

gsutil cp dq-customer-raw-data.yaml "gs://${BUCKET_NAME}/"

echo "${GREEN_TEXT}Upload completed.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating Data Quality Scan...${RESET_FORMAT}"

gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
--project="${PROJECT_ID}" \
--location="${REGION}" \
--data-source-resource="//bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/customers/tables/contact_info" \
--data-quality-spec-file="gs://${BUCKET_NAME}/dq-customer-raw-data.yaml" \
--quiet

echo
echo "${YELLOW_TEXT}Running Data Quality Scan...${RESET_FORMAT}"

gcloud dataplex datascans run customer-orders-data-quality-job \
--location="${REGION}"

echo
echo "${YELLOW_TEXT}Waiting for scan completion...${RESET_FORMAT}"
sleep 60

echo
echo "${YELLOW_TEXT}Fetching scan jobs...${RESET_FORMAT}"

gcloud dataplex datascans jobs list \
--datascan=customer-orders-data-quality-job \
--location="${REGION}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED FOR TASK 6${RESET_FORMAT}"

echo "${CYAN_TEXT}Open BigQuery Console and complete:${RESET_FORMAT}"

echo
echo "${WHITE_TEXT}1.${RESET_FORMAT} Open dataset ${GREEN_TEXT}customers_dq_dataset${RESET_FORMAT}"
echo "${WHITE_TEXT}2.${RESET_FORMAT} Open table ${GREEN_TEXT}dq_results${RESET_FORMAT}"
echo "${WHITE_TEXT}3.${RESET_FORMAT} Open ${GREEN_TEXT}Preview${RESET_FORMAT} tab"
echo "${WHITE_TEXT}4.${RESET_FORMAT} Copy first ${GREEN_TEXT}rule_failed_records_query${RESET_FORMAT}"
echo "${WHITE_TEXT}5.${RESET_FORMAT} Open new SQL query tab"
echo "${WHITE_TEXT}6.${RESET_FORMAT} Paste and run query"
echo "${WHITE_TEXT}7.${RESET_FORMAT} Repeat for second query"

echo
read -rp "$(echo -e "${YELLOW_TEXT}After Task 6 is marked completed press ENTER...${RESET_FORMAT}")"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
