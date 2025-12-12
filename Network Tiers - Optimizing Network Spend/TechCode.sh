
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


# Ask user for zone
echo -e "${CYAN_TEXT}Enter the GCP zone (example: asia-south1-a, us-central1-b):${WHITE_TEXT}"
read -r ZONE

# Auto-derive region from zone
REGION="${ZONE%-*}"

echo -e "${GREEN_TEXT}Selected Zone: $ZONE"
echo -e "${GREEN_TEXT}Derived Region: $REGION${WHITE_TEXT}"

# Set gcloud config
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# Create VM with Premium Network Tier
echo -e "${YELLOW_TEXT}Creating VM with PREMIUM network tier...${WHITE_TEXT}"
gcloud compute instances create vm-premium \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM

# Create VM with Standard Network Tier
echo -e "${YELLOW_TEXT}Creating VM with STANDARD network tier...${WHITE_TEXT}"
gcloud compute instances create vm-standard \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --network-interface=network-tier=STANDARD

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
