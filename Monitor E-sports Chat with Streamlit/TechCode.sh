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
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

clear

echo "${CYAN_TEXT}=================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}      SUBSCRIBE TECH & CODE — EXECUTING LAB SCRIPT...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}=================================================================${RESET_FORMAT}"
echo

############################################################
# TASK 1 — ENVIRONMENT VARIABLES
############################################################
echo "${BLUE_TEXT}[*] Task 1: Configure environment variables${RESET_FORMAT}"

GCP_PROJECT_ID="$(gcloud config get-value project)"
echo "${CYAN_TEXT}Detected Project: ${WHITE_TEXT}$GCP_PROJECT_ID${RESET_FORMAT}"

read -p "${YELLOW_TEXT}Enter REGION: ${RESET_FORMAT}" GCP_REGION

GEMINI_MODEL_ID="gemini-2.5-flash"
BUCKET_NAME="${GCP_PROJECT_ID}-bucket"

export GCP_PROJECT_ID GCP_REGION GEMINI_MODEL_ID BUCKET_NAME

echo "${GREEN_TEXT}[✓] Environment variables configured${RESET_FORMAT}"
sleep 1

############################################################
# CREATE BIGQUERY & BIGTABLE RESOURCES
############################################################
echo "${BLUE_TEXT}[*] Creating BigQuery dataset, tables & Bigtable${RESET_FORMAT}"

bq --location=$GCP_REGION mk -d esports_analytics >/dev/null 2>&1

bq mk --table esports_analytics.raw_chat_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

bq mk --table --description "Unsportsmanlike" \
--time_partitioning_field timestamp --time_partitioning_type DAY \
esports_analytics.unsportsmanlike_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,message_type:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

gcloud bigtable instances create instance \
--display-name="My Bigtable Instance" \
--cluster-config=id=my-cluster,zone=${GCP_REGION}-b,nodes=1 >/dev/null 2>&1

cbt -project $GCP_PROJECT_ID -instance instance createtable unsportsmanlike families=messages >/dev/null 2>&1

echo "${GREEN_TEXT}[✓] BigQuery & Bigtable created${RESET_FORMAT}"
sleep 1

############################################################
# TASK 3 — AUTOMATIC TOPIC + SUBSCRIPTION CREATION
############################################################
echo "${BLUE_TEXT}[*] Task 3: Creating Pub/Sub topic & BigQuery subscription${RESET_FORMAT}"

if gcloud pubsub topics list --format="value(name)" | grep -q "topics/esports_messages_topic$"; then
  warn "Pub/Sub topic esports_messages_topic already exists, skipping."
else
  gcloud pubsub topics create esports_messages_topic
  ok "Created topic esports_messages_topic."
fi

PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT_ID}" --format='value(projectNumber)')"

# Grant BigQuery Data Editor to Pub/Sub service agent so it can write to the table
PUBSUB_SA="service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"
log "Granting BigQuery Data Editor to Pub/Sub service account ${PUBSUB_SA}..."

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${PUBSUB_SA}" \
  --role="roles/bigquery.dataEditor" \
  --quiet >/dev/null || warn "Pub/Sub SA IAM binding may already exist."

ok "Pub/Sub service account has BigQuery Data Editor at project-level."

# Create subscription that writes directly to BigQuery raw_chat_messages
if gcloud pubsub subscriptions list --format="value(name)" | grep -q "subscriptions/esports_messages_topic-sub$"; then
  warn "Subscription esports_messages_topic-sub already exists, skipping."
else
  gcloud pubsub subscriptions create esports_messages_topic-sub \
    --topic=esports_messages_topic \
    --bigquery-table="${GCP_PROJECT_ID}:esports_analytics.raw_chat_messages" \
    --use-table-schema
  ok "Subscription esports_messages_topic-sub created and configured to write to BigQuery."
fi
############################################################
# MANUAL IAM REQUIRED (YOU ASKED)
############################################################

echo
echo "${MAGENTA_TEXT}===== MANUAL IAM STEPS REQUIRED =====${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}1) Go to BigQuery console${RESET_FORMAT}"
echo "${WHITE_TEXT}2) Dataset: esports_analytics → Share Dataset${RESET_FORMAT}"
echo "${WHITE_TEXT}3) Add principal: Pub/Sub SA (shown in subscription error if any)${RESET_FORMAT}"
echo "${WHITE_TEXT}4) Role: BigQuery Data Editor${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}5) Go to IAM & Admin${RESET_FORMAT}"
echo "${WHITE_TEXT}6) Add role Pub/Sub Publisher to compute service account${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}After finishing IAM steps, press Y to continue...${RESET_FORMAT}"
echo

read -p "Continue? (Y/N): " ANSWER

if [[ $ANSWER != "Y" && $ANSWER != "y" ]]; then
    echo "${RED_TEXT}Stopping script — complete IAM first${RESET_FORMAT}"
    exit 1
fi

############################################################
# TASK 5 — DOWNLOAD PYTHON FILES
############################################################
echo "${BLUE_TEXT}[*] Task 5: Downloading Python files${RESET_FORMAT}"

mkdir -p ~/esports
cd ~/esports

wget -q https://storage.googleapis.com/spls/gsp1343/v2/message_generator.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/app.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/requirements.txt

gsutil cp message_generator.py gs://$BUCKET_NAME >/dev/null

echo "${GREEN_TEXT}[✓] Task 5 completed${RESET_FORMAT}"

############################################################
# TASK 6 — SYNTHETIC DATA GENERATOR
############################################################
echo "${BLUE_TEXT}[*] Task 6: Installing Pub/Sub python library${RESET_FORMAT}"

pip install --user google-cloud-pubsub >/dev/null

echo "${LIME_TEXT}[✓] python pubsub installed${RESET_FORMAT}"

echo "${CYAN_TEXT}${UNDERLINE_TEXT}Starting message generator — DO NOT CLOSE THIS TAB${RESET_FORMAT}"
echo "${GOLD_TEXT}If messages publish, Task 6 is successful${RESET_FORMAT}"
echo

python3 message_generator.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
