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


# User Input Section
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the location (e.g., us-central1): ${RESET_FORMAT}" LOCATION
export LOCATION
echo
echo "${CYAN_TEXT}Configuration Parameters:${RESET_FORMAT}"
echo "${WHITE_TEXT}Location: ${BOLD_TEXT}$LOCATION${RESET_FORMAT}"
echo

# Service Enablement
echo "${YELLOW_TEXT}Enabling required Google Cloud services...${RESET_FORMAT}"
gcloud services enable run.googleapis.com
gcloud services enable eventarc.googleapis.com
echo

# Pub/Sub Setup
echo "${YELLOW_TEXT}Creating Pub/Sub topic and subscription...${RESET_FORMAT}"
gcloud pubsub topics create "$DEVSHELL_PROJECT_ID-topic"
gcloud pubsub subscriptions create --topic "$DEVSHELL_PROJECT_ID-topic" "$DEVSHELL_PROJECT_ID-topic-sub"
echo

# Cloud Run Deployment
echo "${YELLOW_TEXT}Deploying Cloud Run service...${RESET_FORMAT}"
gcloud run deploy pubsub-events \
  --image=gcr.io/cloudrun/hello \
  --platform=managed \
  --region="$LOCATION" \
  --allow-unauthenticated
echo

# Eventarc Trigger Setup
echo "${YELLOW_TEXT}Creating Eventarc trigger for Pub/Sub messages...${RESET_FORMAT}"
gcloud eventarc triggers create pubsub-events-trigger \
  --location="$LOCATION" \
  --destination-run-service=pubsub-events \
  --destination-run-region="$LOCATION" \
  --transport-topic="$DEVSHELL_PROJECT_ID-topic" \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished"
echo "${GREEN_TEXT}Eventarc trigger created successfully!${RESET_FORMAT}"
echo

# Test Message
echo "${YELLOW_TEXT}Sending test message to Pub/Sub topic...${RESET_FORMAT}"
gcloud pubsub topics publish "$DEVSHELL_PROJECT_ID-topic" \
  --message="Subscribe to TechCode9"
echo



  # Final message
  echo
  echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
  echo
  echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
  echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
  echo
