#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Auto-fetch project and region/zone
echo "${YELLOW_TEXT}Fetching project info...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud compute instances list --format="value(zone)" --limit=1 | sed 's/-[a-z]$//')
ZONE=$(gcloud compute instances list --format="value(zone)" --limit=1)
VM1=$(gcloud compute instances list --format="value(name)" | grep -v "1$" | head -1)
VM2=$(gcloud compute instances list --format="value(name)" | grep "1$" | head -1)

# Fallback: list all VMs and pick first two
if [ -z "$VM1" ] || [ -z "$VM2" ]; then
  VMS=($(gcloud compute instances list --format="value(name)"))
  VM1="${VMS[0]}"
  VM2="${VMS[1]}"
fi

echo "${WHITE_TEXT}Project : ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${WHITE_TEXT}Region  : ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${WHITE_TEXT}Zone    : ${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${WHITE_TEXT}VM1     : ${BOLD_TEXT}$VM1${RESET_FORMAT}"
echo "${WHITE_TEXT}VM2     : ${BOLD_TEXT}$VM2${RESET_FORMAT}"
echo ""

# ─── TASK 1: Instance Groups ───────────────────────────────────────────────────

echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 1] Creating Instance Groups...${RESET_FORMAT}"

echo "${YELLOW_TEXT}Creating web-server-1 (VM: $VM1)...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged create web-server-1 \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

gcloud compute instance-groups unmanaged add-instances web-server-1 \
  --zone="$ZONE" \
  --instances="$VM1" \
  --project="$PROJECT_ID"

echo "${GREEN_TEXT}✔ web-server-1 created${RESET_FORMAT}"

echo "${YELLOW_TEXT}Creating web-server-2 (VM: $VM2)...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged create web-server-2 \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

gcloud compute instance-groups unmanaged add-instances web-server-2 \
  --zone="$ZONE" \
  --instances="$VM2" \
  --project="$PROJECT_ID"

echo "${GREEN_TEXT}✔ web-server-2 created${RESET_FORMAT}"

# ─── TASK 2: Health Check ──────────────────────────────────────────────────────

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 2] Creating Health Check...${RESET_FORMAT}"

gcloud compute health-checks create tcp basic-http-check \
  --region="$REGION" \
  --port=80 \
  --project="$PROJECT_ID"

echo "${GREEN_TEXT}✔ Health check basic-http-check created${RESET_FORMAT}"

# ─── TASK 2: Static IP ────────────────────────────────────────────────────────

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 2] Reserving Static External IP...${RESET_FORMAT}"

gcloud compute addresses create network-lb-ip \
  --region="$REGION" \
  --project="$PROJECT_ID"

LB_IP=$(gcloud compute addresses describe network-lb-ip \
  --region="$REGION" \
  --format="value(address)" \
  --project="$PROJECT_ID")

echo "${GREEN_TEXT}✔ Static IP reserved: ${BOLD_TEXT}$LB_IP${RESET_FORMAT}"

# ─── TASK 2: Backend Service ──────────────────────────────────────────────────

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 2] Creating Backend Service...${RESET_FORMAT}"

gcloud compute backend-services create network-lb-backend-service \
  --protocol=TCP \
  --region="$REGION" \
  --health-checks=basic-http-check \
  --health-checks-region="$REGION" \
  --project="$PROJECT_ID"

echo "${YELLOW_TEXT}Adding backends...${RESET_FORMAT}"

gcloud compute backend-services add-backend network-lb-backend-service \
  --instance-group=web-server-1 \
  --instance-group-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

gcloud compute backend-services add-backend network-lb-backend-service \
  --instance-group=web-server-2 \
  --instance-group-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo "${GREEN_TEXT}✔ Backend service created with both instance groups${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED${RESET_FORMAT}"
echo ""
echo "Name: network-lb-backend-service"
echo "Health Check: basic-http-check"
echo "Backends: web-server-1 and web-server-2"
echo "Frontend IP: network-lb-ip"
echo "Port: 80"
echo ""
echo "Open the following URL:"
echo "https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID"
echo ""
read -p "${YELLOW_TEXT}${BOLD_TEXT}Create the load balancer, then press ENTER to continue...${RESET_FORMAT}"

echo "${GREEN_TEXT}✔ Backend service created with both instance groups${RESET_FORMAT}"

# ─── TASK 2: Target Pool + Forwarding Rule ────────────────────────────────────

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 2] Creating Target Pool & Forwarding Rule...${RESET_FORMAT}"

gcloud compute target-pools add-instances network-lb-target-pool \
  --instances="$VM1","$VM2" \
  --instances-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo "${YELLOW_TEXT}Creating forwarding rule...${RESET_FORMAT}"

echo "${GREEN_TEXT}✔ Forwarding rule created${RESET_FORMAT}"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
