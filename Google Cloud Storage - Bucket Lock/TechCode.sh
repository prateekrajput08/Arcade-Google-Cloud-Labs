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

export BUCKET=$(gcloud config get-value project)
gsutil mb "gs://$BUCKET"
sleep 10
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_transactions"
sleep 10
gsutil retention lock "gs://$BUCKET/"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"
gsutil rm "gs://$BUCKET/dummy_transactions"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"
# Create the file locally
echo "Dummy loan content for retention testing" > dummy_loan
# Set default event-based hold on the bucket
gsutil retention event-default set "gs://$BUCKET/"
# Upload the file to the bucket
gsutil cp dummy_loan "gs://$BUCKET/"
# Verify the hold is enabled on the uploaded object
gsutil ls -L "gs://$BUCKET/dummy_loan"
# Release the event-based hold
gsutil retention event release "gs://$BUCKET/dummy_loan"
# Verify the retention expiration date (it should now show a date)
gsutil ls -L "gs://$BUCKET/dummy_loan"
# Try to delete the file (it should now be successful)
gsutil rm "gs://$BUCKET/dummy_loan"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
