
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

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 1: Configure environment variables${RESET_FORMAT}"

GCP_PROJECT_ID="$(gcloud config get-value project)"

# auto detect region or fallback
AUTO_REGION="$(gcloud config get-value compute/region 2>/dev/null)"

if [[ -z "$AUTO_REGION" || "$AUTO_REGION" == "(unset)" ]]; then
    AUTO_REGION="us-central1"
fi

GCP_REGION="$AUTO_REGION"
GEMINI_MODEL_ID="gemini-2.5-flash"
BUCKET_NAME="${GCP_PROJECT_ID}-bucket"

export GCP_PROJECT_ID GCP_REGION GEMINI_MODEL_ID BUCKET_NAME

echo "${WHITE_TEXT}${BOLD_TEXT}Project: ${GCP_PROJECT_ID}${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Region (Auto): ${GCP_REGION}${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Bucket: ${BUCKET_NAME}${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Gemini Model: ${GEMINI_MODEL_ID}${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Task 1 environment configured successfully${RESET_FORMAT}"
sleep 1

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 1: Creating BigQuery dataset, tables and Bigtable instance${RESET_FORMAT}"

# Dataset
bq --location=$GCP_REGION mk -d esports_analytics >/dev/null 2>&1

# Raw messages table
bq mk --table esports_analytics.raw_chat_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

# Unsportsmanlike table
bq mk --table --description "Unsportsmanlike" \
--time_partitioning_field timestamp --time_partitioning_type DAY \
esports_analytics.unsportsmanlike_messages \
message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,message_type:STRING,game_id:STRING,server_region:STRING >/dev/null 2>&1

# Bigtable Instance + Table
gcloud bigtable instances create instance \
--display-name="My Bigtable Instance" \
--cluster-config=id=my-cluster,zone=${GCP_REGION}-b,nodes=1 >/dev/null 2>&1

cbt -project $GCP_PROJECT_ID -instance instance createtable unsportsmanlike families=messages >/dev/null 2>&1

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] BigQuery and Bigtable resources created${RESET_FORMAT}"
sleep 1

#####################################
# MANUAL TASK SECTION
#####################################
echo "
${WHITE_TEXT}${BOLD_TEXT}✔ Task 2 — MANUAL:
   - Create Pub/Sub topic
   - Create BigQuery write subscription${RESET_FORMAT}

${WHITE_TEXT}${BOLD_TEXT}✔ Task 3 — MANUAL:
   - Go to BigQuery dataset
   - Add Pub/Sub service account
   - Role = BigQuery Data Editor${RESET_FORMAT}

${MAGENTA_TEXT}${BOLD_TEXT}NOTE: Without these streaming will not work${RESET_FORMAT}
"

echo "${CYAN_TEXT}${BOLD_TEXT}After completing the above manual tasks, type Y to continue${RESET_FORMAT}"
read -p "Continue? (Y/N): " ANSWER

if [[ $ANSWER != "Y" && $ANSWER != "y" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Stopping script - Complete manual tasks first${RESET_FORMAT}"
    exit 1
fi

echo "${TEAL_TEXT}${BOLD_TEXT}# Running Task 5 and Task 6 automatically...${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 5: Downloading Python files...${RESET_FORMAT}"

mkdir -p ~/esports
cd ~/esports

wget -q https://storage.googleapis.com/spls/gsp1343/v2/message_generator.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/app.py
wget -q https://storage.googleapis.com/spls/gsp1343/v2/requirements.txt

gsutil cp message_generator.py gs://$BUCKET_NAME

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Task 5 completed${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 6: Preparing synthetic data generator...${RESET_FORMAT}"

pip install google-cloud-pubsub >/dev/null 2>&1

echo "${LIME_TEXT}${BOLD_TEXT}[✓] Python dependencies installed${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}STARTING MESSAGE GENERATOR (DO NOT CLOSE THIS TAB)${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}If messages are publishing, Task 6 is successful${RESET_FORMAT}"
echo

python3 message_generator.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
