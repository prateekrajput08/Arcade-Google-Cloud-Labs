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
BOLD=`tput bold`
RESET=`tput sgr0`
clear


# Welcome message
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


set -euo pipefail

# Configuration
TOPIC_NAME="cron-topic"
SUBSCRIPTION_NAME="cron-sub"
JOB_NAME="cron-job"
MESSAGE_BODY="hello cron!"
SCHEDULE="* * * * *"
TIMEZONE="Etc/UTC"
LOCATION=""  # Will be asked from user

# Functions

function log() {
    echo -e "\n>>> $1"
}

function enable_api() {
    local api=$1
    if gcloud services list --enabled --format="value(config.name)" | grep -q "^$api$"; then
        log "API '$api' is already enabled."
    else
        log "Enabling API '$api'..."
        gcloud services enable "$api"
    fi
}

function create_topic_if_not_exists() {
    if gcloud pubsub topics describe "$TOPIC_NAME" &>/dev/null; then
        log "Pub/Sub topic '$TOPIC_NAME' already exists."
    else
        log "Creating Pub/Sub topic '$TOPIC_NAME'..."
        gcloud pubsub topics create "$TOPIC_NAME"
    fi
}

function create_subscription_if_not_exists() {
    if gcloud pubsub subscriptions describe "$SUBSCRIPTION_NAME" &>/dev/null; then
        log "Subscription '$SUBSCRIPTION_NAME' already exists."
    else
        log "Creating Pub/Sub subscription '$SUBSCRIPTION_NAME'..."
        gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" --topic="$TOPIC_NAME"
    fi
}

function prompt_for_location() {
    echo -e "\n Cloud Scheduler requires a location (e.g., us-central1, us-east1, europe-west1)"
    read -rp "Enter your desired Cloud Scheduler location: " LOCATION
    if [[ -z "$LOCATION" ]]; then
        echo "Location is required. Exiting."
        exit 1
    fi
}

function create_scheduler_job_if_not_exists() {
    if gcloud scheduler jobs describe "$JOB_NAME" --location="$LOCATION" &>/dev/null; then
        log "Scheduler job '$JOB_NAME' already exists in location '$LOCATION'."
    else
        log "Creating Cloud Scheduler job '$JOB_NAME' in location '$LOCATION'..."
        gcloud scheduler jobs create pubsub "$JOB_NAME" \
            --schedule="$SCHEDULE" \
            --time-zone="$TIMEZONE" \
            --topic="$TOPIC_NAME" \
            --message-body="$MESSAGE_BODY" \
            --description="Send message to Pub/Sub every minute" \
            --location="$LOCATION"
    fi
}

function pull_pubsub_messages() {
    log "Waiting 70 seconds for Scheduler job to trigger at least once..."
    sleep 70

    log "Pulling messages from Pub/Sub subscription '$SUBSCRIPTION_NAME'..."
    gcloud pubsub subscriptions pull "$SUBSCRIPTION_NAME" --limit=5 --auto-ack || log "No messages yet. Try again later."
}

# Main Script

log "Step 1: Enable required APIs"
enable_api "cloudscheduler.googleapis.com"
enable_api "pubsub.googleapis.com"

log "Step 2: Set up Cloud Pub/Sub"
create_topic_if_not_exists
create_subscription_if_not_exists

# log "Step 3: Prompt for Scheduler location"
# prompt_for_location

# log "Step 4: Create Cloud Scheduler Job"
# create_scheduler_job_if_not_exists

# log "Step 5: Verify messages from Pub/Sub"
# pull_pubsub_messages

# log "Step 6: Test your knowledge"
# echo -e "\nQ: You can trigger an App Engine app, send a message via Cloud Pub/Sub, or hit an arbitrary HTTP endpoint running on Compute Engine, Google Kubernetes Engine, or on-premises with your Cloud Scheduler job."
# echo "A: True"

# log "All steps completed successfully and safely re-runnable!"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
