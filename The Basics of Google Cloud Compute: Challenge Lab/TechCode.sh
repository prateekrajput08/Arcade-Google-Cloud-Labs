#!/bin/bash

# ========================= COLOR DEFINITIONS =========================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear
set -e

# ========================= WELCOME MESSAGE =========================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ========================= PROJECT & ZONE =========================
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
ZONE=$(gcloud compute zones list --limit=1 --format="value(name)")

INSTANCE_NAME="techcode-vm"
DISK_NAME="techcode-disk"

# ========================= VALIDATION =========================
if [[ -z "$PROJECT_ID" || -z "$ZONE" || -z "$INSTANCE_NAME" || -z "$DISK_NAME" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}❌ ERROR: Required variables are empty${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}✔ Project ID : $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Zone       : $ZONE${RESET_FORMAT}"
echo

# ========================= ENABLE API =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Enabling Compute Engine API...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com
echo

# ========================= CREATE VM =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Compute Engine VM...${RESET_FORMAT}"
gcloud compute instances create "$INSTANCE_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud
echo

# ========================= CREATE DISK =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Persistent Disk...${RESET_FORMAT}"
gcloud compute disks create "$DISK_NAME" \
  --zone="$ZONE" \
  --size=10GB \
  --type=pd-balanced
echo

# ========================= ATTACH DISK =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Attaching Disk to VM...${RESET_FORMAT}"
gcloud compute instances attach-disk "$INSTANCE_NAME" \
  --disk="$DISK_NAME" \
  --zone="$ZONE"
echo

# ========================= SSH TEST =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Testing SSH connection...${RESET_FORMAT}"
gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="echo SSH Connected Successfully"
echo

# ========================= COMPLETION =========================
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              ALL TASKS COMPLETED SUCCESSFULLY          ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${CYAN_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
