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

# Function to display spinner during long operations
show_spinner() {
    local pid=$!
    local delay=0.1
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

    tput civis
    while kill -0 $pid 2>/dev/null; do
        for char in "${spin_chars[@]}"; do
            printf "\r${char} $1 "
            sleep $delay
        done
    done
    tput cnorm
    printf "\r✔ $1 completed\n"
}

# Step 1: Configure environment
echo "Configuring environment variables"
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo "Environment configured"
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Zone: ${ZONE}"
echo

# Step 2: Enable Security Command Center API
echo "Enabling Security Command Center API"
gcloud services enable securitycenter.googleapis.com --quiet &
show_spinner "Enabling API"

# Step 3: Set up Pub/Sub topic and subscription for findings export
echo "Setting up Pub/Sub for findings export"
export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

gcloud pubsub topics create projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub topic"

gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub subscription"

# Prompt user to configure findings export in the console manually
echo
echo "Please create the export configuration:"
echo "https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=${PROJECT_ID}"
echo

# Step 4: User confirmation before proceeding
while true; do
    read -p "Do you want to proceed? (Y/n): " confirm
    case "$confirm" in
        [Yy]|"") 
            echo "Continuing with setup..."
            break
            ;;
        [Nn]) 
            echo "Operation canceled."
            exit 0
            ;;
        *) 
            echo "Invalid input. Please enter Y or N." 
            ;;
    esac
done

# Step 5: Create a compute instance
echo "Creating compute instance"
gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform &
show_spinner "Creating instance"

# Step 6: Set up BigQuery dataset and export configuration
echo "Setting up BigQuery dataset"
bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset &
show_spinner "Creating dataset"

gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet &
show_spinner "Configuring BigQuery export"

# Step 7: Create test service accounts and keys
echo "👥 Creating service accounts"
for i in {0..2}; do
    gcloud iam service-accounts create sccp-test-sa-$i &
    show_spinner "Creating service account sccp-test-sa-$i"
    
    gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
    --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com &
    show_spinner "Creating key for sccp-test-sa-$i"
done

# Step 8: Wait for findings to appear in BigQuery
echo "Waiting for security findings"
# query_findings() {
#   bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
#     "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
# }

# has_findings() {
#   echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
# }

# while true; do
#     result=$(query_findings)
    
#     if has_findings "$result"; then
#         echo "Findings detected!"
#         echo "$result"
#         break
#     else
#         echo "No findings yet. Waiting for 100 seconds..."
#         sleep 100
#     fi
# done


# Function to query findings in BigQuery
query_findings() {
  bq query --use_legacy_sql=false --format=json \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}

# Function to check if findings exist using jq
has_findings() {
  echo "$1" | jq -e 'length > 0' >/dev/null 2>&1
}

# Retry for up to 15 minutes (9 attempts every 100 seconds)
MAX_ATTEMPTS=3
attempt=1

echo "Checking for findings in BigQuery..."
while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "Attempt $attempt of $MAX_ATTEMPTS..."
    
    result=$(query_findings)

    if has_findings "$result"; then
        echo "Findings detected!"
        echo "$result" | jq
        break
    else
        echo "No findings yet. Waiting for 100 seconds..."
        sleep 100
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $MAX_ATTEMPTS ]; then
    echo "No findings detected after $((MAX_ATTEMPTS * 100 / 60)) minutes. Exiting..."
    # exit 1
fi



# Step 9: Set up Cloud Storage bucket
echo "Setting up Cloud Storage"
gsutil mb -l $REGION gs://$BUCKET_NAME/ &
show_spinner "Creating bucket"

gsutil pap set enforced gs://$BUCKET_NAME &
show_spinner "Enabling public access prevention"

sleep 20

# Step 10: Export findings to Cloud Storage
echo "Exporting findings to Cloud Storage"
gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl &
show_spinner "Exporting findings"

gsutil cp findings.jsonl gs://$BUCKET_NAME/ &
show_spinner "Uploading findings to bucket"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo

echo "Next steps:"
echo "┣ View findings in BigQuery: https://console.cloud.google.com/bigquery?project=${PROJECT_ID}"
