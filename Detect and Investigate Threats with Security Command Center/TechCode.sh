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


# Get zone and region
echo "Getting compute zone and region..."
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Save IAM policy to JSON
echo "Getting IAM policy..."
gcloud projects get-iam-policy $(gcloud config get-value project) \
    --format=json > policy.json

# Modify IAM policy
echo "Updating IAM policy..."
jq '{ 
  "auditConfigs": [ 
    { 
      "service": "cloudresourcemanager.googleapis.com", 
      "auditLogConfigs": [ 
        { 
          "logType": "ADMIN_READ" 
        } 
      ] 
    } 
  ] 
} + .' policy.json > updated_policy.json

# Apply updated IAM policy
echo "Applying IAM policy..."
gcloud projects set-iam-policy $(gcloud config get-value project) updated_policy.json

# Enable Security Center API
echo "Enabling Security Center API..."
gcloud services enable securitycenter.googleapis.com --project=$DEVSHELL_PROJECT_ID

# Wait for API to activate
echo "Waiting 20 seconds..."
sleep 20

# Grant BigQuery Admin role
echo "Granting BigQuery Admin role..."
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin

# Revoke BigQuery Admin role
echo "Revoking BigQuery Admin role..."
gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin

# Grant IAM Admin role to user
echo "Granting IAM Admin role..."
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/cloudresourcemanager.projectIamAdmin 2>/dev/null

# Create VM instance
echo "Creating VM instance..."
gcloud compute instances create instance-1 \
--zone=$ZONE \
--machine-type=e2-medium \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
--metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD \
--scopes=https://www.googleapis.com/auth/cloud-platform --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230912,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced

# Create DNS policy
echo "Creating DNS policy..."
gcloud dns --project=$DEVSHELL_PROJECT_ID policies create dns-test-policy --description="quickgcplab" --networks="default" --private-alternative-name-servers="" --no-enable-inbound-forwarding --enable-logging

# Wait for DNS policy to apply
echo "Waiting 30 seconds..."
sleep 30

# SSH into VM and run commands
echo "Connecting to VM and running commands..."
gcloud compute ssh instance-1 --zone=$ZONE --tunnel-through-iap --project "$DEVSHELL_PROJECT_ID" --quiet --command "gcloud projects get-iam-policy \$(gcloud config get project) && curl etd-malware-trigger.goog"

# Prompt user to confirm progress
function check_progress {
    while true; do
        echo
        read -p "Make sure to check your progress for Task 1 & Task 2 before moving further. (Y/N): " user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo "Continuing to next steps..."
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo "Please check your progress, then type Y to continue."
        else
            echo "Invalid input. Please enter Y or N."
        fi
    done
}

check_progress

# Delete VM
echo "Deleting VM..."
gcloud compute instances delete instance-1 --zone=$ZONE --quiet

echo "Done."

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
