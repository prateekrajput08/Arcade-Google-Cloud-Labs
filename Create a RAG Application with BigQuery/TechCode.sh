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


set -euo pipefail

# =============== Styling & Spinner ===============
CLR_RESET="\033[0m"
CLR_TITLE="\033[38;5;206m"
CLR_ACCENT="\033[38;5;51m"
CLR_OK="\033[32m"
CLR_WARN="\033[33m"
CLR_ERR="\033[31m"

spinner_pid=""
spin() {
  local msg="$1"
  local chars='|/-\'
  printf "  %b%s%b " "$CLR_ACCENT" "$msg" "$CLR_RESET"
  (
    while true; do
      for (( i=0; i<${#chars}; i++ )); do
        printf "\b${chars:$i:1}"
        sleep 0.1
      done
    done
  ) &
  spinner_pid=$!
  disown
}
stop_spin() {
  if [[ -n "${spinner_pid}" ]]; then
    kill "$spinner_pid" >/dev/null 2>&1 || true
    spinner_pid=""
    printf "\b %b✔%b\n" "$CLR_OK" "$CLR_RESET"
  fi
}
trap 'stop_spin || true' EXIT


need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo -e "${CLR_ERR}Missing dependency:$CLR_RESET $1"
    exit 1
  }
}

run_step() {
  local msg="$1"
  shift
  spin "$msg"
  {
    eval "$@"
  } >/dev/null 2>&1
  stop_spin
}

# =============== Start ===============
banner
need gcloud
need bq
need jq

echo -e "${CLR_ACCENT}Authenticating & pulling config...${CLR_RESET}"
run_step "Reading default REGION/ZONE" \
'export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])");
 export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")'

run_step "Reading current PROJECT_ID" \
'export PROJECT_ID=$(gcloud config get-value project)'

if [[ -z "${PROJECT_ID:-}" ]]; then
  echo -e "${CLR_ERR}No active gcloud project set. Run: gcloud config set project YOUR_PROJECT${CLR_RESET}"
  exit 1
fi

echo -e "PROJECT: ${CLR_OK}$PROJECT_ID${CLR_RESET}   REGION: ${CLR_OK}${REGION:-unset}${CLR_RESET}   ZONE: ${CLR_OK}${ZONE:-unset}${CLR_RESET}"

# =============== Enable APIs ===============
run_step "Enabling AI Platform API (Vertex AI)" \
"gcloud services enable aiplatform.googleapis.com --project=${PROJECT_ID}"

sleep 2

# =============== BigQuery Connection (CLOUD_RESOURCE) ===============
# Connection lives in 'US' location and will be referenced as \`us.embedding_conn\`
run_step "Creating BigQuery connection 'embedding_conn' in US" \
"bq mk --connection --location=US --project_id=${PROJECT_ID} --connection_type=CLOUD_RESOURCE embedding_conn || true"

run_step "Fetching connection service account" \
'SERVICE_ACCOUNT=$(bq show --format=json --connection ${PROJECT_ID}.US.embedding_conn | jq -r ".cloudResource.serviceAccountId"); echo "$SERVICE_ACCOUNT" >/tmp/_conn_sa.txt'
SERVICE_ACCOUNT="$(cat /tmp/_conn_sa.txt)"

if [[ -z "${SERVICE_ACCOUNT}" || "${SERVICE_ACCOUNT}" == "null" ]]; then
  echo -e "${CLR_ERR}Could not resolve connection service account. Check your permissions.${CLR_RESET}"
  exit 1
fi

run_step "Granting BigQuery Data Owner to connection SA" \
"gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SERVICE_ACCOUNT} --role=roles/bigquery.dataOwner"

run_step "Granting Vertex AI User to connection SA" \
"gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SERVICE_ACCOUNT} --role=roles/aiplatform.user"

# =============== Dataset & Tables ===============
run_step "Creating dataset CustomerReview (if needed)" \
"bq --location=US mk -d ${PROJECT_ID}:CustomerReview || true"

# Optional placeholder (was empty in your snippet)
# bq query --use_legacy_sql=false ""  # skipped intentionally

# =============== Embedding model (REMOTE) ===============
run_step "Creating REMOTE Embeddings model (text-embedding-005)" \
"bq query --use_legacy_sql=false \"CREATE OR REPLACE MODEL \\\`${PROJECT_ID}.CustomerReview.Embeddings\\\` REMOTE WITH CONNECTION \\\`us.embedding_conn\\\` OPTIONS (ENDPOINT = 'text-embedding-005');\""

# =============== Load sample CSV ===============
run_step "Loading sample customer reviews CSV into CustomerReview.customer_reviews" \
"bq query --use_legacy_sql=false \"
LOAD DATA OVERWRITE \\\`${PROJECT_ID}.CustomerReview.customer_reviews\\\`
(
  customer_review_id INT64,
  customer_id INT64,
  location_id INT64,
  review_datetime DATETIME,
  review_text STRING,
  social_media_source STRING,
  social_media_handle STRING
)
FROM FILES (
  format = 'CSV',
  uris = ['gs://spls/gsp1249/customer_reviews.csv']
);\""

# =============== Generate embeddings table ===============
run_step "Generating embeddings table CustomerReview.customer_reviews_embedded" \
"bq query --use_legacy_sql=false \"
CREATE OR REPLACE TABLE \\\`${PROJECT_ID}.CustomerReview.customer_reviews_embedded\\\` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
  MODEL \\\`${PROJECT_ID}.CustomerReview.Embeddings\\\`,
  (SELECT review_text AS content FROM \\\`${PROJECT_ID}.CustomerReview.customer_reviews\\\`)
);\""

# =============== Vector search sample ===============
run_step "Running VECTOR_SEARCH into CustomerReview.vector_search_result (top 5 for 'service')" \
"bq query --use_legacy_sql=false \"
CREATE OR REPLACE TABLE \\\`${PROJECT_ID}.CustomerReview.vector_search_result\\\` AS
SELECT
  query.query,
  base.content
FROM
  VECTOR_SEARCH(
    TABLE \\\`${PROJECT_ID}.CustomerReview.customer_reviews_embedded\\\`,
    'ml_generate_embedding_result',
    (
      SELECT
        ml_generate_embedding_result,
        content AS query
      FROM
        ML.GENERATE_EMBEDDING(
          MODEL \\\`${PROJECT_ID}.CustomerReview.Embeddings\\\`,
          (SELECT 'service' AS content)
        )
    ),
    top_k => 5,
    options => '{\"fraction_lists_to_search\": 0.01}'
  );\""

# =============== Gemini remote model & summarization ===============
run_step "Creating REMOTE Gemini model (gemini-pro)" \
"bq query --use_legacy_sql=false \"
CREATE OR REPLACE MODEL \\\`${PROJECT_ID}.CustomerReview.Gemini\\\`
REMOTE WITH CONNECTION \\\`us.embedding_conn\\\`
OPTIONS (ENDPOINT = 'gemini-pro');\""

echo -e "${CLR_ACCENT}Generating summary from retrieved reviews...${CLR_RESET}"
bq query --use_legacy_sql=false "
SELECT ml_generate_text_llm_result AS generated
FROM ML.GENERATE_TEXT(
  MODEL \`${PROJECT_ID}.CustomerReview.Gemini\`,
  (
    SELECT CONCAT(
      'Summarize what customers think about our services\n\n',
      STRING_AGG(FORMAT('review text: %s', base.content), ',\n')
    ) AS prompt
    FROM \`${PROJECT_ID}.CustomerReview.vector_search_result\` AS base
  ),
  STRUCT(
    0.4 AS temperature,
    300 AS max_output_tokens,
    0.5 AS top_p,
    5 AS top_k,
    TRUE AS flatten_json_output
  )
);
echo

"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
