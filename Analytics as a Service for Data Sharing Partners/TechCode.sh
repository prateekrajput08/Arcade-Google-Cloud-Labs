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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

set -euo pipefail

PARTNER_PROJECT_ID=$(gcloud config get-value project)
DATASET="demo_dataset"
VIEW_A="authorized_view_a"
VIEW_B="authorized_view_b"

echo "Using Project: $PARTNER_PROJECT_ID"
echo "Creating Authorized Views..."

bq query --use_legacy_sql=false --project_id="$PARTNER_PROJECT_ID" <<EOF
CREATE OR REPLACE VIEW \`${PARTNER_PROJECT_ID}.${DATASET}.${VIEW_A}\` AS
SELECT * FROM \`bigquery-public-data.geo_us_boundaries.zip_codes\` WHERE state_code = 'TX' LIMIT 4000;
EOF
echo " • View A created."

bq query --use_legacy_sql=false --project_id="$PARTNER_PROJECT_ID" <<EOF
CREATE OR REPLACE VIEW \`${PARTNER_PROJECT_ID}.${DATASET}.${VIEW_B}\` AS
SELECT * FROM \`bigquery-public-data.geo_us_boundaries.zip_codes\` WHERE state_code = 'CA' LIMIT 4000;
EOF
echo " • View B created."

echo "Authorizing views to access the source dataset..."
echo "Now Please DO manual step..."

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
