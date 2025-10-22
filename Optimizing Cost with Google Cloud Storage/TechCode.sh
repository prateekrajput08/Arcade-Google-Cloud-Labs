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

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Set compute region, project ID & project number
echo "${BOLD}${YELLOW}Setting region, project ID & project number${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Step 2: Enable required services
echo "${BOLD}${CYAN}Enabling Cloud Scheduler and Cloud Run APIs${RESET}"
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

# Step 3: Add IAM policy binding for Artifact Registry
echo "${BOLD}${RED}Granting Artifact Registry reader role to Compute Engine default service account${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 4: Copy training files and move into directory
echo "${BOLD}${GREEN}Copying training files and changing directory${RESET}"
gcloud storage cp -r gs://spls/gsp649/* . && cd gcf-automated-resource-cleanup/
WORKDIR=$(pwd)

# Step 5: Install apache2-utils
echo "${BOLD}${BLUE}Installing apache2-utils${RESET}"
sudo apt-get update
sudo apt-get install apache2-utils -y

# Step 6: Move to migrate-storage directory
echo "${BOLD}${MAGENTA}Moving to migrate-storage directory${RESET}"
cd $WORKDIR/migrate-storage

# Step 7: Create public serving bucket
echo "${BOLD}${CYAN}Creating public serving bucket${RESET}"
gcloud storage buckets create  gs://${PROJECT_ID}-serving-bucket -l $REGION

# Step 8: Make entire bucket publicly readable
echo "${BOLD}${RED}Making serving bucket publicly readable${RESET}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket

# Step 9: Upload test file to serving bucket
echo "${BOLD}${GREEN}Uploading testfile.txt to serving bucket${RESET}"
gcloud storage cp $WORKDIR/migrate-storage/testfile.txt  gs://${PROJECT_ID}-serving-bucket

# Step 10: Make test file publicly accessible
echo "${BOLD}${YELLOW}Making testfile.txt publicly accessible${RESET}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket/testfile.txt

# Step 11: Test file availability via curl
echo "${BOLD}${BLUE}Testing public access to testfile.txt${RESET}"
curl http://storage.googleapis.com/${PROJECT_ID}-serving-bucket/testfile.txt

# Step 12: Create idle bucket
echo "${BOLD}${MAGENTA}Creating idle bucket${RESET}"
gcloud storage buckets create gs://${PROJECT_ID}-idle-bucket -l $REGION
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket

# Step 13: View function call in main.py
echo "${BOLD}${CYAN}Viewing migrate_storage call in main.py${RESET}"
cat $WORKDIR/migrate-storage/main.py | grep "migrate_storage(" -A 15

# Step 14: Replace placeholder with actual project ID
echo "${BOLD}${RED}Replacing <project-id> in main.py${RESET}"
sed -i "s/<project-id>/$PROJECT_ID/" $WORKDIR/migrate-storage/main.py

# Step 15: Disable Cloud Functions temporarily
echo "${BOLD}${GREEN}Disabling Cloud Functions API temporarily${RESET}"
gcloud services disable cloudfunctions.googleapis.com

# Step 16: Wait 10 seconds
echo "${BOLD}${YELLOW}Sleeping for 10 seconds...${RESET}"
sleep 10

# Step 17: Re-enable Cloud Functions
echo "${BOLD}${BLUE}Re-enabling Cloud Functions API${RESET}"
gcloud services enable cloudfunctions.googleapis.com

# Step 18: Deploy the function using Cloud Functions Gen2
echo "${BOLD}${MAGENTA}Deploying Cloud Function (Gen2)${RESET}"
gcloud functions deploy migrate_storage --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 19: Fetch the function URL
echo "${BOLD}${CYAN}Fetching deployed function URL${RESET}"
export FUNCTION_URL=$(gcloud functions describe migrate_storage --format=json --region $REGION | jq -r '.url')

# Step 20: Replace IDLE_BUCKET_NAME placeholder in incident.json
echo "${BOLD}${RED}Replacing IDLE_BUCKET_NAME placeholder in incident.json${RESET}"
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket
sed -i "s/\\\$IDLE_BUCKET_NAME/$IDLE_BUCKET_NAME/" $WORKDIR/migrate-storage/incident.json

# Step 21: Trigger the function using curl
echo "${BOLD}${GREEN}Triggering function via HTTP request${RESET}"
envsubst < $WORKDIR/migrate-storage/incident.json | curl -X POST -H "Content-Type: application/json" $FUNCTION_URL -d @-

# Step 22: Verify default storage class
echo "${BOLD}${YELLOW}Verifying default storage class for idle bucket${RESET}"
gsutil defstorageclass get gs://$PROJECT_ID-idle-bucket

echo

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
