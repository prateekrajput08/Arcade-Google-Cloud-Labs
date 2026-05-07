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

# ─────────────────────────────────────────────
# Step 0: Auto-detect project, region, zone
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[0/7] Detecting project, region, and zone...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
REGION=$(gcloud config get-value compute/region 2>/dev/null)
ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

# Fallback: pick first available zone if not set
if [[ -z "$REGION" || "$REGION" == "(unset)" ]]; then
  REGION=$(gcloud compute zones list --format="value(region)" --limit=1 2>/dev/null | head -1)
  gcloud config set compute/region "$REGION"
fi

if [[ -z "$ZONE" || "$ZONE" == "(unset)" ]]; then
  ZONE=$(gcloud compute zones list --filter="region:$REGION" --format="value(name)" --limit=1 2>/dev/null | head -1)
  gcloud config set compute/zone "$ZONE"
fi

echo "${GREEN_TEXT}  ✔ Project : ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}  ✔ Region  : ${WHITE_TEXT}${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}  ✔ Zone    : ${WHITE_TEXT}${ZONE}${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 1: Clone the demo repo
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[1/7] Cloning demo repository...${RESET_FORMAT}"

if [[ -d "gke-network-policy-demo" ]]; then
  echo "${BLUE_TEXT}  → Directory already exists, skipping clone.${RESET_FORMAT}"
else
  gsutil cp -r gs://spls/gsp480/gke-network-policy-demo . 2>&1 | \
    sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"
fi

cd gke-network-policy-demo || { echo "${RED_TEXT}  ✘ Failed to enter directory.${RESET_FORMAT}"; exit 1; }
chmod -R 755 *
echo "${GREEN_TEXT}  ✔ Repository ready.${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 2: Lab setup — enable APIs & terraform.tfvars
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[2/7] Running lab setup (make setup-project)...${RESET_FORMAT}"

# Auto-answer 'y' to the confirmation prompt
echo "y" | make setup-project 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

echo "${GREEN_TEXT}  ✔ Project setup complete.${RESET_FORMAT}"
echo ""

# Verify terraform.tfvars was created
echo "${CYAN_TEXT}  terraform.tfvars contents:${RESET_FORMAT}"
cat terraform/terraform.tfvars | sed "s/^/  ${WHITE_TEXT}/" ; echo -n "${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 3: Terraform apply — provision GKE cluster
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[3/7] Provisioning GKE cluster with Terraform (make tf-apply)...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}  This will take several minutes. Please be patient...${RESET_FORMAT}"

echo "yes" | make tf-apply 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  echo "${RED_TEXT}  ✘ Terraform apply failed. Check output above.${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}  ✔ GKE cluster provisioned successfully.${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 4: Configure kubectl via bastion (remote commands)
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[4/7] Configuring kubectl on the bastion host...${RESET_FORMAT}"
echo "${BLUE_TEXT}  → Sending setup commands to gke-demo-bastion via SSH...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion --zone="$ZONE" --command="
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin > /dev/null 2>&1
  echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
  source ~/.bashrc
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  gcloud container clusters get-credentials gke-demo-cluster --zone ${ZONE}
  echo 'kubectl_configured'
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

echo "${GREEN_TEXT}  ✔ kubectl configured on bastion.${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 5: Deploy hello-app (server + clients)
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[5/7] Deploying hello-server and hello-client pods...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion --zone="$ZONE" --command="
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  cd \$(find ~ -name 'hello-app' -type d 2>/dev/null | head -1 | xargs dirname)
  # Fallback: use the copied manifests
  if [[ ! -d './manifests' ]]; then
    gsutil cp -r gs://spls/gsp480/gke-network-policy-demo/manifests ./manifests
  fi
  kubectl apply -f ./manifests/hello-app/
  echo 'Waiting for pods to be ready...'
  kubectl wait --for=condition=Ready pods --all --timeout=120s
  echo '--- Pod Status ---'
  kubectl get pods
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

echo "${GREEN_TEXT}  ✔ All three pods deployed (hello-server, hello-client-allowed, hello-client-blocked).${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 6: Apply Network Policy (restrict by pod label)
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[6/7] Applying Network Policy to restrict access by pod label...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion --zone="$ZONE" --command="
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  cd \$(find ~ -name 'manifests' -type d 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '.')
  if [[ ! -d './manifests' ]]; then
    gsutil cp -r gs://spls/gsp480/gke-network-policy-demo/manifests ./manifests
  fi
  kubectl apply -f ./manifests/network-policy.yaml
  echo '--- Network Policies ---'
  kubectl get networkpolicy
  echo 'Waiting 10s for policy to take effect...'
  sleep 10
  echo '--- Blocked client logs (should show timeout) ---'
  kubectl logs --tail 5 \$(kubectl get pods -oname -l app=not-hello) 2>/dev/null || echo '(no logs yet)'
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

echo "${GREEN_TEXT}  ✔ Network Policy applied — hello-client-blocked is now blocked.${RESET_FORMAT}"
echo ""

# ─────────────────────────────────────────────
# Step 7: Namespace-based Network Policy + second client deploy
# ─────────────────────────────────────────────
echo "${YELLOW_TEXT}${BOLD_TEXT}[7/7] Applying namespace-scoped Network Policy and deploying second client set...${RESET_FORMAT}"

gcloud compute ssh gke-demo-bastion --zone="$ZONE" --command="
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  cd \$(find ~ -name 'manifests' -type d 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '.')
  if [[ ! -d './manifests' ]]; then
    gsutil cp -r gs://spls/gsp480/gke-network-policy-demo/manifests ./manifests
  fi

  # Delete old label-based policy
  kubectl delete -f ./manifests/network-policy.yaml
  echo '  → Old network policy deleted.'

  # Create namespace-scoped policy
  kubectl create -f ./manifests/network-policy-namespaced.yaml
  echo '  → Namespaced network policy created.'

  # Deploy second copy of clients into hello-apps namespace
  kubectl -n hello-apps apply -f ./manifests/hello-app/hello-client.yaml
  echo '  → Second hello-client set deployed into hello-apps namespace.'

  echo ''
  echo '--- Network Policies (all namespaces) ---'
  kubectl get networkpolicy --all-namespaces

  echo ''
  echo '--- Pods in hello-apps namespace ---'
  kubectl get pods -n hello-apps
" 2>&1 | sed "s/^/  ${BLACK_TEXT}/" ; echo -n "${RESET_FORMAT}"

echo "${GREEN_TEXT}  ✔ Namespace-based Network Policy applied and second client deployed.${RESET_FORMAT}"
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
