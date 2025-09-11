#!/bin/bash
# Enhanced Color Definitions
COLOR_BLACK=$'\033[0;30m'
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_MAGENTA=$'\033[0;35m'
COLOR_CYAN=$'\033[0;36m'
COLOR_WHITE=$'\033[0;37m'
COLOR_RESET=$'\033[0m'

# Text Formatting
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
BLINK=$'\033[5m'
REVERSE=$'\033[7m'

clear
# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Enable GCP Services
echo "${COLOR_BLUE}${BOLD}Enabling Required GCP Services...${COLOR_RESET}"
echo
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  osconfig.googleapis.com \
  pubsub.googleapis.com

# Set Project Variables
export PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION

# Configure IAM
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/eventarc.eventReceiver

# Update IAM Policy
gcloud projects get-iam-policy $PROJECT_ID > policy.yaml
cat <<EOF >> policy.yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: compute.googleapis.com
EOF
gcloud projects set-iam-policy $PROJECT_ID policy.yaml

# Deploy HTTP Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying HTTP Trigger Function...${COLOR_RESET}"
echo
mkdir ~/hello-http && cd $_
cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js 22 in GCF 2nd gen!');
});
EOF
cat > package.json <<EOF
{
  "name": "nodejs-http-function",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

deploy_with_retry() {
  local function_name=$1
  shift
  local attempts=0
  local max_attempts=5
  while [ $attempts -lt $max_attempts ]; do
    echo "${COLOR_YELLOW}${BOLD}Attempt $((attempts+1)): Deploying $function_name...${COLOR_RESET}"
    
    if gcloud functions deploy $function_name "$@"; then
      echo "${COLOR_GREEN}${BOLD}$function_name deployed successfully!${COLOR_RESET}"
      return 0
    else
      attempts=$((attempts+1))
      echo "${COLOR_RED}${BOLD}Deployment failed. Retrying in 30 seconds...${COLOR_RESET}"
      sleep 30
    fi
  done
  echo "${COLOR_RED}${BOLD}Failed to deploy $function_name after $max_attempts attempts${COLOR_RESET}"
  return 1
}

deploy_with_retry nodejs-http-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 1 \
  --allow-unauthenticated

# Test HTTP Function
echo
echo "${COLOR_BLUE}${BOLD}Testing HTTP Function...${COLOR_RESET}"
gcloud functions call nodejs-http-function --gen2 --region $REGION

# Deploy Storage Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying Storage Trigger Function...${COLOR_RESET}"
echo
mkdir ~/hello-storage && cd $_
cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js 22 in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF
cat > package.json <<EOF
{
  "name": "nodejs-storage-function",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
gsutil mb -l $REGION $BUCKET
deploy_with_retry nodejs-storage-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloStorage \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 1

# Test Storage Function
echo "Hello World" > random.txt
gsutil cp random.txt $BUCKET/random.txt
echo
echo "${COLOR_BLUE}${BOLD}Checking Storage Function Logs...${COLOR_RESET}"
gcloud functions logs read nodejs-storage-function \
  --region $REGION --gen2 --limit=100 --format "value(log)"

# Deploy VM Labeler Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying VM Labeler Function...${COLOR_RESET}"
echo
cd ~
git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git
cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs
deploy_with_retry gce-vm-labeler \
  --gen2 \
  --runtime nodejs22 \
  --entry-point labelVmCreation \
  --source . \
  --region $REGION \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location $REGION \
  --max-instances 1

# Create Test VM
echo
echo "${COLOR_BLUE}${BOLD}Creating Test VM Instance...${COLOR_RESET}"
gcloud compute instances create instance-1 --project=$PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-osconfig=TRUE,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud --reservation-affinity=any && printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml && gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE --project=$PROJECT_ID --zone=$ZONE --file=config.yaml && gcloud compute resource-policies create snapshot-schedule default-schedule-1 --project=$PROJECT_ID --region=$REGION --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --daily-schedule --start-time=08:00 && gcloud compute disks add-resource-policies instance-1 --project=$PROJECT_ID --zone=$ZONE --resource-policies=projects/$PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

# Describe VM
echo
echo "${COLOR_BLUE}${BOLD}Checking VM Details...${COLOR_RESET}"
gcloud compute instances describe instance-1 --zone $ZONE

# Deploy Colored Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying Colored Hello World Function...${COLOR_RESET}"
echo
mkdir ~/hello-world-colored && cd $_
touch requirements.txt
cat > main.py <<EOF
import os
color = os.environ.get('COLOR')
def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF
deploy_with_retry hello-world-colored \
  --gen2 \
  --runtime python39 \
  --entry-point hello_world \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars COLOR=yellow \
  --max-instances 1

# Deploy Slow Go Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying Slow Go Function...${COLOR_RESET}"
echo
mkdir ~/min-instances && cd $_
touch main.go
cat > main.go <<EOF
package p
import (
        "fmt"
        "net/http"
        "time"
)
func init() {
        time.Sleep(10 * time.Second)
}
func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF
echo "module example.com/mod" > go.mod
deploy_with_retry slow-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4

# Test Slow Function
echo
echo "${COLOR_BLUE}${BOLD}Testing Slow Function...${COLOR_RESET}"
gcloud functions call slow-function --gen2 --region $REGION

# Deploy as Cloud Run Service
echo
echo "${COLOR_BLUE}${BOLD}Deploying as Cloud Run Service...${COLOR_RESET}"

# Progress Check
function check_progress {
    while true; do
        echo
        echo "${COLOR_CYAN}${BOLD} ------ PLEASE COMPLETE MANUAL STEP AND VERIFY YOUR PROGRESS UP TO TASK 6 ${COLOR_RESET}"
        echo
        read -p "${COLOR_BLUE}${BOLD}Have you completed Task 6? (Y/N): ${COLOR_RESET}" user_input
        
        case $user_input in
            [Yy]*)
                echo
                echo "${COLOR_GREEN}${BOLD}Proceeding to next steps...${COLOR_RESET}"
                echo
                break
                ;;
            [Nn]*)
                echo
                echo "${COLOR_RED}${BOLD}Please complete Task 6 first${COLOR_RESET}"
                ;;
            *)
                echo
                echo "Invalid input. Please enter Y or N."
                ;;
        esac
    done
}
check_progress

# Cleanup
echo
echo "${COLOR_BLUE}${BOLD}Cleaning Up Previous Deployment...${COLOR_RESET}"
gcloud run services delete slow-function --region $REGION --quiet

# Deploy Concurrent Function
echo
echo "${COLOR_BLUE}${BOLD}Deploying Concurrent Function...${COLOR_RESET}"
deploy_with_retry slow-concurrent-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4

echo "${COLOR_CYAN}${BOLD} ------ PLEASE COMPLETE MANUAL STEP AND VERIFY YOUR PROGRESS OF TASK 7 ${COLOR_RESET}"

# Final message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
