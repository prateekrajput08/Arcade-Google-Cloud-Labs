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
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Task 1: Env setup
echo "${BLUE_TEXT}[*] Task 1: Configure environment variables${RESET_FORMAT}"

GCP_PROJECT_ID="$(gcloud config get-value project)"
echo "${CYAN_TEXT}Detected Project: ${WHITE_TEXT}$GCP_PROJECT_ID${RESET_FORMAT}"

read -p "${YELLOW_TEXT}Enter REGION: ${RESET_FORMAT}" GCP_REGION

GEMINI_MODEL_ID="gemini-2.5-flash"
BUCKET_NAME="${GCP_PROJECT_ID}-bucket"

export GCP_PROJECT_ID GCP_REGION GEMINI_MODEL_ID BUCKET_NAME

echo "${GREEN_TEXT}[✓] Environment variables configured${RESET_FORMAT}"
sleep 1

# Task 1: Create BigQuery and Bigtable resources
echo "${BLUE_TEXT}[*] Creating BigQuery dataset, tables and Bigtable${RESET_FORMAT}"

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

echo "${GREEN_TEXT}[✓] BigQuery and Bigtable resources created${RESET_FORMAT}"
sleep 1

# Task 3: Topic auto + subscription (PULL)
echo "${BLUE_TEXT}[*] Task 3: Creating Pub/Sub topic & subscription${RESET_FORMAT}"

if gcloud pubsub topics list --format="value(name)" | grep -q "topics/esports_messages_topic$"; then
  echo "${YELLOW_TEXT}[!] Topic already exists${RESET_FORMAT}"
else
  gcloud pubsub topics create esports_messages_topic >/dev/null
  echo "${GREEN_TEXT}[✓] Topic esports_messages_topic created${RESET_FORMAT}"
fi

echo "${BLUE_TEXT}[*] Creating subscription esports_messages_topic-sub (PULL TYPE)${RESET_FORMAT}"

if gcloud pubsub subscriptions list --format="value(name)" | grep -q "subscriptions/esports_messages_topic-sub$"; then
    echo "${YELLOW_TEXT}[!] Subscription already exists${RESET_FORMAT}"
else
    gcloud pubsub subscriptions create esports_messages_topic-sub \
        --topic=esports_messages_topic >/dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        echo "${RED_TEXT}[!] Subscription could not be created${RESET_FORMAT}"
        exit 1
    else
        echo "${GREEN_TEXT}[✓] Subscription created${RESET_FORMAT}"
    fi
fi

# Print service accounts
PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT_ID}" --format='value(projectNumber)')"
PUBSUB_SA="service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Manual instructions
echo
echo "${MAGENTA_TEXT}===== MANUAL STEPS REQUIRED BEFORE CONTINUING =====${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}STEP-1: Go to Pub/Sub → subscriptions → esports_messages_topic-sub → EDIT${RESET_FORMAT}"
echo "${WHITE_TEXT}Change DELIVERY TYPE to: Write to BigQuery${RESET_FORMAT}"
echo "${WHITE_TEXT}Dataset: esports_analytics${RESET_FORMAT}"
echo "${WHITE_TEXT}Table: raw_chat_messages${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}STEP-2: BigQuery Dataset → Share → Add THIS principal:${RESET_FORMAT}"
echo "${CYAN_TEXT}${PUBSUB_SA}${RESET_FORMAT}"
echo "${WHITE_TEXT}Role: BigQuery Data Editor${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}STEP-3: IAM & Admin → Add THIS principal:${RESET_FORMAT}"
echo "${CYAN_TEXT}${COMPUTE_SA}${RESET_FORMAT}"
echo "${WHITE_TEXT}Role: Pub/Sub Publisher${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}Press Y after completing all above steps${RESET_FORMAT}"
echo

read -p "Continue? (Y/N): " ANSWER

if [[ $ANSWER != "Y" && $ANSWER != "y" ]]; then
    echo "${RED_TEXT}Stopping script — complete manual IAM and DB write first${RESET_FORMAT}"
    exit 1
fi

# Task 5: Download python files
echo "${BLUE_TEXT}[*] Task 5: Download Python files${RESET_FORMAT}"

mkdir -p ~/esports
cd ~/esports

wget -q https://storage.googleapis.com/spls/gsp1343/v2/message_generator.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/app.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/requirements.txt

gsutil cp message_generator.py gs://$BUCKET_NAME >/dev/null

echo "${GREEN_TEXT}[✓] Python files downloaded${RESET_FORMAT}"

# Task 6: Install Pub/Sub library
echo "${BLUE_TEXT}[*] Task 6: Installing google-cloud-pubsub${RESET_FORMAT}"

pip install --user google-cloud-pubsub >/dev/null

echo "${LIME_TEXT}[✓] Pub/Sub library installed${RESET_FORMAT}"

echo "${CYAN_TEXT}Starting message generator — DO NOT CLOSE THIS TAB${RESET_FORMAT}"
echo "${GOLD_TEXT}If events publish, Task 6 is successful${RESET_FORMAT}"
echo

python3 message_generator.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
