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
RESET_FORMAT_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT_FORMAT}"
echo

echo "${GOLD_TEXT}${BOLD_TEXT}Enter PROJECT_ID:${RESET_FORMAT}"
read PROJECT_ID

echo "${GOLD_TEXT}${BOLD_TEXT}Enter REGION (e.g., us-central1):${RESET_FORMAT}"
read REGION

echo "${GOLD_TEXT}${BOLD_TEXT}Enter ZONE (e.g., us-central1-a):${RESET_FORMAT}"
read ZONE

echo "${GREEN_TEXT}${BOLD_TEXT}Configuring gcloud settings...${RESET_FORMAT}"
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo "${GREEN_TEXT}${BOLD_TEXT}Creating VPC and Subnets...${RESET_FORMAT}"
gcloud compute networks create test-vpc --subnet-mode=custom
gcloud compute networks subnets create test-subnet --network=test-vpc --region="$REGION" --range=10.10.10.0/24
gcloud compute networks subnets create another-subnet --network=test-vpc --region="$REGION" --range=10.20.20.0/24

echo "${GREEN_TEXT}${BOLD_TEXT}Creating Firewall Rule for IAP...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-iap-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=test-vpc \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=iap-gce

echo "${GREEN_TEXT}${BOLD_TEXT}Creating VM instance...${RESET_FORMAT}"
gcloud compute instances create test-instance \
  --machine-type=e2-micro \
  --subnet=test-subnet \
  --no-address \
  --tags=iap-gce \
  --zone="$ZONE"

echo "${YELLOW_TEXT}${BOLD_TEXT}Testing connectivity (expected FAIL)...${RESET_FORMAT}"
gcloud compute ssh test-instance --zone="$ZONE" --command="ping -c 3 8.8.8.8 || true"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating NAT (misconfigured)...${RESET_FORMAT}"
gcloud compute addresses create nat-ip --region="$REGION"
gcloud compute routers create test-nat-router --network=test-vpc --region="$REGION"

gcloud compute routers nats create test-nat \
  --router=test-nat-router \
  --region="$REGION" \
  --nat-external-ip-pool=nat-ip \
  --nat-custom-subnet-ip-ranges=another-subnet

echo "${YELLOW_TEXT}${BOLD_TEXT}Testing again (still FAIL)...${RESET_FORMAT}"
gcloud compute ssh test-instance --zone="$ZONE" --command="ping -c 3 8.8.8.8 || true"

echo "${TEAL_TEXT}${BOLD_TEXT}Fixing NAT configuration...${RESET_FORMAT}"
gcloud compute routers nats update test-nat \
  --router=test-nat-router \
  --region="$REGION" \
  --nat-custom-subnet-ip-ranges=test-subnet

echo "${GREEN_TEXT}${BOLD_TEXT}Testing after fix (SUCCESS expected)...${RESET_FORMAT}"
gcloud compute ssh test-instance --zone="$ZONE" --command="ping -c 3 8.8.8.8"

echo "${GREEN_TEXT}${BOLD_TEXT}Installing DNS tools & testing DNS resolution...${RESET_FORMAT}"
gcloud compute ssh test-instance --zone="$ZONE" --command="sudo apt-get update && sudo apt-get install -y dnsutils && nslookup google.com"

echo "${PURPLE_TEXT}${BOLD_TEXT}✔ LAB COMPLETED SUCCESSFULLY${RESET_FORMAT}"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
