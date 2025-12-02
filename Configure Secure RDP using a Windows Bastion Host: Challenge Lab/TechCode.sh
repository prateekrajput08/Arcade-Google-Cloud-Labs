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

# Function to validate zone format
validate_zone() {
  local zone=$1
  if [[ "$zone" =~ ^[a-z]+-[a-z]+[0-9]-[a-z]$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt user for zone input
echo "${GREEN_TEXT}${BOLD_TEXT}Step 1: Set the zone for your resources${RESET_FORMAT}"
echo "${YELLOW_TEXT}Please enter your preferred zone (e.g., us-central1-a):${RESET_FORMAT}"
read -p "Zone: " ZONE

# Validate zone input
while ! validate_zone "$ZONE"; do
  echo "${RED_TEXT}${BOLD_TEXT}Invalid zone format. Please enter a valid zone (e.g., us-central1-a)${RESET_FORMAT}"
  read -p "Zone: " ZONE
done

export ZONE
REGION="${ZONE%-*}"
export REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Using Zone: ${WHITE}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Derived Region: ${WHITE}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

# Create network and subnets
echo "${BLUE_TEXT}${BOLD_TEXT}Creating secure network and subnet...${RESET_FORMAT}"
gcloud compute networks create securenetwork --subnet-mode custom
gcloud compute networks subnets create securenetwork-subnet \
  --network=securenetwork \
  --region $REGION \
  --range=192.168.16.0/20

# Create firewall rule
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating firewall rule for RDP access...${RESET_FORMAT}"
gcloud compute firewall-rules create rdp-ingress-fw-rule \
  --allow=tcp:3389 \
  --source-ranges 0.0.0.0/0 \
  --target-tags allow-rdp-traffic \
  --network securenetwork

# Create VM instances
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating bastion host VM...${RESET_FORMAT}"
gcloud compute instances create vm-bastionhost \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=subnet=securenetwork-subnet \
  --network-interface=subnet=default,no-address \
  --tags=allow-rdp-traffic \
  --image=projects/windows-cloud/global/images/windows-server-2016-dc-v20220513

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating secure host VM...${RESET_FORMAT}"
gcloud compute instances create vm-securehost \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=subnet=securenetwork-subnet,no-address \
  --network-interface=subnet=default,no-address \
  --tags=allow-rdp-traffic \
  --image=projects/windows-cloud/global/images/windows-server-2016-dc-v20220513

# Wait for VMs to initialize
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting 5 minutes for VMs to initialize...${RESET_FORMAT}"
for i in {300..1}; do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Time remaining: ${i}s \r${RESET_FORMAT}"
  sleep 1
done
echo

# Reset Windows passwords
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Resetting ${RED}${BOLD_TEXT}password ${WHITE_TEXT}${BOLD_TEXT}for ${GREEN_TEXT}${BOLD_TEXT}vm-bastionhost${RESET_FORMAT}"
gcloud compute reset-windows-password vm-bastionhost \
  --user app_admin \
  --zone $ZONE \
  --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Resetting ${RED_TEXT}${BOLD_TEXT}password ${WHITE_TEXT}${BOLD_TEXT}for ${BLUE_TEXT}${BOLD_TEXT}vm-securehost${RESET_FORMAT}"
gcloud compute reset-windows-password vm-securehost \
  --user app_admin \
  --zone $ZONE \
  --quiet


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
