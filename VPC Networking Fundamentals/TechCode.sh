#!/bin/bash

# Bright Foreground Colors
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
PINK_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
GREEN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Displaying start message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Prompt user for Zone 2 input
echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter a second GCP zone:${RESET_FORMAT}"
read -r ZONE_2
echo "${PINK_TEXT}You entered: ${BOLD_TEXT}$ZONE_2${RESET_FORMAT}"

export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Creating network
echo "${BLUE_TEXT}${BOLD_TEXT}Creating VPC network: mynetwork...${RESET_FORMAT}"
gcloud compute networks create mynetwork \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=auto \
  --mtu=1460 \
  --bgp-routing-mode=regional

echo "${PINK_TEXT}Network creation completed.${RESET_FORMAT}"

# Creating first VM
echo "${BLUE_TEXT}${BOLD_TEXT}Creating first VM in zone: $ZONE_1...${RESET_FORMAT}"
gcloud compute instances create mynet-us-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_1 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-us-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_1/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${PINK_TEXT}First VM created successfully.${RESET_FORMAT}"

# Creating second VM
echo "${BLUE_TEXT}${BOLD_TEXT}Creating second VM in zone: $ZONE_2...${RESET_FORMAT}"
gcloud compute instances create mynet-second-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_2 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-eu-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_2/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${PINK_TEXT}Second VM created successfully.${RESET_FORMAT}"

echo
echo "${PINK_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
