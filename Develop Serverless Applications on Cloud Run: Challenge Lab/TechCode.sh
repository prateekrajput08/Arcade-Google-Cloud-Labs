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
TEAL=$'\033[38;5;50m'

# Define text formatting variables
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

# Step 1: Configure Google Cloud environment for the project
echo "${BOLD}${BLUE}Configure Google Cloud environment for the project...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set project \
$(gcloud projects list --format='value(PROJECT_ID)' \
--filter='qwiklabs-gcp')

gcloud config set run/region $REGION

gcloud config set run/platform managed

# Step 2: Clone the Git repository
echo "${BOLD}${CYAN}Cloning repository...${RESET}"
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07

# Step 3: Deploy Billing Staging API
echo "${BOLD}${YELLOW}Deploying Billing Staging API...${RESET}"
cd ~/pet-theory/lab07/unit-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.1
gcloud run deploy $PUBLIC_BILLING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.1 --quiet

# Step 4: Deploy Frontend Staging
echo "${BOLD}${MAGENTA}Deploying Frontend Staging...${RESET}"
cd ~/pet-theory/lab07/staging-frontend-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1
gcloud run deploy $FRONTEND_STAGING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1 --quiet

# Step 5: Update Billing Staging API
echo "${BOLD}${RED}Updating Billing Staging API...${RESET}"
cd ~/pet-theory/lab07/staging-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.2
gcloud run deploy $PRIVATE_BILLING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.2 --quiet

# Step 6: Create IAM Service Accounts
echo "${BOLD}${GREEN}Creating IAM Service Accounts...${RESET}"
gcloud iam service-accounts create $BILLING_SERVICE_ACCOUNT --display-name "Billing Service Account Cloud Run"

# Step 7: Deploy Billing Production API
echo "${BOLD}${MAGENTA}Deploy Billing Production API...${RESET}"
cd ~/pet-theory/lab07/prod-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-prod-api:0.1
gcloud run deploy $BILLING_PROD_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-prod-api:0.1 --quiet

# Step 8: Create Frontend IAM Service Account
echo "${BOLD}${MAGENTA}Create Frontend IAM Service Account...${RESET}"
gcloud iam service-accounts create $FRONTEND_SERVICE_ACCOUNT --display-name "Billing Service Account Cloud Run Invoker"

# Step 9: Deploy Frontend Production
echo "${BOLD}${CYAN}Deploying Frontend Production...${RESET}"
cd ~/pet-theory/lab07/prod-frontend-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-prod:0.1
gcloud run deploy $FRONTEND_PRODUCTION_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-prod:0.1 --quiet

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
