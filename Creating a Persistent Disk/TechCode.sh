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

# ================== INPUT ==================
echo "${CYAN_TEXT}${BOLD_TEXT}Enter Zone (example: us-east4-c): ${RESET_FORMAT}"
read ZONE

# ================== AUTO FETCH ==================
echo "${YELLOW_TEXT}Fetching project details...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
REGION=$(echo $ZONE | sed 's/-[a-z]$//')

export ZONE
export REGION

echo "${GREEN_TEXT}Project: $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Region: $REGION${RESET_FORMAT}"

# ================== SET CONFIG ==================
echo "${BLUE_TEXT}Setting compute zone & region...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE >/dev/null 2>&1
gcloud config set compute/region $REGION >/dev/null 2>&1

echo "${GREEN_TEXT}Config set successfully!${RESET_FORMAT}"

# ================== CREATE VM ==================
echo "${MAGENTA_TEXT}Creating VM instance (gcelab)...${RESET_FORMAT}"
gcloud compute instances create gcelab \
  --zone $ZONE \
  --machine-type e2-standard-2

echo "${GREEN_TEXT}VM created successfully!${RESET_FORMAT}"

# ================== CREATE DISK ==================
echo "${CYAN_TEXT}Creating persistent disk (mydisk)...${RESET_FORMAT}"
gcloud compute disks create mydisk \
  --size=200GB \
  --zone $ZONE

echo "${GREEN_TEXT}Disk created successfully!${RESET_FORMAT}"

# ================== ATTACH DISK ==================
echo "${YELLOW_TEXT}Attaching disk to VM...${RESET_FORMAT}"
gcloud compute instances attach-disk gcelab \
  --disk mydisk \
  --zone $ZONE

echo "${GREEN_TEXT}Disk attached successfully!${RESET_FORMAT}"

# ================== REMOTE SETUP ==================
echo "${BLUE_TEXT}Formatting & mounting disk via SSH...${RESET_FORMAT}"

gcloud compute ssh gcelab --zone $ZONE --command="
echo 'Creating mount directory...'
sudo mkdir -p /mnt/mydisk

echo 'Formatting disk...'
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
/dev/disk/by-id/scsi-0Google_PersistentDisk_mydisk

echo 'Mounting disk...'
sudo mount -o discard,defaults \
/dev/disk/by-id/scsi-0Google_PersistentDisk_mydisk /mnt/mydisk

echo 'Persisting mount...'
echo '/dev/disk/by-id/scsi-0Google_PersistentDisk_mydisk /mnt/mydisk ext4 defaults 1 1' | sudo tee -a /etc/fstab

echo 'Done inside VM!'
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

echo "${YELLOW_TEXT}Removing script file...${RESET_FORMAT}"
rm TechCode.sh
