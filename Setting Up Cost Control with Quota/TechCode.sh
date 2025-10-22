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

bq query --use_legacy_sql=false \
"
SELECT
    w1mpro_ep,
    mjd,
    load_id,
    frame_id
FROM
    \`bigquery-public-data.wise_all_sky_data_release.mep_wise\`
ORDER BY
    mjd ASC
LIMIT 500
"

gcloud alpha services quota list --service=bigquery.googleapis.com --consumer=projects/${DEVSHELL_PROJECT_ID} --filter="usage"

gcloud alpha services quota update --consumer=projects/${DEVSHELL_PROJECT_ID} --service bigquery.googleapis.com --metric bigquery.googleapis.com/quota/query/usage --value 262144 --unit 1/d/{project}/{user} --force

gcloud alpha services quota list --service=bigquery.googleapis.com --consumer=projects/${DEVSHELL_PROJECT_ID} --filter="usage"

bq query --use_legacy_sql=false --nouse_cache \
"
 SELECT
     w1mpro_ep,
     mjd,
     load_id,
     frame_id
 FROM
     \`bigquery-public-data.wise_all_sky_data_release.mep_wise\`
 ORDER BY
     mjd ASC
 LIMIT 500
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
