#!/bin/bash

# ================== COLORS ==================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ================== INPUT ==================
read -p "Enter Zone (example: us-east4-c): " ZONE

if [[ -z "$ZONE" ]]; then
  echo "${RED_TEXT}Zone cannot be empty!${RESET_FORMAT}"
  exit 1
fi

# ================== AUTO FETCH ==================
echo "${YELLOW_TEXT}Fetching project details...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
REGION=$(echo "$ZONE" | sed 's/-[a-z]$//')

export ZONE REGION

echo "${GREEN_TEXT}Project: $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Region: $REGION${RESET_FORMAT}"

# ================== CONFIG ==================
echo "${BLUE_TEXT}Setting compute config...${RESET_FORMAT}"
gcloud config set compute/zone "$ZONE" >/dev/null
gcloud config set compute/region "$REGION" >/dev/null

# ================== CREATE VM ==================
echo "${MAGENTA_TEXT}Creating VM...${RESET_FORMAT}"
gcloud compute instances create gcelab \
  --zone "$ZONE" \
  --machine-type e2-standard-2

# ================== CREATE DISK ==================
echo "${CYAN_TEXT}Creating disk...${RESET_FORMAT}"
gcloud compute disks create mydisk \
  --size=200GB \
  --zone "$ZONE"

# ================== ATTACH DISK ==================
echo "${YELLOW_TEXT}Attaching disk...${RESET_FORMAT}"
gcloud compute instances attach-disk gcelab \
  --disk mydisk \
  --zone "$ZONE"

# WAIT to ensure disk is visible
echo "${BLUE_TEXT}Waiting for disk to be ready...${RESET_FORMAT}"
sleep 10

# ================== REMOTE SETUP ==================
echo "${BLUE_TEXT}Formatting & mounting disk...${RESET_FORMAT}"

gcloud compute ssh gcelab --zone "$ZONE" --command="
echo 'Detecting disk...'
DISK=\$(ls /dev/disk/by-id/ | grep persistent-disk-1)

echo 'Using disk: '\$DISK

sudo mkdir -p /mnt/mydisk

echo 'Formatting disk...'
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/\$DISK

echo 'Mounting disk...'
sudo mount -o discard,defaults /dev/disk/by-id/\$DISK /mnt/mydisk

echo 'Persisting mount...'
echo \"/dev/disk/by-id/\$DISK /mnt/mydisk ext4 defaults 1 1\" | sudo tee -a /etc/fstab

echo 'Disk mounted successfully!'
"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo

# ================== CLEANUP ==================
echo "${YELLOW_TEXT}Removing script...${RESET_FORMAT}"
rm -f -- "$0"
