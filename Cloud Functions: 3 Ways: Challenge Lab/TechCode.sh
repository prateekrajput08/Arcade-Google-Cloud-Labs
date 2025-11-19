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


# --- VALIDATE REQUIRED VARIABLES ---
if [[ -z "$REGION" || -z "$FUNCTION_NAME" || -z "$HTTP_FUNCTION" ]]; then
    echo "${RED}${BOLD}ERROR: REGION, FUNCTION_NAME or HTTP_FUNCTION is NOT set!${RESET}"
    exit 1
fi

# --- ENABLE REQUIRED APIs ---
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

sleep 20

# --- IAM Settings ---
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

# --- CREATE BUCKET (Bucket name must NOT include gs://) ---
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

export BUCKET_NAME="$DEVSHELL_PROJECT_ID"

# -------------------------------------------------
# CLOUD STORAGE FUNCTION (Task 2)
# -------------------------------------------------

mkdir ~/$FUNCTION_NAME && cd ~/$FUNCTION_NAME

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

deploy_cs_function() {
  gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime nodejs20 \
    --entry-point $FUNCTION_NAME \
    --source . \
    --region $REGION \
    --trigger-bucket=$BUCKET_NAME \
    --max-instances=2 \
    --quiet
}

echo "${CYAN}${BOLD}Deploying Cloud Storage function...${RESET}"

while true; do
  deploy_cs_function

  if gcloud run services describe $FUNCTION_NAME --region $REGION &>/dev/null; then
      echo "${GREEN}${BOLD}Cloud Storage function deployed successfully!${RESET}"
      break
  else
      echo "${YELLOW}Waiting for deployment...${RESET}"
      sleep 10
  fi
done

cd ~

# -------------------------------------------------
# HTTP FUNCTION (Task 3)
# -------------------------------------------------

mkdir ~/$HTTP_FUNCTION && cd ~/$HTTP_FUNCTION

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('awesome lab');
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

deploy_http_function() {
  gcloud functions deploy $HTTP_FUNCTION \
    --gen2 \
    --runtime nodejs20 \
    --entry-point $HTTP_FUNCTION \
    --source . \
    --region $REGION \
    --trigger-http \
    --timeout 600s \
    --max-instances 2 \
    --min-instances 1 \
    --quiet
}

echo "${CYAN}${BOLD}Deploying HTTP function...${RESET}"

while true; do
  deploy_http_function

  if gcloud run services describe $HTTP_FUNCTION --region $REGION &>/dev/null; then
      echo "${GREEN}${BOLD}HTTP function deployed successfully!${RESET}"
      break
  else
      echo "${YELLOW}Waiting for HTTP service deployment...${RESET}"
      sleep 10
  fi
done



# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
