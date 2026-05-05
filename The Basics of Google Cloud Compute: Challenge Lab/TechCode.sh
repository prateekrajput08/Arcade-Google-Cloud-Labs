#!/bin/bash
# ========================= COLOR DEFINITIONS =========================
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear
set -e

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ========================= AUTO-FETCH ALL VALUES =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Auto-fetching environment values...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

# Fallback if zone/region not set in project metadata
if [[ -z "$ZONE" ]]; then
  ZONE="us-west1-c"
  echo "${YELLOW_TEXT}⚠ Zone not found in metadata, using default: $ZONE${RESET_FORMAT}"
fi
if [[ -z "$REGION" ]]; then
  REGION="us-west1"
  echo "${YELLOW_TEXT}⚠ Region not found in metadata, using default: $REGION${RESET_FORMAT}"
fi

# Auto-fetch bucket name from lab project ID
BUCKET_NAME="${PROJECT_ID}-bucket"

INSTANCE_NAME="my-instance"
DISK_NAME="mydisk"

# ========================= VALIDATION =========================
if [[ -z "$PROJECT_ID" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}❌ ERROR: PROJECT_ID is empty. Are you logged in?${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}✔ Project ID  : $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Zone        : $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Region      : $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Bucket Name : $BUCKET_NAME${RESET_FORMAT}"
echo

# ========================= ENABLE API =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Enabling Compute Engine API...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com
echo

# ========================= TASK 1: BUCKET =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Cloud Storage Bucket...${RESET_FORMAT}"
gsutil mb -l US gs://$BUCKET_NAME
echo

# ========================= TASK 2: CREATE INSTANCE =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Compute Engine Instance...${RESET_FORMAT}"
gcloud compute instances create $INSTANCE_NAME \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server
echo

# ========================= TASK 2: CREATE DISK =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Persistent Disk...${RESET_FORMAT}"
gcloud compute disks create $DISK_NAME \
  --size=200GB \
  --zone=$ZONE
echo

# ========================= TASK 2: ATTACH DISK =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Attaching Disk to VM...${RESET_FORMAT}"
gcloud compute instances attach-disk $INSTANCE_NAME \
  --disk=$DISK_NAME \
  --zone=$ZONE
echo

# ========================= TASK 3: INSTALL NGINX =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Installing NGINX via SSH...${RESET_FORMAT}"
gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --quiet --command="
sudo apt update -y &&
sudo apt install -y nginx &&
sudo systemctl enable nginx &&
sudo systemctl start nginx
"
echo

# ========================= FIREWALL =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Creating Firewall Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --target-tags=http-server \
  --direction=INGRESS \
  --priority=1000 \
  --network=default
echo

# ========================= COMPLETION =========================
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         ALL TASKS COMPLETED SUCCESSFULLY               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${CYAN_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
