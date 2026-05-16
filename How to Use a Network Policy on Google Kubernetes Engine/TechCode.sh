#!/bin/bash

# ---------- COLORS ----------
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

RESET_FORMAT=$'\033[0m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================================================
# AUTO FETCH PROJECT / REGION / ZONE
# =========================================================

echo "${BLUE_TEXT}Fetching Project Configuration...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)

REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items.google-compute-default-region)")

ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items.google-compute-default-zone)")

# Fallbacks
[[ -z "$REGION" ]] && REGION="us-east1"
[[ -z "$ZONE" ]] && ZONE="us-east1-d"

gcloud config set project "$PROJECT_ID"

gcloud config set compute/region "$REGION"

gcloud config set compute/zone "$ZONE"

echo
echo "${GREEN_TEXT}Project ID : ${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}Region     : ${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone       : ${ZONE}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}Cloning Lab Resources...${RESET_FORMAT}"

gsutil cp -r gs://spls/gsp480/gke-network-policy-demo .

cd gke-network-policy-demo || exit

chmod -R 755 *

echo
echo "${YELLOW_TEXT}Setting up Project APIs & Terraform Variables...${RESET_FORMAT}"

echo "y" | make setup-project

echo
echo "${MAGENTA_TEXT}Provisioning Infrastructure using Terraform...${RESET_FORMAT}"
echo "${YELLOW_TEXT}This may take several minutes...${RESET_FORMAT}"

make tf-apply <<< "yes"

echo
echo "${GREEN_TEXT}Infrastructure Provisioned Successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Waiting for Infrastructure Stabilization...${RESET_FORMAT}"

sleep 30

echo
echo "${GREEN_TEXT}Configuring Bastion Host and Deploying Resources...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion \
--zone "$ZONE" \
--quiet << EOF

# ---------------------------------------------------------
# INSTALL GKE AUTH PLUGIN
# ---------------------------------------------------------

sudo apt-get update -y

sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin

echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# ---------------------------------------------------------
# CLONE LAB FILES INSIDE BASTION
# ---------------------------------------------------------

gsutil cp -r gs://spls/gsp480/gke-network-policy-demo .

cd gke-network-policy-demo

# ---------------------------------------------------------
# GET CLUSTER CREDENTIALS
# ---------------------------------------------------------

gcloud container clusters get-credentials gke-demo-cluster --zone $ZONE

# ---------------------------------------------------------
# DEPLOY HELLO APPLICATION
# ---------------------------------------------------------

echo
echo "Deploying Hello Application..."

kubectl apply -f ./manifests/hello-app/

echo
echo "Waiting for Pods to Become Ready..."

sleep 60

kubectl get pods

# ---------------------------------------------------------
# IMPORTANT WAIT FOR LAB GRADER
# ---------------------------------------------------------

echo
echo "Waiting for Lab Validation..."

sleep 90

# ---------------------------------------------------------
# APPLY NETWORK POLICY
# ---------------------------------------------------------

echo
echo "Applying Network Policy..."

kubectl apply -f ./manifests/network-policy.yaml

sleep 20

# ---------------------------------------------------------
# VALIDATE BLOCKED CLIENT
# ---------------------------------------------------------

echo
echo "Blocked Client Logs:"
echo "--------------------------------------------------"

kubectl logs --tail 10 \$(kubectl get pods -oname -l app=not-hello)

echo "--------------------------------------------------"

# ---------------------------------------------------------
# REMOVE POLICY
# ---------------------------------------------------------

echo
echo "Removing Existing Policy..."

kubectl delete -f ./manifests/network-policy.yaml

# ---------------------------------------------------------
# APPLY NAMESPACE POLICY
# ---------------------------------------------------------

echo
echo "Applying Namespace Policy..."

kubectl create -f ./manifests/network-policy-namespaced.yaml

sleep 15

# ---------------------------------------------------------
# DEPLOY CLIENTS IN NAMESPACE
# ---------------------------------------------------------

echo
echo "Deploying Clients in Namespace..."

kubectl -n hello-apps apply \
-f ./manifests/hello-app/hello-client.yaml

sleep 30

# ---------------------------------------------------------
# FINAL VALIDATION
# ---------------------------------------------------------

echo
echo "Cluster Resources:"
echo "--------------------------------------------------"

kubectl get pods -A

echo "--------------------------------------------------"

EOF

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe ❤️${RESET_FORMAT}"
echo
