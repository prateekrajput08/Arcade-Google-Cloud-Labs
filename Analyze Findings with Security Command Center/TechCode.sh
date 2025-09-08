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
COLOR_RED=$'\033[0;91m'
COLOR_GREEN=$'\033[0;92m'
COLOR_YELLOW=$'\033[0;93m'
COLOR_BLUE=$'\033[0;94m'
COLOR_CYAN=$'\033[0;96m'
COLOR_WHITE=$'\033[0;97m'
STYLE_BOLD=$'\033[1m'
FORMAT_RESET=$'\033[0m'
BG_BLUE=$'\033[44m'
FG_WHITE=$'\033[97m'
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

# Function to display spinner
show_spinner() {
    local pid=$!
    local delay=0.1
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    
    tput civis
    while kill -0 $pid 2>/dev/null; do
        for char in "${spin_chars[@]}"; do
            printf "\r${COLOR_CYAN}${STYLE_BOLD}${char}${FORMAT_RESET} $1 "
            sleep $delay
        done
    done
    tput cnorm
    printf "\r${COLOR_GREEN}✔ $1 completed${FORMAT_RESET}\n"
}

# Step 1: Configure environment
echo "${COLOR_YELLOW}${STYLE_BOLD}🔧 Configuring environment variables${FORMAT_RESET}"
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo "${COLOR_GREEN}${STYLE_BOLD}✔ Environment configured${FORMAT_RESET}"
echo "${STYLE_BOLD}${COLOR_WHITE}┣ Project ID: ${PROJECT_ID}${FORMAT_RESET}"
echo "${STYLE_BOLD}${COLOR_WHITE}┣ Region: ${REGION}${FORMAT_RESET}"
echo "${STYLE_BOLD}${COLOR_WHITE}┗ Zone: ${ZONE}${FORMAT_RESET}"
echo

# Step 2: Enable Security Command Center
echo "${COLOR_CYAN}${STYLE_BOLD}🛡️ Enabling Security Command Center API${FORMAT_RESET}"
gcloud services enable securitycenter.googleapis.com --quiet &
show_spinner "Enabling API"

# Step 3: Create Pub/Sub resources
echo "${COLOR_MAGENTA}${STYLE_BOLD}📨 Setting up Pub/Sub for findings export${FORMAT_RESET}"
export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

gcloud pubsub topics create projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub topic"

gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub subscription"

echo
echo "${COLOR_WHITE}${STYLE_BOLD}🔗 Please create the export configuration:${FORMAT_RESET}"
echo "${COLOR_BLUE}https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=${PROJECT_ID}${FORMAT_RESET}"
echo

# Step 4: Confirmation prompt
while true; do
    read -p "${COLOR_YELLOW}${STYLE_BOLD}Do you want to proceed? (Y/n): ${FORMAT_RESET}" confirm
    case "$confirm" in
        [Yy]|"") 
            echo "${COLOR_GREEN}${STYLE_BOLD}Continuing with setup...${FORMAT_RESET}"
            break
            ;;
        [Nn]) 
            echo "${COLOR_RED}Operation canceled.${FORMAT_RESET}"
            exit 0
            ;;
        *) 
            echo "${COLOR_RED}Invalid input. Please enter Y or N.${FORMAT_RESET}" 
            ;;
    esac
done

# Step 5: Create compute instance
echo "${COLOR_CYAN}${STYLE_BOLD}🖥️ Creating compute instance${FORMAT_RESET}"
gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform &
show_spinner "Creating instance"

# Step 6: BigQuery setup
echo "${COLOR_BLUE}${STYLE_BOLD}📊 Setting up BigQuery dataset${FORMAT_RESET}"
bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset &
show_spinner "Creating dataset"

gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet &
show_spinner "Configuring BigQuery export"

# Step 7: Create service accounts
echo "${COLOR_MAGENTA}${STYLE_BOLD}👥 Creating service accounts${FORMAT_RESET}"
for i in {0..2}; do
    gcloud iam service-accounts create sccp-test-sa-$i &
    show_spinner "Creating service account sccp-test-sa-$i"
    
    gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
    --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com &
    show_spinner "Creating key for sccp-test-sa-$i"
done

# Step 8: Wait for findings
echo "${COLOR_YELLOW}${STYLE_BOLD}🔍 Waiting for security findings${FORMAT_RESET}"
query_findings() {
  bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}

has_findings() {
  echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
}

while true; do
    result=$(query_findings)
    
    if has_findings "$result"; then
        echo "${COLOR_GREEN}${STYLE_BOLD}✔ Findings detected!${FORMAT_RESET}"
        echo "$result"
        break
    else
        echo "${COLOR_YELLOW}No findings yet. Waiting for 100 seconds...${FORMAT_RESET}"
        sleep 100
    fi
done

# Step 9: Storage setup
echo "${COLOR_CYAN}${STYLE_BOLD}📦 Setting up Cloud Storage${FORMAT_RESET}"
gsutil mb -l $REGION gs://$BUCKET_NAME/ &
show_spinner "Creating bucket"

gsutil pap set enforced gs://$BUCKET_NAME &
show_spinner "Enabling public access prevention"

sleep 20

# Step 10: Export findings
echo "${COLOR_MAGENTA}${STYLE_BOLD}📤 Exporting findings to Cloud Storage${FORMAT_RESET}"
gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl &
show_spinner "Exporting findings"

gsutil cp findings.jsonl gs://$BUCKET_NAME/ &
show_spinner "Uploading findings to bucket"
# Final message

echo "${COLOR_WHITE}${STYLE_BOLD}Next steps:${FORMAT_RESET}"
echo "┣ View findings in BigQuery: ${COLOR_BLUE}https://console.cloud.google.com/bigquery?project=${PROJECT_ID}${FORMAT_RESET}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
