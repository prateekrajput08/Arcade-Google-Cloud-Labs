
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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE: ${RESET_FORMAT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_2: ${RESET_FORMAT}" REGION_2

REGION="${ZONE%-*}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Starting lab execution...${RESET_FORMAT}"

gcloud compute networks create managementnet --subnet-mode=custom

gcloud compute networks subnets create managementsubnet-1 \
--network=managementnet \
--region=$REGION \
--range=10.130.0.0/20

gcloud compute networks create privatenet --subnet-mode=custom

gcloud compute networks subnets create privatesubnet-1 \
--network=privatenet \
--region=$REGION \
--range=172.16.0.0/24

gcloud compute networks subnets create privatesubnet-2 \
--network=privatenet \
--region=$REGION_2 \
--range=172.20.0.0/20

gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
--direction=INGRESS \
--priority=1000 \
--network=managementnet \
--action=ALLOW \
--rules=icmp,tcp:22,tcp:3389 \
--source-ranges=0.0.0.0/0

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
--direction=INGRESS \
--priority=1000 \
--network=privatenet \
--action=ALLOW \
--rules=icmp,tcp:22,tcp:3389 \
--source-ranges=0.0.0.0/0

gcloud compute instances create managementnet-vm-1 \
--zone=$ZONE \
--machine-type=e2-micro \
--subnet=managementsubnet-1

gcloud compute instances create privatenet-vm-1 \
--zone=$ZONE \
--machine-type=e2-micro \
--subnet=privatesubnet-1

gcloud compute instances create vm-appliance \
--zone=$ZONE \
--machine-type=e2-standard-4 \
--network-interface=subnet=privatesubnet-1 \
--network-interface=subnet=managementsubnet-1 \
--network-interface=subnet=mynetwork

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
