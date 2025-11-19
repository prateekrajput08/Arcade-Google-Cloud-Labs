#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

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

# Step 1: Enable Cloud Run API
echo "${CYAN_TEXT}_TEXT${BOLD_TEXT}Enabling Cloud Run API...${RESET_FORMAT}"
gcloud services enable run.googleapis.com

# Step 2: Clone the repository
echo "${GREEN_TEXT}${BOLD_TEXT}Cloning Google Cloud generative AI repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/generative-ai.git

# Step 3: Navigate to the required directory
echo "${YELLOW_TEXT}${BOLD_TEXT}Navigating to the 'gemini-streamlit-cloudrun' directory...${RESET_FORMAT}"
cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

# Step 4: Copy chef.py from the cloud storage bucket
echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying 'chef.py' from Google Cloud Storage...${RESET_FORMAT}"
gsutil cp gs://spls/gsp517/chef.py .

# Step 5: Remove unnecessary files
echo "${BLUE_TEXT}${BOLD_TEXT}Removing existing files: Dockerfile, chef.py, requirements.txt...${RESET_FORMAT}"
rm -rf Dockerfile chef.py requirements.txt

# Step 6: Download required files (Add specific URLs in wget commands)
echo "${RED_TEXT}${BOLD_TEXT}Downloading required files...${RESET_FORMAT}"
wget https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/chef.py

wget https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/Dockerfile

wget https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/requirements.txt

# Step 7: Upload chef.py to the Cloud Storage bucket
echo "${_TEXT}${BOLD_TEXT}Uploading 'chef.py' to Cloud Storage bucket...${RESET_FORMAT}"
gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/

# Step 8: Set project and region variables
echo "${GREEN_TEXT}${BOLD_TEXT}Setting GCP project and region variables...${RESET_FORMAT}"
GCP_PROJECT=$(gcloud config get-value project)
GCP_REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 9: Create a virtual environment and install dependencies
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up Python virtual environment...${RESET_FORMAT}"
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt

# Step 10: Start Streamlit application
echo "${MAGENTA_TEXT}${BOLD_TEXT}Running Streamlit application in the background...${RESET_FORMAT}"
nohup streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080 > streamlit.log 2>&1 &

# Step 11: Create Artifact Repository
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Artifact Registry repository...${RESET_FORMAT}"
AR_REPO='chef-repo'
SERVICE_NAME='chef-streamlit-app' 
gcloud artifacts repositories create "$AR_REPO" --location="$GCP_REGION" --repository-format=Docker

# Step 12: Submit Cloud Build
echo "${RED_TEXT}${BOLD_TEXT}Submitting Cloud Build...${RESET_FORMAT}"
gcloud builds submit --tag "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME"

# Step 13: Deploy Cloud Run Service
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying Cloud Run service...${RESET_FORMAT}"
gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$GCP_REGION \
  --platform=managed  \
  --project=$GCP_PROJECT \
  --set-env-vars=GCP_PROJECT=$GCP_PROJECT,GCP_REGION=$GCP_REGION

# Step 14: Get Cloud Run Service URL
echo "${GREEN_TEXT}${BOLD_TEXT}Fetching Cloud Run service URL...${RESET_FORMAT}"
CLOUD_RUN_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$GCP_REGION" --format='value(status.url)')

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Streamlit running at: ${RESET_FORMAT}""http://localhost:8080"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Cloud Run Service is available at: ${RESET_FORMAT}""$CLOUD_RUN_URL"
echo


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
