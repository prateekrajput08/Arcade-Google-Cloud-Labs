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
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# User prompts with bold formatting
echo -e "${BOLD_TEXT}${YELLOW_TEXT}Please enter the Amazon RDS for MySQL connection profile details:${RESET_FORMAT}"

read -p "$(echo -e "${BOLD_TEXT}${YELLOW_TEXT}Enter the connection profile ID (unique identifier): ${RESET_FORMAT}")" CONNECTION_PROFILE_ID
read -p "$(echo -e "${BOLD_TEXT}${YELLOW_TEXT}Enter the connection profile display name: ${RESET_FORMAT}")" CONNECTION_PROFILE_NAME
read -p "$(echo -e "${BOLD_TEXT}${YELLOW_TEXT}Enter the Amazon RDS endpoint (host or IP address): ${RESET_FORMAT}")" HOST_OR_IP
read -p "$(echo -e "${BOLD_TEXT}${YELLOW_TEXT}Enter the region (e.g., us-central1): ${RESET_FORMAT}")" REGION

# Variables
DATABASE_ENGINE="Amazon RDS for MySQL"
USERNAME="admin"
PASSWORD="changeme"
PORT=3306

# Check if profile exists with color output
EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)

if [ "$EXISTS" == "" ]; then
  # Create the connection profile with Amazon RDS settings
  gcloud database-migration connection-profiles create mysql "$CONNECTION_PROFILE_ID" \
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=$PORT \
    --username="$USERNAME" \
    --password="$PASSWORD" \
    --type=RDS \
    --labels=engine="amazon-rds-mysql"

  echo -e "${GREEN_TEXT}${BOLD_TEXT}Amazon RDS connection profile '${CONNECTION_PROFILE_NAME}' (ID: ${CONNECTION_PROFILE_ID}) created successfully in region '${REGION}' with database engine '${DATABASE_ENGINE}'.${NO_COLOR}"
else
  # Profile already exists warning
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}Connection profile with ID '${CONNECTION_PROFILE_ID}' already exists in region '${REGION}'. No new Amazon RDS profile was created.${NO_COLOR}"
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
