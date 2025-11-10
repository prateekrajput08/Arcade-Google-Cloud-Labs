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

echo "${CYAN_TEXT}--- Create Amazon RDS MySQL Connection Profile ---${RESET_TEXT}"

# Step 1: Ask for Amazon RDS IP address
read -p "${YELLOW_TEXT}Enter the Amazon RDS MySQL public IP address: ${RESET_TEXT}" RDS_IP

# Step 2: Ask for Google Cloud zone
read -p "${YELLOW_TEXT}Enter your Google Cloud zone (e.g., us-central1-a): ${RESET_TEXT}" ZONE

# Step 3: Derive region from zone
REGION=$(echo "$ZONE" | sed 's/-[a-z]$//')
echo "${GREEN_TEXT}Detected Region from Zone: ${REGION}${RESET_TEXT}"

# Step 4: Confirm details
echo ""
echo "${YELLOW_TEXT}Please confirm the details:${RESET_TEXT}"
echo "  Amazon RDS IP:   $RDS_IP"
echo "  Zone:            $ZONE"
echo "  Region:          $REGION"
read -p "${YELLOW_TEXT}Continue with these settings? (y/n): ${RESET_TEXT}" CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "${RED_TEXT}Operation cancelled.${RESET_TEXT}"
  exit 1
fi

# Step 5: Create the connection profile
echo ""
echo "${YELLOW_TEXT}Creating connection profile 'mysql-rds'...${RESET_TEXT}"

gcloud database-migration connection-profiles create mysql-rds \
  --region=$REGION \
  --display-name="mysql-rds" \
  --provider=aws \
  --engine=mysql \
  --username=admin \
  --password=changeme \
  --hostname=$RDS_IP \
  --port=3306 \
  --no-ssl \
  --static-ip \
  --quiet

# Step 6: Verify creation
if [ $? -eq 0 ]; then
  echo ""
  echo "${GREEN_TEXT}Connection profile 'mysql-rds' created successfully in region: $REGION${RESET_TEXT}"
else
  echo ""
  echo "${RED_TEXT}Failed to create connection profile. Please check your Cloud IAM permissions or network settings.${RESET_TEXT}"
  exit 1
fi

# Step 7: List connection profiles for confirmation
echo ""
echo "${YELLOW_TEXT}Listing all connection profiles in region $REGION:${RESET_TEXT}"
gcloud database-migration connection-profiles list --region=$REGION



# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
