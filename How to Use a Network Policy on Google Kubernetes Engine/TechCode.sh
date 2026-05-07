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
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# --- 1. Environmental Setup ---
echo "${BLUE_TEXT}Fetching Project ID, Region, and Zone...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-region)")
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-zone)")

# Fallback if metadata is not set
[[ -z "$REGION" ]] && REGION="us-east1"
[[ -z "$ZONE" ]] && ZONE="us-east1-b"

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# --- 2. Clone and Prep ---
echo "${BLUE_TEXT}Cloning lab resources...${RESET_FORMAT}"
gsutil cp -r gs://spls/gsp480/gke-network-policy-demo .
cd gke-network-policy-demo
chmod -R 755 *

echo "${YELLOW_TEXT}Enabling APIs and generating Terraform vars...${RESET_FORMAT}"
# Using 'yes' to bypass the confirmation prompt in 'make setup-project'
yes | make setup-project

# --- 3. Provision Infrastructure ---
echo "${MAGENTA_TEXT}Running Terraform Apply (this will take several minutes)...${RESET_FORMAT}"
# Using -auto-approve for non-interactive execution
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# --- 4. Bastion Configuration ---
# Since we are in Cloud Shell, we need to send commands TO the bastion via SSH
echo "${GREEN_TEXT}Configuring GKE Auth Plugin on Bastion Host...${RESET_FORMAT}"
gcloud compute ssh gke-demo-bastion --zone "$ZONE" --quiet --command "
  sudo apt-get update && sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
  echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  gcloud container clusters get-credentials gke-demo-cluster --zone $ZONE
"

# --- 5. Deploy Applications ---
echo "${BLUE_TEXT}Deploying hello-app manifests...${RESET_FORMAT}"
gcloud compute ssh gke-demo-bastion --zone "$ZONE" --quiet --command "
  cd gke-network-policy-demo
  kubectl apply -f ./manifests/hello-app/
  echo 'Waiting for pods to be ready...'
  kubectl wait --for=condition=ready pod -l app=hello --timeout=90s
"

# --- 6. Apply Network Policy ---
echo "${YELLOW_TEXT}Applying Restrictive Network Policy...${RESET_FORMAT}"
gcloud compute ssh gke-demo-bastion --zone "$ZONE" --quiet --command "
  cd gke-network-policy-demo
  kubectl apply -f ./manifests/network-policy.yaml
"

# --- 7. Namespace Testing ---
echo "${MAGENTA_TEXT}Setting up Namespaced Network Policies...${RESET_FORMAT}"
gcloud compute ssh gke-demo-bastion --zone "$ZONE" --quiet --command "
  cd gke-network-policy-demo
  kubectl delete -f ./manifests/network-policy.yaml
  kubectl create -f ./manifests/network-policy-namespaced.yaml
  kubectl -n hello-apps apply -f ./manifests/hello-app/hello-client.yaml
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

