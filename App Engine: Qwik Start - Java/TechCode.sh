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

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        SUBSCRIBE TECH & CODE- INITIATING EXECUTION...            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Ask region
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter your region (example: us-central): ${RESET_FORMAT}"
read REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Checking active account...${RESET_FORMAT}"
gcloud auth list

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling App Engine API...${RESET_FORMAT}"
gcloud services enable appengine.googleapis.com

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Downloading lab source files...${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp068/appengine-java21/appengine-java21/* .

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Navigating to project directory...${RESET_FORMAT}"
cd helloworld/http-server

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating App Engine application...${RESET_FORMAT}"
gcloud app create --region=$REGION --quiet

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying application to App Engine...${RESET_FORMAT}"
gcloud app deploy --quiet

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Opening deployed application...${RESET_FORMAT}"
gcloud app browse

# Final message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Subscribe for more Google Cloud Labs 🚀${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
