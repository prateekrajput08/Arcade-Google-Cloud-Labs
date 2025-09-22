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

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run command with spinner
run_with_spinner() {
    local command="$1"
    local message="$2"
    
    echo -n "${GREEN_TEXT}${BOLD_TEXT}$message... ${RESET_FORMAT}"
    (eval "$command" > /dev/null 2>&1) &
    spinner
    echo "${BLUE_TEXT}✓${RESET_FORMAT}"
}

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


echo -n "${YELLOW_TEXT}${BOLD_TEXT}Please enter the zone: ${RESET_FORMAT}"
read ZONE
export ZONE

# Enable the required API
run_with_spinner \
    "gcloud services enable file.googleapis.com" \
    "${MAGENTA_TEXT}${BOLD_TEXT}Enabling the Filestore API"

# Create a Compute Engine instance with Debian 12 (bookworm)
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Compute Engine instance named 'nfs-client'...${RESET_FORMAT}"
run_with_spinner \
    "gcloud compute instances create nfs-client \
    --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=nfs-client,image=projects/debian-cloud/global/images/debian-12-bookworm-v20231010,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any" \
    "Creating Compute Engine instance"

# Create a Filestore instance
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Filestore instance named 'nfs-server'...${RESET_FORMAT}"
run_with_spinner \
    "gcloud filestore instances create nfs-server \
    --zone=$ZONE --tier=BASIC_HDD \
    --file-share=name=\"vol1\",capacity=1TB \
    --network=name=\"default\"" \
    "Creating Filestore instance"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
