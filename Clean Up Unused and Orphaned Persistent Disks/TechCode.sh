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

# Step 1: Set ZONE and REGION variables
echo "${BOLD}${YELLOW}Setting compute zone and region variables...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Set compute region
echo "${BOLD}${BLUE}Configuring compute region...${RESET}"
gcloud config set compute/region $REGION

# Step 3: Enable Cloud Scheduler API
echo "${BOLD}${MAGENTA}Enabling Cloud Scheduler API...${RESET}"
gcloud services enable cloudscheduler.googleapis.com

# Step 4: Copy required files and navigate to the working directory
echo "${BOLD}${CYAN}Copying required files and changing to the working directory...${RESET}"
gsutil cp -r gs://spls/gsp648 . && cd gsp648

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
WORKDIR=$(pwd)
cd $WORKDIR/unattached-pd

# Step 5: Modify main.py with project ID
echo "${BOLD}${RED}Updating main.py with the project ID...${RESET}"
sed -i "s/'automating-cost-optimization'/'$(echo $DEVSHELL_PROJECT_ID)'/" main.py

# Step 6: Define orphaned and unused disk names
echo "${BOLD}${GREEN}Setting disk names...${RESET}"
export ORPHANED_DISK=orphaned-disk
export UNUSED_DISK=unused-disk

# Step 7: Create orphaned and unused disks
echo "${BOLD}${YELLOW}Creating orphaned and unused disks...${RESET}"
gcloud compute disks create $ORPHANED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

gcloud compute disks create $UNUSED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

# Step 8: List all disks
echo "${BOLD}${BLUE}Listing all disks...${RESET}"
gcloud compute disks list

# Step 9: Create an instance and attach the orphaned disk
echo "${BOLD}${MAGENTA}Creating an instance and attaching the orphaned disk...${RESET}"
gcloud compute instances create disk-instance \
--zone=$ZONE \
--machine-type=e2-medium \
--disk=name=$ORPHANED_DISK,device-name=$ORPHANED_DISK,mode=rw,boot=no

# Step 10: Describe the orphaned disk
echo "${BOLD}${CYAN}Describing the orphaned disk...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress upto Task 3 ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress upto Task 3 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 11: Detach the orphaned disk
echo "${BOLD}${RED}Detaching the orphaned disk...${RESET}"
gcloud compute instances detach-disk disk-instance --device-name=$ORPHANED_DISK --zone=$ZONE

# Step 12: Describe the orphaned disk again
echo "${BOLD}${GREEN}Describing the orphaned disk after detachment...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Step 13: Disable and re-enable Cloud Functions API
echo "${BOLD}${YELLOW}Disabling and re-enabling Cloud Functions API...${RESET}"
gcloud services disable cloudfunctions.googleapis.com

sleep 5

gcloud services enable cloudfunctions.googleapis.com

sleep 30

# Step 14: Add IAM policy binding for Artifact Registry reader role
echo "${BOLD}${BLUE}Adding IAM policy binding for Artifact Registry reader...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:qwiklabs-gcp-01-7864202acea1@appspot.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 15: Enable Cloud Run API
echo "${BOLD}${MAGENTA}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com

sleep 30

# Step 16: Deploy the Cloud Function
echo "${BOLD}${CYAN}Deploying the Cloud Function...${RESET}"
cd ~/gsp648/unattached-pd
gcloud functions deploy delete_unattached_pds --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 17: Get the Cloud Function URL
echo "${BOLD}${RED}Fetching the Cloud Function URL...${RESET}"
export FUNCTION_URL=$(gcloud functions describe delete_unattached_pds --format=json --region $REGION | jq -r '.url')

# Step 18: Create an App Engine application
echo "${BOLD}${GREEN}Creating an App Engine application...${RESET}"
gcloud app create --region=$REGION

# Step 29: Create a Cloud Scheduler job
echo "${BOLD}${YELLOW}Creating a Cloud Scheduler job...${RESET}"
gcloud scheduler jobs create http unattached-pd-job \
--schedule="* 2 * * *" \
--uri=$FUNCTION_URL \
--location=$REGION

sleep 60

# Step 20: Run the Cloud Scheduler job
echo "${BOLD}${BLUE}Running the Cloud Scheduler job...${RESET}"
gcloud scheduler jobs run unattached-pd-job \
--location=$REGION

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
