#!/bin/bash

# Bright Foreground Colors
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Authenticating with gcloud ========================== ${RESET_FORMAT}"
echo
gcloud auth list

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Retrieving Default Zone ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Retrieving the default compute zone for your project... ${RESET_FORMAT}"
echo
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating 'gcelab' Instance ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Now we're creating the 'gcelab' virtual machine. ${RESET_FORMAT}"
echo
gcloud compute instances create gcelab --zone=$ZONE --machine-type=e2-medium --boot-disk-size=10GB --image-family=debian-11 --image-project=debian-cloud --create-disk=size=10GB,type=pd-balanced --tags=http-server

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating 'gcelab2' Instance ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating another VM named 'gcelab2' with default settings. ${RESET_FORMAT}"
echo
gcloud compute instances create gcelab2 --machine-type e2-medium --zone=$ZONE

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Firewall Rule ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} We're now creating a firewall rule to allow HTTP traffic. ${RESET_FORMAT}"
echo
gcloud compute firewall-rules create allow-http --action=ALLOW --direction=INGRESS --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Installing Nginx on 'gcelab' ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Connecting to 'gcelab' via SSH to install Nginx and check its status. ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} This may take a few moments... ${RESET_FORMAT}"
echo
gcloud compute ssh gcelab --zone=$ZONE --quiet --command "sudo apt-get update && sudo apt-get install -y nginx && ps auwx | grep nginx "

echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
