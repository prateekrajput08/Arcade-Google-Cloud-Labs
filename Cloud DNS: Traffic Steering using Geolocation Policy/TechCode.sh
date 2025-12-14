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

# ========================= WELCOME MESSAGE =========================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ========================= USER INPUT SECTION =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}### PLEASE ENTER REGION & ZONE DETAILS (MANDATORY) ###${RESET_FORMAT}"
echo

read -p "${GREEN_TEXT}Enter Region 1 (e.g. us-east1): ${RESET_FORMAT}" region1
read -p "${GREEN_TEXT}Enter Zone 1   (e.g. us-east1-b): ${RESET_FORMAT}" zone1

read -p "${GREEN_TEXT}Enter Region 2 (e.g. europe-west4): ${RESET_FORMAT}" region2
read -p "${GREEN_TEXT}Enter Zone 2   (e.g. europe-west4-a): ${RESET_FORMAT}" zone2

read -p "${GREEN_TEXT}Enter Region 3 (e.g. asia-south1): ${RESET_FORMAT}" region3
read -p "${GREEN_TEXT}Enter Zone 3   (e.g. asia-south1-a): ${RESET_FORMAT}" zone3

# Validation
if [[ -z "$region1" || -z "$zone1" || -z "$region2" || -z "$zone2" || -z "$region3" || -z "$zone3" ]]; then
    echo
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: All region and zone values are required. Exiting...${RESET_FORMAT}"
    exit 1
fi

echo
echo "${CYAN_TEXT}${BOLD_TEXT}✔ Region & Zone details captured successfully${RESET_FORMAT}"
echo

# ========================= AUTH & PROJECT INFO =========================
gcloud auth list
gcloud config list project

# ========================= ENABLE REQUIRED SERVICES =========================
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com

sleep 20

gcloud services list | grep -E 'compute|dns'

# ========================= FIREWALL RULES =========================
gcloud compute firewall-rules create fw-default-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20

gcloud compute firewall-rules create allow-http-traffic \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:80 \
--source-ranges=0.0.0.0/0 \
--target-tags=http-server

# ========================= CLIENT VMs =========================
gcloud compute instances create us-client-vm --machine-type e2-micro --zone $zone1
gcloud compute instances create europe-client-vm --machine-type e2-micro --zone $zone2
gcloud compute instances create asia-client-vm --machine-type e2-micro --zone $zone3

# ========================= WEB VMs =========================
gcloud compute instances create us-web-vm \
--zone=$zone1 \
--machine-type=e2-micro \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
apt-get update
apt-get install apache2 -y
echo "Page served from: us-east1" | tee /var/www/html/index.html
systemctl restart apache2'

gcloud compute instances create europe-web-vm \
--zone=$zone2 \
--machine-type=e2-micro \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
apt-get update
apt-get install apache2 -y
echo "Page served from: europe-west4" | tee /var/www/html/index.html
systemctl restart apache2'

sleep 20

# ========================= INTERNAL IPs =========================
export US_WEB_IP=$(gcloud compute instances describe us-web-vm --zone=$zone1 --format="value(networkInterfaces.networkIP)")
export EUROPE_WEB_IP=$(gcloud compute instances describe europe-web-vm --zone=$zone2 --format="value(networkInterfaces.networkIP)")

# ========================= CLOUD DNS =========================
gcloud dns managed-zones create example \
--description=test \
--dns-name=example.com \
--networks=default \
--visibility=private

gcloud dns record-sets create geo.example.com \
--ttl=5 \
--type=A \
--zone=example \
--routing-policy-type=GEO \
--routing-policy-data="$region1=$US_WEB_IP;$region2=$EUROPE_WEB_IP"

gcloud dns record-sets list --zone=example

# ========================= COMPLETION MESSAGE =========================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
