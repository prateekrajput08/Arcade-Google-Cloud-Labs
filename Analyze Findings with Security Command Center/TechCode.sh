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


gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

gcloud services enable securitycenter.googleapis.com --quiet

export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

gcloud pubsub topics create projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic

gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic

echo
echo -e "\033[1;33mCreate an export-findings-pubsub\033[0m \033[1;34mhttps://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=$DEVSHELL_PROJECT_ID\033[0m"
echo

while true; do
    echo -ne "\e[1;93mDo you Want to proceed? (Y/n): \e[0m"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo -e "\e[34mRunning the command...\e[0m"
            break
            ;;
        [Nn]|"") 
            echo "Operation canceled."
            break
            ;;
        *) 
            echo -e "\e[31mInvalid input. Please enter Y or N.\e[0m" 
            ;;
    esac
done

gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform

bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset

gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet

for i in {0..2}; do
gcloud iam service-accounts create sccp-test-sa-$i;
gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
--iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com;
done

query_findings() {
  bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}

has_findings() {
  echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
}
wait_for_findings() {
  while true; do
    result=$(query_findings)
    
    if has_findings "$result"; then
      echo "Findings detected!"
      echo "$result"
      break
    else
      echo "No findings yet. Waiting for 100 seconds..."
      sleep 100
    fi
  done
}
wait_for_findings

gsutil mb -l $REGION gs://$BUCKET_NAME/
gsutil pap set enforced gs://$BUCKET_NAME

sleep 20

gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl

sleep 20

gsutil cp findings.jsonl gs://$BUCKET_NAME/

echo
echo -e "\033[1;33mCreate an old_findings\033[0m \033[1;34mhttps://console.cloud.google.com/bigquery?project=$DEVSHELL_PROJECT_ID\033[0m"
echo

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
