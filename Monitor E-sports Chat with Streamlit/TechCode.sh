
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

############################################
# TASK 1 — ENVIRONMENT VARIABLES
############################################
echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 1: Configure environment variables${RESET_FORMAT}"

GCP_PROJECT_ID="$(gcloud config get-value project)"
echo "${CYAN_TEXT}${BOLD_TEXT}Detected Project: ${WHITE_TEXT}$GCP_PROJECT_ID${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" GCP_REGION

GEMINI_MODEL_ID="gemini-2.5-flash"
BUCKET_NAME="${GCP_PROJECT_ID}-bucket"

export GCP_PROJECT_ID GCP_REGION GEMINI_MODEL_ID BUCKET_NAME

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Environment variables configured${RESET_FORMAT}"
sleep 1

############################################
# TASK 1 — BIGQUERY & BIGTABLE RESOURCES
############################################
echo "${BLUE_TEXT}${BOLD_TEXT}[*] Creating BigQuery dataset, tables and Bigtable instance${RESET_FORMAT}"

# BigQuery Dataset
bq --location=$GCP_REGION mk -d esports_analytics >/dev/null 2>&1

# BigQuery Table 1
bq mk --table esports_analytics.raw_chat_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

# BigQuery Table 2
bq mk --table --description "Unsportsmanlike" \
--time_partitioning_field timestamp --time_partitioning_type DAY \
esports_analytics.unsportsmanlike_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,message_type:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

# Bigtable Instance
gcloud bigtable instances create instance \
--display-name="My Bigtable Instance" \
--cluster-config=id=my-cluster,zone=${GCP_REGION}-b,nodes=1 >/dev/null 2>&1

# Bigtable Table
cbt -project $GCP_PROJECT_ID -instance instance createtable unsportsmanlike families=messages >/dev/null 2>&1

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] BigQuery & Bigtable resources created${RESET_FORMAT}"
sleep 1

############################################
# TASK 2 + TASK 3 + TASK 4 AUTOMATION
############################################
echo "${BLUE_TEXT}${BOLD_TEXT}[*] Automating Pub/Sub + IAM setup${RESET_FORMAT}"

# Project Number
PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT_ID}" --format='value(projectNumber)')"

############################################
# Create Pub/Sub Topic
############################################
if gcloud pubsub topics list --format="value(name)" | grep -q "topics/esports_messages_topic$"; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}[!] Topic esports_messages_topic already exists${RESET_FORMAT}"
else
    gcloud pubsub topics create esports_messages_topic >/dev/null
    echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Topic esports_messages_topic created${RESET_FORMAT}"
fi

############################################
# IAM — BigQuery Data Editor for Pub/Sub SA
############################################
PUBSUB_SA="service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${PUBSUB_SA}" \
  --role="roles/bigquery.dataEditor" \
  --quiet >/dev/null || echo "${YELLOW_TEXT}[!] IAM already set${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Granted BigQuery Data Editor to Pub/Sub SA${RESET_FORMAT}"

############################################
# Create BigQuery Write Subscription
############################################
if gcloud pubsub subscriptions list --format="value(name)" | grep -q "subscriptions/esports_messages_topic-sub$"; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}[!] Subscription already exists${RESET_FORMAT}"
else
    gcloud pubsub subscriptions create esports_messages_topic-sub \
      --topic=esports_messages_topic \
      --bigquery-table="${GCP_PROJECT_ID}:esports_analytics.raw_chat_messages" \
      --use-table-schema >/dev/null
    echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Subscription writing directly to BigQuery${RESET_FORMAT}"
fi

############################################
# IAM — Pub/Sub Publisher for Compute SA
############################################
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/pubsub.publisher" \
  --quiet >/dev/null || echo "${YELLOW_TEXT}[!] Compute SA IAM already exists${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Compute SA can publish to Pub/Sub${RESET_FORMAT}"
sleep 1

############################################
# TASK 5 — DOWNLOAD PYTHON FILES
############################################
echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 5: Downloading Python files${RESET_FORMAT}"

mkdir -p ~/esports
cd ~/esports

wget -q https://storage.googleapis.com/spls/gsp1343/v2/message_generator.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/app.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/requirements.txt

gsutil cp message_generator.py gs://$BUCKET_NAME >/dev/null

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Task 5 complete${RESET_FORMAT}"

############################################
# TASK 6 — SYNTHETIC DATA GENERATOR
############################################
echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 6: Installing Pub/Sub Python lib${RESET_FORMAT}"

pip install --user google-cloud-pubsub >/dev/null
echo "${LIME_TEXT}${BOLD_TEXT}[✓] python pubsub installed${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}STARTING MESSAGE GENERATOR — DO NOT CLOSE THIS TAB${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}If messages publish, Task 6 is successful${RESET_FORMAT}"
echo

python3 message_generator.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
