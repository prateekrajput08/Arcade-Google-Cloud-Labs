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

# Ask user for the connection profile ID (unique identifier)
read -p "Enter the connection profile ID (unique identifier): " CONNECTION_PROFILE_ID

# Ask user for the display name of the connection profile
read -p "Enter the connection profile display name: " CONNECTION_PROFILE_NAME

# Ask user for the host or IP address
read -p "Enter the host or IP address: " HOST_OR_IP

# Ask user for the region
read -p "Enter the region: " REGION

# Fixed values for database engine, username, and password
DATABASE_ENGINE="MYSQL"
USERNAME="admin"
PASSWORD="changeme"
PORT=3306

# Check if connection profile already exists
EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)

if [ "$EXISTS" == "" ]; then
  # Create the connection profile
  gcloud database-migration connection-profiles create mysql "$CONNECTION_PROFILE_ID" \
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=$PORT \
    --username="$USERNAME" \
    --password="$PASSWORD"

  echo "Connection profile '$CONNECTION_PROFILE_NAME' (ID: $CONNECTION_PROFILE_ID) created successfully in region '$REGION' with database engine '$DATABASE_ENGINE'."
else
  echo "Connection profile with ID '$CONNECTION_PROFILE_ID' already exists in region '$REGION'. No new profile was created."
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
