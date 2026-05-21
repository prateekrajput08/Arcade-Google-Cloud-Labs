#!/bin/bash

# =========================================================
# GOOGLE CLOUD GKE NETWORK POLICY LAB AUTOMATION
# Tech & Code
# =========================================================

# ---------------- COLORS ----------------

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

echo "${BLUE_TEXT}${BOLD_TEXT}Fetching Project Configuration...${RESET_FORMAT}"
echo

gcloud config set project $(gcloud projects list \
  --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")


gcloud config set project "$PROJECT_ID" >/dev/null 2>&1
gcloud config set compute/region "$REGION" >/dev/null 2>&1
gcloud config set compute/zone "$ZONE" >/dev/null 2>&1

echo "${GREEN_TEXT}Project ID : ${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}Region     : ${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone       : ${ZONE}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Downloading Lab Resources...${RESET_FORMAT}"
echo

rm -rf gke-network-policy-demo

gsutil cp -r gs://spls/gsp480/gke-network-policy-demo . || exit 1

cd gke-network-policy-demo || exit 1

chmod -R 755 *

echo
echo "${GREEN_TEXT}Lab files downloaded successfully.${RESET_FORMAT}"
echo

# =========================================================
# PROJECT SETUP
# =========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting Up Project APIs & Terraform Variables...${RESET_FORMAT}"
echo

yes | make setup-project

echo
echo "${GREEN_TEXT}Project setup completed.${RESET_FORMAT}"
echo

# =========================================================
# TERRAFORM APPLY
# =========================================================

echo "${MAGENTA_TEXT}${BOLD_TEXT}Provisioning Infrastructure using Terraform...${RESET_FORMAT}"
echo "${YELLOW_TEXT}This process may take several minutes...${RESET_FORMAT}"
echo

yes | make tf-apply

if [ $? -ne 0 ]; then
    echo
    echo "${RED_TEXT}${BOLD_TEXT}Terraform deployment failed.${RESET_FORMAT}"
    exit 1
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Infrastructure Provisioned Successfully.${RESET_FORMAT}"
echo

# =========================================================
# WAIT FOR STABILIZATION
# =========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for Infrastructure Stabilization...${RESET_FORMAT}"
echo

sleep 60

# =========================================================
# SSH INTO BASTION
# =========================================================

echo "${CYAN_TEXT}${BOLD_TEXT}Connecting to Bastion Host...${RESET_FORMAT}"
echo

gcloud compute ssh gke-demo-bastion \
--zone "$ZONE" \
--quiet << EOF

echo "Installing GKE Auth Plugin..."

sudo apt-get update -y

sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin

echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc

source ~/.bashrc

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

echo "Downloading Lab Files Inside Bastion..."

rm -rf gke-network-policy-demo

gsutil cp -r gs://spls/gsp480/gke-network-policy-demo .

cd gke-network-policy-demo || exit 1

chmod -R 755 *

echo "Fetching Cluster Credentials..."

gcloud container clusters get-credentials gke-demo-cluster --zone "$ZONE"

kubectl apply -f ./manifests/hello-app/

echo
echo "Waiting for Pods to Become Ready..."
echo

kubectl wait --for=condition=Ready pod --all --timeout=300s

echo "Current Pods:"

kubectl get pods

sleep 180

kubectl apply -f ./manifests/network-policy.yaml

sleep 30

kubectl logs --tail 10 \$(kubectl get pods -oname -l app=not-hello)

kubectl delete -f ./manifests/network-policy.yaml

sleep 15

kubectl create -f ./manifests/network-policy-namespaced.yaml

sleep 20

kubectl logs --tail 10 \$(kubectl get pods -oname -l app=hello)

kubectl -n hello-apps apply \
-f ./manifests/hello-app/hello-client.yaml

echo
echo "Waiting for Namespace Pods..."
echo

kubectl wait --for=condition=Ready pod \
--all -n hello-apps --timeout=300s

kubectl logs --tail 10 -n hello-apps \
\$(kubectl get pods -oname -l app=hello -n hello-apps)

kubectl get pods -A

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
