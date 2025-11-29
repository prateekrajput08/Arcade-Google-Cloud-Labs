#!/bin/bash

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

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Assigning variables
echo "${BOLD_TEXT}${BLUE_TEXT}Assigning variables${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
export CLUSTER=hello-cluster
export REPO=my-repository

# Step 2: Enable required GCP services
echo "${BOLD_TEXT}${YELLOW_TEXT}Enabling Required GCP Services${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com

# Step 3: Create Artifact Repository
echo "${BOLD_TEXT}${CYAN_TEXT}Creating Artifact Repository${RESET_FORMAT}"
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="Awesome Lab"

sleep 20

# Step 4: Assign IAM roles to Cloud Build service account
echo "${BOLD_TEXT}${MAGENTA_TEXT}Adding IAM Policy Binding${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")@cloudbuild.gserviceaccount.com --role="roles/container.developer"

# Step 5: Install GitHub CLI and configure Git
echo "${BOLD_TEXT}${BLUE_TEXT}Installing GitHub CLI and Configuring Git${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh
gh auth login
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

# Step 6: Create Kubernetes cluster
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Kubernetes Cluster${RESET_FORMAT}"
gcloud beta container --project "$PROJECT_ID" clusters create "$CLUSTER" --zone "$ZONE" --no-enable-basic-auth --cluster-version latest --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-autoscaling --min-nodes "2" --max-nodes "6" --location-policy "BALANCED" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "$ZONE"

# Step 7: Configure Kubernetes
echo "${BOLD_TEXT}${CYAN_TEXT}Configuring Kubernetes${RESET_FORMAT}"
gcloud container clusters get-credentials hello-cluster --zone=$ZONE
kubectl create namespace prod
kubectl create namespace dev

# Step 8: Clone and Configure GitHub Repository
echo "${BOLD_TEXT}${MAGENTA_TEXT}Cloning and Configuring GitHub Repository${RESET_FORMAT}"
gh repo create sample-app --private
git clone https://github.com/${GITHUB_USERNAME}/sample-app.git
cd ~
gsutil cp -r gs://spls/gsp330/sample-app/* sample-app
for file in sample-app/cloudbuild-dev.yaml sample-app/cloudbuild.yaml; do
    sed -i "s/<your-region>/${REGION}/g" "$file"
    sed -i "s/<your-zone>/${ZONE}/g" "$file"
done

git init
cd sample-app/
git checkout -b master
git add .
git commit -m "Awesome Lab" 
git push -u origin master

git add .
git commit -m "Initial commit with sample code"
git push origin master
git checkout -b dev
git commit -m "Initial commit for dev branch"
git push origin dev

# Step 9: Output Cloud Build Trigger Link
echo "${BOLD_TEXT}${YELLOW_TEXT}Cloud Build Trigger Link${RESET_FORMAT}"
echo "${BOLD_TEXT}${BLUE_TEXT}Visit this link to configure triggers: ${RESET_FORMAT}" "https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
