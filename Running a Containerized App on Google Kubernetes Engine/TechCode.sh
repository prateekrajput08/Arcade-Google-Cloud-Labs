
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

ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

# DEFAULT if zone not set
if [ -z "$ZONE" ] || [ "$ZONE" == "(unset)" ]; then
    ZONE="us-central1-a"
    echo "${YELLOW_TEXT}Zone not set, using default: $ZONE${RESET_FORMAT}"
fi

echo "${BLUE_TEXT}Setting Compute Zone...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${GREEN_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services enable container.googleapis.com compute.googleapis.com

echo "${GREEN_TEXT}Creating GKE Cluster...${RESET_FORMAT}"
gcloud container clusters create hello-world --num-nodes=3

echo "${TEAL_TEXT}Fetching Project ID...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)

echo "${BLUE_TEXT}Cloning Repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/kubernetes-engine-samples
cd kubernetes-engine-samples/quickstarts/hello-app

echo "${MAGENTA_TEXT}Building Docker Image...${RESET_FORMAT}"
docker build -t gcr.io/$PROJECT_ID/hello-app:1.0 .

echo "${NAVY_TEXT}Pushing Image to Artifact Registry...${RESET_FORMAT}"
gcloud auth configure-docker
docker push gcr.io/$PROJECT_ID/hello-app:1.0

echo "${GREEN_TEXT}Creating Deployment...${RESET_FORMAT}"
kubectl create deployment hello-app --image=gcr.io/$PROJECT_ID/hello-app:1.0

echo "${GOLD_TEXT}Exposing Service...${RESET_FORMAT}"
kubectl expose deployment hello-app --name=hello-app --type=LoadBalancer --port=80 --target-port=8080

echo "${PURPLE_TEXT}Waiting for External IP...${RESET_FORMAT}"
sleep 25
kubectl get svc hello-app

echo "${LIME_TEXT}If External IP is <pending>, run: kubectl get svc hello-app${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
