
#!/bin/bash

# Define text colors and formatting
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
clear # Clear the terminal screen


# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Step 1: Authenticate and set up environment
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Setting up GCP environment${RESET_FORMAT}"
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# Step 2: Configure Kubernetes cluster
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Configuring Kubernetes cluster${RESET_FORMAT}"
gcloud container clusters get-credentials day2-ops --region $REGION

# Step 3: Deploy microservices
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Deploying microservices${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo || exit

kubectl apply -f release/kubernetes-manifests.yaml

echo "${GREEN_TEXT}Waiting for pods to initialize...${RESET_FORMAT}"
sleep 45
kubectl get pods

# Step 4: Get external IP
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4: Getting external IP${RESET_FORMAT}"
export EXTERNAL_IP=$(kubectl get service frontend-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo "Frontend External IP: ${BLUE}${BOLD}$EXTERNAL_IP${NC}"

# Step 5: Test the deployment
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5: Testing deployment${RESET_FORMAT}"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "http://${EXTERNAL_IP}")
echo "HTTP Status Code: ${BLUE}${BOLD}$HTTP_STATUS${NC}"

# Step 6: Configure logging
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Configuring logging${RESET_FORMAT}"
gcloud logging buckets update _Default --project=$PROJECT_ID --location=global --enable-analytics

gcloud logging sinks create day2ops-sink \
    logging.googleapis.com/projects/$PROJECT_ID/locations/global/buckets/day2ops-log \
    --log-filter='resource.type="k8s_container"' \
    --include-children --format='json'

# Final output
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Deployment completed successfully!${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Next steps:${NC}"
echo "1. Access the application at: ${BLUE_TEXT}http://${EXTERNAL_IP}${RESET_FORMAT}"
echo "2. View logs in the console: ${BLUE_TEXT}https://console.cloud.google.com/logs/storage/bucket?project=${PROJECT_ID}${NC}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
