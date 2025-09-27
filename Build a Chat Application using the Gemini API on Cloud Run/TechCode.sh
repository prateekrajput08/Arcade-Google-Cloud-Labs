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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Exit if any command fails
set -e

read -p "Enter the deployment region (e.g., us-central1, europe-west4): " REGION
if [[ -z "$REGION" ]]; then
  echo "Region is required. Exiting."
  exit 1
fi


# === Project Setup ===
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID
export REGION
export AR_REPO='chat-app-repo'
export SERVICE_NAME='chat-flask-app'

echo "   Using:"
echo "   ➤ Project: $PROJECT_ID"
echo "   ➤ Region:  $REGION"
echo "   ➤ Repo:    $AR_REPO"
echo "   ➤ Service: $SERVICE_NAME"

# === Enable Required Services ===
echo "Enabling required services..."
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com

# === Download App Source ===
echo "Downloading sample app source..."
gsutil cp -R gs://spls/gsp1201/chat-flask-cloudrun .
cd chat-flask-cloudrun || exit

# === Create Artifact Registry Repo ===
echo "Creating Artifact Registry (if needed)..."
gcloud artifacts repositories create "$AR_REPO" \
  --location="$REGION" \
  --repository-format=Docker || echo "Repo may already exist."


# === Docker Auth ===
echo "Configuring Docker authentication..."
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# === Build & Push Docker Image ===
echo "Building and pushing image to Artifact Registry..."
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"

# === Deploy to Cloud Run ===
echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME:latest" \
  --allow-unauthenticated \
  --region="$REGION" \
  --platform=managed \
  --project="$PROJECT_ID" \
  --set-env-vars=GCP_PROJECT="$PROJECT_ID",GCP_REGION="$REGION"

echo ""
echo "Deployment complete!"
echo "Visit the service URL shown above to test your app."

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
