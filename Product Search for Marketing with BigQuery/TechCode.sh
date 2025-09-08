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
BOLD=`tput bold`
RESET=`tput sgr0`
clear


# Welcome message
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

set -e

NC='\033[0m'

echo -e "${CYAN_TEXT}🔧 Starting BigQuery Load + Search Index Script...${NC}"

read -p "Enter BigQuery dataset name [default: products]: " DATASET
DATASET=${DATASET:-products}

read -p "Enter BigQuery table name [default: products_information]: " TABLE
TABLE=${TABLE:-products_information}

BQ_TABLE="$DATASET.$TABLE"
BQ_TABLE_BACKTICK="\`$BQ_TABLE\`"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED_TEXT}Failed to get GCP project ID. Authenticate with gcloud.${NC}"
  exit 1
fi

echo -e "${GREEN_TEXT}Project ID: $PROJECT_ID${NC}"

GCS_URI="gs://${PROJECT_ID}-bucket/products.csv"
if ! gsutil ls "$GCS_URI" &>/dev/null; then
  echo -e "${YELLOW_TEXT}File not found: $GCS_URI. Trying fallback: $DATASET.csv${NC}"
  GCS_URI="gs://${PROJECT_ID}-bucket/${DATASET}.csv"
fi

echo -e "${GREEN_TEXT}Using CSV from: $GCS_URI${NC}"

echo -e "${CYAN_TEXT}Loading data into BigQuery table: $BQ_TABLE...${NC}"
bq load --source_format=CSV --skip_leading_rows=1 --autodetect "$BQ_TABLE" "$GCS_URI"

echo -e "${CYAN_TEXT}Creating search index on: $BQ_TABLE...${NC}"
bq query --use_legacy_sql=false "
CREATE SEARCH INDEX IF NOT EXISTS product_search_index ON $BQ_TABLE_BACKTICK (ALL COLUMNS);
"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
