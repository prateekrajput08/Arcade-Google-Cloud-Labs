#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

run_step() {
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}▶ $1${RESET_FORMAT}"
    
    eval "$2"

    if [ $? -eq 0 ]; then
        echo "${GREEN_TEXT}✓ Success${RESET_FORMAT}"
    else
        echo "${RED_TEXT}✗ Failed${RESET_FORMAT}"
        exit 1
    fi
}

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          SUBSCRIBE TECH & CODE - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ==========================================
# Variables
# ==========================================
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="$(gcloud config get-value project)-bucket"
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${YELLOW_TEXT}Project ID : ${PROJECT_ID}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Bucket     : ${BUCKET_NAME}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Region     : ${REGION}${RESET_FORMAT}"

run_step "Cloning synthtool repository..." \
"git clone https://github.com/googleapis/synthtool"

run_step "Moving to samples directory..." \
"cd synthtool/tests/fixtures/nodejs-dlp/samples"

run_step "Installing Node.js dependencies..." \
"npm install"

run_step "Enabling DLP & KMS APIs..." \
"gcloud services enable dlp.googleapis.com cloudkms.googleapis.com --project=$PROJECT_ID"

run_step "Inspecting sample string..." \
"node inspectString.js $PROJECT_ID 'My email address is jenny@somedomain.com and you can call me at 555-867-5309' > inspected-string.txt"

run_step "Inspecting accounts.txt..." \
"node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt"

run_step "Running de-identification..." \
"node deidentifyWithMask.js $PROJECT_ID 'My order number is F12312399. Email me at anthony@somedomain.com' > de-identify-output.txt"

run_step "Redacting credit card number..." \
"node redactText.js $PROJECT_ID 'Please refund the purchase to my credit card 4012888888881881' CREDIT_CARD_NUMBER > redacted-string.txt"

run_step "Redacting phone number from image..." \
"node redactImage.js $PROJECT_ID resources/test.png '' PHONE_NUMBER ./redacted-phone.png"

run_step "Redacting email from image..." \
"node redactImage.js $PROJECT_ID resources/test.png '' EMAIL_ADDRESS ./redacted-email.png"

run_step "Uploading inspected-string.txt..." \
"gsutil cp inspected-string.txt gs://$BUCKET_NAME"

run_step "Uploading inspected-file.txt..." \
"gsutil cp inspected-file.txt gs://$BUCKET_NAME"

run_step "Uploading de-identify-output.txt..." \
"gsutil cp de-identify-output.txt gs://$BUCKET_NAME"

run_step "Uploading redacted-string.txt..." \
"gsutil cp redacted-string.txt gs://$BUCKET_NAME"

run_step "Uploading redacted-phone.png..." \
"gsutil cp redacted-phone.png gs://$BUCKET_NAME"

run_step "Uploading redacted-email.png..." \
"gsutil cp redacted-email.png gs://$BUCKET_NAME"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}Generated Files:${RESET_FORMAT}"
ls -lh *.txt *.png
