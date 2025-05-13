#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
PINK_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${PINK_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${PINK_TEXT}${BOLD_TEXT}🔍 Attempting to automatically determine your default GCP zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default zone not found.${RESET_FORMAT}"
    read -p "${GREEN_TEXT}${BOLD_TEXT}Please enter the zone: ${RESET_FORMAT}" ZONE
fi

echo "${PINK_TEXT}${BOLD_TEXT}🌍 Attempting to automatically determine your default GCP region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
    if [ -n "$ZONE" ]; then
        REGION=$(echo "$ZONE" | sed 's/-[a-z]$//')
        echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default region not found. Deriving region from zone: ${GREEN_TEXT}$REGION${RESET_FORMAT}"
    else
        echo "${RED_TEXT}${BOLD_TEXT}❌ Critical: Cannot determine region as zone is also not set. Please configure default zone/region or provide them.${RESET_FORMAT}"
    fi
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📍 Using Zone: ${WHITE_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🌎 Using Region: ${WHITE_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${PINK_TEXT}${BOLD_TEXT}🛠️  Creating a custom-mode VPC network named 'labnet'...${RESET_FORMAT}"
gcloud compute networks create labnet --subnet-mode=custom

echo "${PINK_TEXT}${BOLD_TEXT}🔗 Creating a subnet 'labnet-sub' within the 'labnet' network in region ${WHITE_TEXT}$REGION${PINK_TEXT}${BOLD_TEXT} with IP range 10.0.0.0/28...${RESET_FORMAT}"
gcloud compute networks subnets create labnet-sub \
   --network labnet \
   --region "$REGION" \
   --range 10.0.0.0/28

echo "${PINK_TEXT}${BOLD_TEXT}📋 Listing all VPC networks in the project...${RESET_FORMAT}"
gcloud compute networks list

echo "${PINK_TEXT}${BOLD_TEXT}🛡️  Setting up firewall rule 'labnet-allow-internal' for 'labnet' to permit ICMP and TCP port 22 (SSH) from all sources (0.0.0.0/0)...${RESET_FORMAT}"
gcloud compute firewall-rules create labnet-allow-internal \
    --network=labnet \
    --action=ALLOW \
    --rules=icmp,tcp:22 \
    --source-ranges=0.0.0.0/0

echo "${PINK_TEXT}${BOLD_TEXT}🛠️  Creating another custom-mode VPC network named 'privatenet'...${RESET_FORMAT}"
gcloud compute networks create privatenet --subnet-mode=custom

echo "${PINK_TEXT}${BOLD_TEXT}🔗 Creating a subnet 'private-sub' within the 'privatenet' network in region ${WHITE_TEXT}$REGION${PINK_TEXT}${BOLD_TEXT} with IP range 10.1.0.0/28...${RESET_FORMAT}"
gcloud compute networks subnets create private-sub \
    --network=privatenet \
    --region="$REGION" \
    --range 10.1.0.0/28

echo "${PINK_TEXT}${BOLD_TEXT}🛡️  Setting up firewall rule 'privatenet-deny' for 'privatenet' to block ICMP and TCP port 22 (SSH) from all sources (0.0.0.0/0)...${RESET_FORMAT}"
gcloud compute firewall-rules create privatenet-deny \
    --network=privatenet \
    --action=DENY \
    --rules=icmp,tcp:22 \
    --source-ranges=0.0.0.0/0

echo "${PINK_TEXT}${BOLD_TEXT}📜 Listing all firewall rules, sorted by network, to review our configurations...${RESET_FORMAT}"
gcloud compute firewall-rules list --sort-by=NETWORK

echo "${PINK_TEXT}${BOLD_TEXT}💻 Launching a new VM instance named 'pnet-vm' in zone ${WHITE_TEXT}$ZONE${PINK_TEXT}${BOLD_TEXT}, connected to the 'private-sub' subnet...${RESET_FORMAT}"
gcloud compute instances create pnet-vm \
--zone="$ZONE" \
--machine-type=n1-standard-1 \
--subnet=private-sub

echo "${PINK_TEXT}${BOLD_TEXT}💻 Launching another new VM instance named 'lnet-vm' in zone ${WHITE_TEXT}$ZONE${PINK_TEXT}${BOLD_TEXT}, connected to the 'labnet-sub' subnet...${RESET_FORMAT}"
gcloud compute instances create lnet-vm \
--zone="$ZONE" \
--machine-type=n1-standard-1 \
--subnet=labnet-sub

echo
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
