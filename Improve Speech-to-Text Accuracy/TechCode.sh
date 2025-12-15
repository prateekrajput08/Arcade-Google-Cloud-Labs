
#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'
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

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Vertex AI Workbench Setup - Lab Automation${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
echo -e "${YELLOW_TEXT}Project ID:${RESET_FORMAT} $PROJECT_ID\n"

# ================================
# Ask for Region & Zone
# ================================
read -p "$(echo -e ${YELLOW_TEXT}Enter REGION \(example: us-central1\): ${RESET_FORMAT})" REGION
read -p "$(echo -e ${YELLOW_TEXT}Enter ZONE \(example: us-central1-a\): ${RESET_FORMAT})" ZONE

echo

# ================================
# Enable Required APIs
# ================================
echo -e "${YELLOW_TEXT}Enabling required APIs...${RESET_FORMAT}"

gcloud services enable \
  aiplatform.googleapis.com \
  notebooks.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com

echo -e "${YELLOW_TEXT}APIs enabled successfully!${RESET_FORMAT}\n"

# ================================
# Create Vertex AI Workbench Instance
# ================================
echo -e "${YELLOW_TEXT}Creating Vertex AI Workbench instance...${RESET_FORMAT}"

gcloud notebooks instances create lab-workbench \
  --location=$ZONE \
  --machine-type=e2-standard-4 \
  --boot-disk-size=100GB \
  --boot-disk-type=PD_STANDARD \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu

echo -e "\n${YELLOW_TEXT}Vertex AI Workbench instance created successfully!${RESET_FORMAT}"

# ================================
# Final Info
# ================================
echo -e "\n${YELLOW_TEXT}Instance Details:${RESET_FORMAT}"
echo "----------------------------------"
echo "Name   : lab-workbench"
echo "Region : $REGION"
echo "Zone   : $ZONE"
echo "----------------------------------"

echo -e "\n${GREEN_TECT}You can now access it from:${RESET_FORMAT}"
echo "Vertex AI → Workbench → Instances"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
