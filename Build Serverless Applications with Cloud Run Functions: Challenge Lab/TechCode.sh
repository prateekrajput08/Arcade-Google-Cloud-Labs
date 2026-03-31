#!/bin/bash

# Color Codes
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Ask user for inputs
echo "${YELLOW_TEXT}Enter Event Function Name:${RESET_FORMAT}"
read FUNCTION_NAME

echo "${YELLOW_TEXT}Enter HTTP Function Name:${RESET_FORMAT}"
read HTTP_FUNCTION

DEFAULT_REGION=$(gcloud functions regions list --format="value(name)" 2>/dev/null | head -n 1)
DEFAULT_REGION=${DEFAULT_REGION:-us-central1}

echo "${CYAN_TEXT}Enter region [default: $DEFAULT_REGION]:${RESET_FORMAT}"
read REGION

REGION=${REGION:-$DEFAULT_REGION}

echo "${GREEN_TEXT}Using region: $REGION${RESET_FORMAT}"

# Enable APIs
echo "${YELLOW_TEXT}Enabling required services...${RESET_FORMAT}"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

echo "${BLUE_TEXT}Fetching project details...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

echo "${YELLOW_TEXT}Assigning IAM roles...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

echo "${GREEN_TEXT}Creating storage bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID
export BUCKET="gs://$DEVSHELL_PROJECT_ID"

echo "${MAGENTA_TEXT}Setting up Event-driven function...${RESET_FORMAT}"

mkdir -p ~/$FUNCTION_NAME
cd ~/$FUNCTION_NAME

touch index.js package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "${YELLOW_TEXT}Waiting before deployment...${RESET_FORMAT}"

sleep 60

echo "${GREEN_TEXT}Deploying Event-driven function...${RESET_FORMAT}"
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime nodejs20 \
  --entry-point $FUNCTION_NAME \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 2

cd ..

echo "${MAGENTA_TEXT}Setting up HTTP function...${RESET_FORMAT}"

mkdir -p ~/$FUNCTION_NAME
cd ~/$FUNCTION_NAME

touch index.js package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('subscribe to quikclab');
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "${GREEN_TEXT}Deploying HTTP function...${RESET_FORMAT}"
gcloud functions deploy $HTTP_FUNCTION \
  --gen2 \
  --runtime nodejs20 \
  --entry-point $HTTP_FUNCTION \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 2 \
  --min-instances 1

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
