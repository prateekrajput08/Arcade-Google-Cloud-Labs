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

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
echo "${GREEN_TEXT}${BOLD_TEXT}Active Project: ${PROJECT_ID}${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION (example: us-central1): ${RESET_FORMAT}" REGION
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE (example: us-central1-a): ${RESET_FORMAT}" ZONE

gcloud config set compute/region $REGION >/dev/null
gcloud config set compute/zone $ZONE >/dev/null

echo "${GREEN_TEXT}${BOLD_TEXT}Region set to: $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone set to: $ZONE${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com iap.googleapis.com

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating VPC and subnets...${RESET_FORMAT}"

gcloud compute networks create test-vpc --subnet-mode=custom

gcloud compute networks subnets create client-subnet \
  --network=test-vpc --region=$REGION --range=10.10.10.0/24

gcloud compute networks subnets create server-subnet \
  --network=test-vpc --region=$REGION --range=10.20.20.0/24

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating IAP firewall rule...${RESET_FORMAT}"

gcloud compute firewall-rules create allow-iap-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=test-vpc \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=iap-gce

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating web-server instance...${RESET_FORMAT}"

gcloud compute instances create web-server \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --subnet=server-subnet \
  --tags=http-server,https-server,iap-gce \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install -y nginx
      echo "<div>Hello from web-server!</div>" > /var/www/html/index.nginx-debian.html
      systemctl start nginx'

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating client-instance...${RESET_FORMAT}"

gcloud compute instances create client-instance \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --subnet=client-subnet \
  --tags=iap-gce \
  --scopes=https://www.googleapis.com/auth/cloud-platform

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating NGFW Policy...${RESET_FORMAT}"

gcloud compute network-firewall-policies create test-firewall-policy \
  --global \
  --description="Test Firewall Policy"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Adding DENY rule (misconfigured)...${RESET_FORMAT}"

gcloud compute network-firewall-policies rules create 100 \
  --firewall-policy=test-firewall-policy \
  --action=deny \
  --direction=INGRESS \
  --src-ip-ranges=10.10.10.0/24 \
  --dest-ip-ranges=10.20.20.0/24 \
  --layer4-configs=tcp:80 \
  --description="Deny client -> server on port 80" \
  --global-firewall-policy

echo "${MAGENTA_TEXT}${BOLD_TEXT}Associating firewall policy to VPC...${RESET_FORMAT}"

gcloud compute network-firewall-policies associations create \
  test-association \
  --firewall-policy=test-firewall-policy \
  --network=test-vpc \
  --global-firewall-policy

echo "${BLUE}${BOLD_TEXT}Testing denial from client-instance...${RESET_FORMAT}"

WEBSERVER_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
echo "${GREEN_TEXT}${BOLD_TEXT}Internal Web Server IP: ${WEBSERVER_IP}${RESET_FORMAT}"

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}Running curl test (expected timeout)...${RESET_FORMAT}"
echo ""

gcloud compute ssh client-instance --tunnel-through-iap --zone=$ZONE --command="curl -m 5 $WEBSERVER_IP"

echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}Updating rule 100 to ALLOW...${RESET_FORMAT}"

gcloud compute network-firewall-policies rules update 100 \
  --firewall-policy=test-firewall-policy \
  --action=allow \
  --global-firewall-policy

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Rule updated successfully! Traffic should now pass.${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Testing allowed traffic from client-instance...${RESET_FORMAT}"

gcloud compute ssh client-instance --tunnel-through-iap --zone=$ZONE \
  --command="curl -m 5 $WEBSERVER_IP"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
