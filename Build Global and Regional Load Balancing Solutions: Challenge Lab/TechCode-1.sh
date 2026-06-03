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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_A: ${RESET_FORMAT}" REGION_A
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_B: ${RESET_FORMAT}" REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc

source ~/.bashrc

echo "${YELLOW_TEXT}${BOLD_TEXT}
Open:
https://console.cloud.google.com/compute/instanceGroups/add

Create Regional MIG

Name: mig-proxy-internal
Template: template-proxy-internal
Region: Region B
Add Named Port: tcp80 -> 80
${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Press Enter to continue...${RESET_FORMAT}"

gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80

gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80

gcloud compute health-checks create tcp hc-internal-proxy \
    --region=$REGION_B \
    --port=80

echo "${YELLOW_TEXT}${BOLD_TEXT}Open:
https://console.cloud.google.com/networking/addresses/list

Create:

Name: ip-internal-proxy
Region: Region B
Network: lb-network
Subnet: lb-backend-subnet-region-b
Purpose: Shared Load Balancer VIP${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Press Enter to continue...${RESET_FORMAT}"

gcloud compute backend-services create internal-proxy-backend \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION_B \
    --health-checks=hc-internal-proxy \
    --health-checks-region=$REGION_B

gcloud compute backend-services add-backend internal-proxy-backend \
    --instance-group=mig-proxy-internal \
    --instance-group-zone=${REGION_B}-b \
    --region=$REGION_B

echo "${YELLOW_TEXT}${BOLD_TEXT}Open:
https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers

echo Frontend:
Name: rule-internal-proxy
IP Address: ip-internal-proxy
Protocol: TCP
Port: 110
Global Access: Disabled${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Press Enter to continue...${RESET_FORMAT}"

gcloud compute instances create vm-client-internal \
   --zone=${REGION_B}-b \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=lb-backend-subnet-region-b \
   --tags=allow-ssh

# Get Internal LB IP
LB_IP=$(gcloud compute addresses describe ip-internal-proxy \
    --region=$REGION_B \
    --format="value(address)")

echo $LB_IP
   
# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
