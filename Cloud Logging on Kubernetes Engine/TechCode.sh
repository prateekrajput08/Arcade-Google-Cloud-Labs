#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

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

# ========================= AUTH CHECK =========================
echo "${CYAN_TEXT}${BOLD_TEXT}Checking active gcloud authentication...${RESET_FORMAT}"
gcloud auth list

# ========================= SET ZONE & REGION =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Fetching default compute zone and region...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# ========================= SET PROJECT =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Setting active GCP project...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $DEVSHELL_PROJECT_ID

# ========================= APPLY CONFIG =========================
echo "${TEAL_TEXT}${BOLD_TEXT}Applying compute zone and region configuration...${RESET_FORMAT}"
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# ========================= CLONE REPOSITORY =========================
echo "${GREEN_TEXT}${BOLD_TEXT}Cloning GKE logging sinks demo repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/gke-logging-sinks-demo

sleep 10
cd gke-logging-sinks-demo
sleep 10

# ========================= TERRAFORM PROVIDER UPDATE =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating Terraform provider version...${RESET_FORMAT}"
sed -i 's/  version = "~> 2.11.0"/  version = "~> 2.19.0"/g' terraform/provider.tf

# ========================= LOG FILTER UPDATE =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating logging filter to k8s_container...${RESET_FORMAT}"
sed -i 's/  filter      = "resource.type = container"/  filter      = "resource.type = k8s_container"/g' terraform/main.tf

# ========================= CREATE INFRASTRUCTURE =========================
echo "${LIME_TEXT}${BOLD_TEXT}Creating infrastructure using make...${RESET_FORMAT}"
make create

# ========================= VALIDATE DEPLOYMENT =========================
echo "${LIME_TEXT}${BOLD_TEXT}Validating deployment...${RESET_FORMAT}"
make validate

# ========================= READ LOGS =========================
echo "${NAVY_TEXT}${BOLD_TEXT}Reading Kubernetes container logs...${RESET_FORMAT}"
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$PROJECT_ID

# ========================= READ LOGS (JSON FORMAT) =========================
echo "${NAVY_TEXT}${BOLD_TEXT}Reading Kubernetes logs in JSON format...${RESET_FORMAT}"
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" \
  --project=$PROJECT_ID \
  --format=json

# ========================= CREATE LOGGING SINK =========================
echo "${MAROON_TEXT}${BOLD_TEXT}Creating BigQuery logging sink...${RESET_FORMAT}"
gcloud logging sinks create techcps \
  bigquery.googleapis.com/projects/$PROJECT_ID/datasets/bq_logs \
  --log-filter='resource.type="k8s_container" resource.labels.cluster_name="stackdriver-logging"' \
  --include-children \
  --format='json'

sleep 20

# ========================= QUERY BIGQUERY LOGS =========================
echo "${GOLD_TEXT}${BOLD_TEXT}Querying logs from BigQuery dataset...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT *
FROM \`$DEVSHELL_PROJECT_ID.gke_logs_dataset.diagnostic_log_*\`
WHERE _TABLE_SUFFIX BETWEEN
FORMAT_DATE('%Y%m%d', CURRENT_DATE() - INTERVAL 1 DAY)
AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
