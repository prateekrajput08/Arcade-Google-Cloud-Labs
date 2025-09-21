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

clear

# Welcome message
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Exit on any error
set -e

# Constants
VM_NAME="speaking-with-a-webpage"
IMAGE_PROJECT="debian-cloud"
IMAGE_FAMILY="debian-12"
MACHINE_TYPE="e2-medium"

# Prompt for user input
read -p "Enter the zone (e.g. us-central1-b): " ZONE

echo "Starting setup in zone '$ZONE'..."

# Check if firewall rule 'dev-ports' exists, create if not
if ! gcloud compute firewall-rules describe dev-ports &>/dev/null; then
  echo "Creating firewall rule 'dev-ports' to allow TCP:8443 from 0.0.0.0/0..."
  gcloud compute firewall-rules create dev-ports \
    --allow=tcp:8443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server,https-server
else
  echo "Firewall rule 'dev-ports' already exists, skipping creation."
fi

# Check if VM already exists
if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
  echo "VM '$VM_NAME' already exists in zone '$ZONE'. Skipping VM creation."
else
  echo "Creating VM '$VM_NAME' in zone '$ZONE'..."
  gcloud compute instances create "$VM_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --tags=http-server,https-server \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --metadata=enable-oslogin=TRUE \
    --no-shielded-secure-boot \
    --quiet
fi

# Wait for instance to be ready (skip if VM existed)
echo "Waiting for instance to be ready..."
sleep 15

# SSH install dependencies and clone repo (idempotent)
echo "Installing packages and cloning repo via SSH..."
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  sudo apt-get update -y && \
  sudo apt-get install -y git maven openjdk-17-jdk lsof && \
  if [ ! -d speaking-with-a-webpage ]; then
    git clone https://github.com/googlecodelabs/speaking-with-a-webpage.git
  else
    echo 'Repository already cloned, skipping git clone.'
  fi
"

# Extra wait for VM readiness
echo "Waiting 30 seconds for VM to initialize..."
sleep 30

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "External IP address: $EXTERNAL_IP"

echo "Connecting to VM via SSH to start Task 3 Jetty server..."

# Start Task 3 server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java || true
  cd speaking-with-a-webpage/01-hello-https
  nohup mvn clean jetty:run > jetty.log 2>&1 &
"

echo "Jetty server for Task 3 started on VM."

echo "Open your browser and visit: https://$EXTERNAL_IP:8443"
echo "Your browser may warn about the self-signed SSL certificate — this is expected."

read -p "After confirming the servlet is working and you've checked your progress in the lab, press Enter to continue to Task 4..."

# Stop Task 3 Jetty server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  PID=\$(sudo lsof -ti tcp:8443)
  if [ -n \"\$PID\" ]; then
    sudo kill \$PID
    echo 'Task 3 Jetty server stopped.'
  else
    echo 'No Jetty server found on port 8443.'
  fi
"

# Start Task 4 server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  cd speaking-with-a-webpage/02-webaudio
  nohup mvn clean jetty:run > jetty.log 2>&1 &
  echo \$! > jetty.pid
"

echo "Jetty server for Task 4 started on VM."
echo "Open your browser and visit: https://$EXTERNAL_IP:8443"

read -p "After confirming the Task 4 servlet is working and you've checked your progress in the lab, press Enter to finish..."

echo "Lab completed! Remember to stop the server when you're done by running:"
echo "kill \$(cat jetty.pid)  # on the VM"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
