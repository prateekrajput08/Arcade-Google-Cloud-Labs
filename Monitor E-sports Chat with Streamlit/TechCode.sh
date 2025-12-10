
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
echo "${CYAN_TEXT}${BOLD_TEXT}Detected Project: ${WHITE_TEXT}$GCP_PROJECT_ID${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter region from lab (example: us-central1): ${RESET_FORMAT}" GCP_REGION
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Gemini model (example: gemini-1.5-flash-002): ${RESET_FORMAT}" GEMINI_MODEL_ID

BUCKET_NAME="${GCP_PROJECT_ID}-bucket"
export GCP_PROJECT_ID GCP_REGION GEMINI_MODEL_ID BUCKET_NAME

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Environment variables configured successfully.${RESET_FORMAT}"

echo "
${WHITE_TEXT}${BOLD_TEXT}✔ Task 2 — MANUAL:
   - Create BigQuery dataset + tables
   - Create Bigtable instance + table${RESET_FORMAT}

${WHITE_TEXT}${BOLD_TEXT}✔ Task 3 — MANUAL:
   - Create Pub/Sub topic
   - Create BigQuery write subscription${RESET_FORMAT}

${WHITE_TEXT}${BOLD_TEXT}✔ Task 4 — MANUAL:
   - Go to BigQuery dataset
   - Add Pub/Sub service account
   - Role = BigQuery Data Editor${RESET_FORMAT}

${MAGENTA_TEXT}${BOLD_TEXT}NOTE: Without these, streaming will NOT work.${RESET_FORMAT}
"

echo "${CYAN_TEXT}${BOLD_TEXT}When you finish all manual steps, type Y to continue: ${RESET_FORMAT}"

read -p "Continue? (Y/N): " ANSWER

if [[ $ANSWER != "Y" && $ANSWER != "y" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Stopping script — Complete manual tasks first.${RESET_FORMAT}"
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

echo "${GREEN_TEXT}${BOLD_TEXT}[✓] Task 5 completed successfully.${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Task 6: Setting up synthetic data generator...${RESET_FORMAT}"

pip install google-cloud-pubsub >/dev/null 2>&1

export GCP_PROJECT_ID="$GCP_PROJECT_ID"
export GCP_REGION="$GCP_REGION"
export GEMINI_MODEL_ID="$GEMINI_MODEL_ID"
export BUCKET_NAME="$BUCKET_NAME"

echo "${LIME_TEXT}${BOLD_TEXT}[✓] Environment variables exported${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}Starting message generator (DO NOT CLOSE THIS TAB)...${RESET_FORMAT}"
echo
echo "${GOLD_TEXT}${BOLD_TEXT}>>> If messages are publishing, Task 6 is successful.${RESET_FORMAT}"
echo

python3 message_generator.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
