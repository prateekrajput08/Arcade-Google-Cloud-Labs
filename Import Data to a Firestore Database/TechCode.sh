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

# Set Project ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting project ID...${RESET_FORMAT}"
gcloud config set project $DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}Project ID set to: ${WHITE_TEXT}${BOLD_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo

# Create Firestore Database
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Firestore database in nam5 region...${RESET_FORMAT}"
gcloud firestore databases create --location=nam5 --quiet
echo "${GREEN_TEXT}Firestore database created successfully!${RESET_FORMAT}"
echo

# Clone Repository
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the pet-theory repository...${RESET_FORMAT}"
if [ -d "pet-theory" ]; then
    echo "${CYAN_TEXT}Repository already exists. Pulling latest changes...${RESET_FORMAT}"
    cd pet-theory && git pull
else
    git clone https://github.com/rosera/pet-theory.git
fi
echo "${GREEN_TEXT}Repository ready!${RESET_FORMAT}"
echo

# Navigate to Directory
echo "${YELLOW_TEXT}${BOLD_TEXT}Navigating to lab directory...${RESET_FORMAT}"
cd pet-theory/lab01 || { echo "${RED_TEXT}Failed to navigate to directory!${RESET_FORMAT}"; exit 1; }
echo "${GREEN_TEXT}Current directory: ${WHITE_TEXT}${BOLD_TEXT}$(pwd)${RESET_FORMAT}"
echo

# Install required packages
echo "${YELLOW_TEXT}${BOLD_TEXT}Installing required Node.js packages...${RESET_FORMAT}"
npm install @google-cloud/firestore
npm install @google-cloud/logging
npm install faker@5.5.3
npm install csv-parse
echo "${GREEN_TEXT}All packages installed successfully!${RESET_FORMAT}"
echo

# Download required scripts
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading required scripts...${RESET_FORMAT}"
echo "${CYAN_TEXT}Downloading importTestData.js...${RESET_FORMAT}"
curl -o createTestData.js \
https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/main/Import%20Data%20to%20a%20Firestore%20Database/createTestData.js
echo "${CYAN_TEXT}Downloading createTestData.js...${RESET_FORMAT}"
curl -o importTestData.js \
https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/main/Import%20Data%20to%20a%20Firestore%20Database/importTestData.js
echo "${GREEN_TEXT}Scripts downloaded successfully!${RESET_FORMAT}"
echo

# Create and import test data
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating and importing test data...${RESET_FORMAT}"
node createTestData 1000
node importTestData customers_1000.csv
node createTestData 20000
node importTestData customers_20000.csv
echo "${GREEN_TEXT}Test data generation and import completed!${RESET_FORMAT}"
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
