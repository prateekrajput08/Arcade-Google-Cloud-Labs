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


echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Project ID...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}PROJECT_ID: $PROJECT_ID${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Default Zone...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${GREEN_TEXT}ZONE: $ZONE${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Region...${RESET_FORMAT}"
REGION=$(echo "$ZONE" | awk -F'-' '{print $1"-"$2}')
echo "${GREEN_TEXT}REGION: $REGION${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Setting configuration...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID >/dev/null
gcloud config set compute/region $REGION >/dev/null
gcloud config set compute/zone $ZONE >/dev/null

echo "${BLUE_TEXT}${BOLD_TEXT}Enabling required APIs...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com iap.googleapis.com

echo "${TEAL_TEXT}${BOLD_TEXT}Creating VPC and Subnets...${RESET_FORMAT}"
gcloud compute networks create test-vpc --subnet-mode=custom

gcloud compute networks subnets create client-subnet \
  --network=test-vpc --range=10.10.10.0/24 --region=$REGION

gcloud compute networks subnets create server-subnet \
  --network=test-vpc --range=10.20.20.0/24 --region=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Firewall Rule for IAP SSH...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-iap-ssh \
  --network=test-vpc --allow=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=iap-gce

echo "${GOLD_TEXT}${BOLD_TEXT}Creating web-server instance...${RESET_FORMAT}"
gcloud compute instances create web-server \
  --zone=$ZONE \
  --subnet=server-subnet \
  --tags=iap-gce \
  --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install -y nginx
echo "Hello from web-server!" > /var/www/html/index.html
systemctl restart nginx'

echo "${PURPLE_TEXT}${BOLD_TEXT}Creating client-instance...${RESET_FORMAT}"
gcloud compute instances create client-instance \
  --zone=$ZONE \
  --subnet=client-subnet \
  --tags=iap-gce

echo "${NAVY_TEXT}${BOLD_TEXT}Creating NGFW Policy...${RESET_FORMAT}"
gcloud compute network-firewall-policies create test-firewall-policy --global

echo "${MAROON_TEXT}${BOLD_TEXT}Adding DENY Rule (Misconfigured)...${RESET_FORMAT}"
gcloud compute network-firewall-policies rules create 100 \
  --global \
  --firewall-policy=test-firewall-policy \
  --action=deny \
  --direction=INGRESS \
  --src-ip-ranges=10.10.10.0/24 \
  --dest-ip-ranges=10.20.20.0/24 \
  --layer4-configs=tcp:80

echo "${BLUE_TEXT}${BOLD_TEXT}Associating Firewall Policy with VPC...${RESET_FORMAT}"
gcloud compute network-firewall-policies associations create test-firewall-association \
  --firewall-policy=test-firewall-policy \
  --network=test-vpc \
  --global

echo
echo "${RED_TEXT}${BOLD_TEXT}Traffic is currently BLOCKED by NGFW rule.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Run this inside client-instance to test denial:${RESET_FORMAT}"
echo "${GREEN_TEXT}curl -m 5 http://<web-server-internal-ip>${RESET_FORMAT}"
echo

read -p "${CYAN_TEXT}${BOLD_TEXT}Press ENTER to update the rule to ALLOW...${RESET_FORMAT}"

echo "${LIME_TEXT}${BOLD_TEXT}Updating Rule to ALLOW...${RESET_FORMAT}"
gcloud compute network-firewall-policies rules update 100 \
  --global \
  --firewall-policy=test-firewall-policy \
  --action=allow \
  --layer4-configs=tcp:80

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Rule Updated Successfully!${RESET_FORMAT}"
echo "${YELLOW_TEXT}Traffic should now be allowed. Test again with curl from client-instance.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
