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

# Enable required APIs with color output
echo -e "${YELLOW_TEXT}Enabling Database Migration API...${RESET_FORMAT}"
gcloud services enable datamigration.googleapis.com --quiet
echo -e "${YELLOW_TEXT}Enabling Service Networking API...${RESET_FORMAT}"
gcloud services enable servicenetworking.googleapis.com --quiet

# User prompts with bold formatting
echo -e "${BOLD_TEXT}${YELLOW_TEXT}Please enter the connection profile details:${RESET_FORMAT}"

read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the connection profile ID (unique identifier): ${RESET_FORMAT}")" CONNECTION_PROFILE_ID
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the connection profile display name: ${RESET_FORMAT}")" CONNECTION_PROFILE_NAME
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the host or IP address: ${RESET_FORMAT}")" HOST_OR_IP
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the region: ${RESET_FORMAT}")" REGION

# Variables
DATABASE_ENGINE="POSTGRESQL"     # UPDATED FOR POSTGRES
USERNAME="migration_user"              # UPDATED FOR POSTGRES
PASSWORD="DMS_1s_cool!"
PORT=5432                        # UPDATED FOR POSTGRES

# Check if profile exists with color output
EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)

if [ "$EXISTS" == "" ]; then
  # Create the connection profile for PostgreSQL
  gcloud database-migration connection-profiles create postgresql "$CONNECTION_PROFILE_ID" \   # UPDATED FOR POSTGRES
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=$PORT \
    --username="$USERNAME" \
    --password="$PASSWORD"

  echo -e "${GREEN_TEXT}${BOLD_TEXT}Connection profile '${CONNECTION_PROFILE_NAME}' (ID: ${CONNECTION_PROFILE_ID}) created successfully in region '${REGION}' with PostgreSQL engine.${NO_COLOR}"
else
  # Profile already exists warning
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}Connection profile with ID '${CONNECTION_PROFILE_ID}' already exists in region '${REGION}'. No new profile was created.${NO_COLOR}"
fi

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
