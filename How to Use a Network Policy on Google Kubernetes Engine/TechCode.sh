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

# ==========================================================
# STEP 0 - DETECT PROJECT / REGION / ZONE
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[0/8] Detecting Google Cloud environment...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

REGION=$(gcloud config get-value compute/region 2>/dev/null)
ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

# Auto detect region if unset
if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
    REGION=$(gcloud compute regions list --format="value(name)" --limit=1)
    gcloud config set compute/region "$REGION" >/dev/null 2>&1
fi

# Auto detect zone if unset
if [[ -z "$ZONE" || "$ZONE" == "(unset)" ]]; then
    ZONE=$(gcloud compute zones list \
        --filter="region:(${REGION})" \
        --format="value(name)" \
        --limit=1)
    gcloud config set compute/zone "$ZONE" >/dev/null 2>&1
fi

echo "${GREEN_TEXT}✔ Project : ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Region  : ${WHITE_TEXT}${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}✔ Zone    : ${WHITE_TEXT}${ZONE}${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 1 - DOWNLOAD LAB FILES
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[1/8] Downloading lab files...${RESET_FORMAT}"

if [[ -d "gke-network-policy-demo" ]]; then
    echo "${BLUE_TEXT}→ Lab directory already exists. Skipping download.${RESET_FORMAT}"
else
    gsutil cp -r gs://spls/gsp480/gke-network-policy-demo . \
        2>&1 | sed "s/^/  ${BLACK_TEXT}/"
fi

cd gke-network-policy-demo || {
    echo "${RED_TEXT}✘ Failed to enter lab directory.${RESET_FORMAT}"
    exit 1
}

chmod -R 755 *

echo "${GREEN_TEXT}✔ Lab files ready.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 2 - SET REGION & ZONE
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[2/8] Setting compute region and zone...${RESET_FORMAT}"

gcloud config set compute/region "$REGION" >/dev/null
gcloud config set compute/zone "$ZONE" >/dev/null

echo "${GREEN_TEXT}✔ Region and zone configured.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 3 - SETUP PROJECT
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[3/8] Running project setup...${RESET_FORMAT}"

echo "y" | make setup-project \
    2>&1 | sed "s/^/  ${BLACK_TEXT}/"

if [[ ${PIPESTATUS[1]} -ne 0 ]]; then
    echo "${RED_TEXT}✘ setup-project failed.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}✔ Project setup complete.${RESET_FORMAT}"
echo ""

echo "${CYAN_TEXT}terraform.tfvars:${RESET_FORMAT}"
cat terraform/terraform.tfvars
echo ""

# ==========================================================
# STEP 4 - TERRAFORM APPLY
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[4/8] Creating GKE infrastructure...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}This may take several minutes...${RESET_FORMAT}"

echo "yes" | make tf-apply \
    2>&1 | sed "s/^/  ${BLACK_TEXT}/"

if [[ ${PIPESTATUS[1]} -ne 0 ]]; then
    echo "${RED_TEXT}✘ Terraform apply failed.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}✔ Infrastructure deployed successfully.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 5 - CONFIGURE BASTION + KUBECTL
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[5/8] Configuring bastion host and kubectl...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion \
    --zone="$ZONE" \
    --command="
sudo apt-get update -y >/dev/null 2>&1

sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin >/dev/null 2>&1

echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

gcloud container clusters get-credentials gke-demo-cluster --zone ${ZONE}

echo 'Bastion setup completed.'
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/"

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "${RED_TEXT}✘ Bastion setup failed.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}✔ Bastion configured successfully.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 6 - DEPLOY HELLO APPLICATION
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[6/8] Deploying hello application...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion \
    --zone="$ZONE" \
    --command="
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

cd ~/gke-network-policy-demo

kubectl apply -f ./manifests/hello-app/

echo ''
echo 'Waiting for pods to become ready...'

kubectl wait --for=condition=Ready pods --all --timeout=180s

echo ''
echo 'Current pods:'
kubectl get pods
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/"

echo "${GREEN_TEXT}✔ hello-server and clients deployed.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 7 - APPLY NETWORK POLICIES
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[7/8] Applying Network Policies...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion \
    --zone="$ZONE" \
    --command="
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

cd ~/gke-network-policy-demo

echo 'Applying pod label network policy...'

kubectl apply -f ./manifests/network-policy.yaml

sleep 10

echo ''
echo 'Blocked client logs:'

kubectl logs --tail=5 \$(kubectl get pods -oname -l app=not-hello)

echo ''
echo 'Replacing with namespace-based policy...'

kubectl delete -f ./manifests/network-policy.yaml

kubectl create -f ./manifests/network-policy-namespaced.yaml

echo ''
echo 'Deploying clients into hello-apps namespace...'

kubectl -n hello-apps apply -f ./manifests/hello-app/hello-client.yaml

echo ''
echo 'Pods in hello-apps namespace:'

kubectl get pods -n hello-apps
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/"

echo "${GREEN_TEXT}✔ Network Policies configured successfully.${RESET_FORMAT}"
echo ""

# ==========================================================
# STEP 8 - VALIDATION
# ==========================================================

echo "${YELLOW_TEXT}${BOLD_TEXT}[8/8] Validating final deployment...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion \
    --zone="$ZONE" \
    --command="
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

echo ''
echo '=== Network Policies ==='
kubectl get networkpolicy --all-namespaces

echo ''
echo '=== Pods ==='
kubectl get pods --all-namespaces
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/"

echo "${GREEN_TEXT}✔ Validation completed.${RESET_FORMAT}"
echo ""


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
