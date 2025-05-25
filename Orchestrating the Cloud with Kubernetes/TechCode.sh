#!/bin/bash

# Bright Foreground Colors
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Start of the script
echo
echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# User input for ZONE
echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}"
read -p "Zone: " ZONE
export ZONE

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Setting compute zone to $ZONE...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating a GKE cluster named 'io'...${RESET_FORMAT}"
gcloud container clusters create io

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Copying files from Google Cloud Storage...${RESET_FORMAT}"
gsutil cp -r gs://spls/gsp021/* .

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Changing directory to 'orchestrate-with-kubernetes/kubernetes'...${RESET_FORMAT}"
cd orchestrate-with-kubernetes/kubernetes

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating an NGINX deployment...${RESET_FORMAT}"
kubectl create deployment nginx --image=nginx:1.10.0

echo
echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Waiting for 20 seconds...${RESET_FORMAT}"
sleep 20

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Exposing the NGINX deployment on port 80...${RESET_FORMAT}"
kubectl expose deployment nginx --port 80 --type LoadBalancer

echo
echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Waiting for 80 seconds...${RESET_FORMAT}"
sleep 80

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Fetching service details...${RESET_FORMAT}"
kubectl get services

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Changing back to 'orchestrate-with-kubernetes/kubernetes' directory...${RESET_FORMAT}"
cd ~/orchestrate-with-kubernetes/kubernetes

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating a monolith pod...${RESET_FORMAT}"
kubectl create -f pods/monolith.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating TLS secrets and NGINX proxy configuration...${RESET_FORMAT}"
kubectl create secret generic tls-certs --from-file tls/
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating a secure monolith pod...${RESET_FORMAT}"
kubectl create -f pods/secure-monolith.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating a monolith service...${RESET_FORMAT}"
kubectl create -f services/monolith.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating a firewall rule to allow traffic on port 31000...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-monolith-nodeport \
  --allow=tcp:31000

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Labeling the secure-monolith pod...${RESET_FORMAT}"
kubectl label pods secure-monolith 'secure=enabled'
kubectl get pods secure-monolith --show-labels

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating the auth deployment and service...${RESET_FORMAT}"
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating the hello deployment and service...${RESET_FORMAT}"
kubectl create -f deployments/hello.yaml
kubectl create -f services/hello.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating the frontend configuration and deployment...${RESET_FORMAT}"
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf
kubectl create -f deployments/frontend.yaml
kubectl create -f services/frontend.yaml

echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
