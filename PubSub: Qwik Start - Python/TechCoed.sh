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
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Authenticate gcloud
echo "${YELLOW_TEXT}${BOLD_TEXT}Authenticating with Google Cloud...${RESET_FORMAT}"
gcloud auth list 

echo "${CYAN_TEXT}${BOLD_TEXT}Installing virtualenv...${RESET_FORMAT}"
sudo apt-get install -y virtualenv

# Set up Python virtual environment
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Python virtual environment...${RESET_FORMAT}"
python3 -m venv venv

# Activate virtual environment
echo "${GREEN_TEXT}${BOLD_TEXT}Activating virtual environment...${RESET_FORMAT}"
source venv/bin/activate

# Install dependencies
echo "${BLUE_TEXT}${BOLD_TEXT}Installing required Python packages...${RESET_FORMAT}"
pip install --upgrade google-cloud-pubsub

# Clone repository
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning Google Cloud Pub/Sub repository...${RESET_FORMAT}"
git clone https://github.com/googleapis/python-pubsub.git

# Navigate to scripts directory
echo "${MAGENTA_TEXT}${BOLD_TEXT}Navigating to the samples directory...${RESET_FORMAT}"
cd python-pubsub/samples/snippets

# Display usage help
echo "${CYAN_TEXT}${BOLD_TEXT}Displaying help for publisher script...${RESET_FORMAT}"
python publisher.py -h

# Create a topic
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a Pub/Sub topic...${RESET_FORMAT}"
python publisher.py $GOOGLE_CLOUD_PROJECT create MyTopic

# Create a subscription
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a subscription for the topic...${RESET_FORMAT}"
python subscriber.py $GOOGLE_CLOUD_PROJECT create MyTopic MySub


echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
