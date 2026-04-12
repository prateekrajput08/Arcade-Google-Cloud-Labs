
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

# Ask the zone from user
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Please enter the Zone (e.g., us-central1-a):${RESET_FORMAT}"
read -p "> " ZONE

# Auto-fetch Region by removing the last hyphen and everything after it
REGION="${ZONE%-*}"

# Auto-fetch Project ID
PROJECT=$(gcloud config get-value project)
CLUSTER=gke-load-test
TARGET=${PROJECT}.appspot.com

echo -e "${CYAN_TEXT}Setting up configuration for Project: ${PROJECT}, Region: ${REGION}, Zone: ${ZONE}${RESET_FORMAT}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo -e "${GREEN_TEXT}Fetching sample code from Cloud Storage...${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp182/distributed-load-testing-using-kubernetes .

echo -e "${BLUE_TEXT}Navigating to directory and updating Python version...${RESET_FORMAT}"
cd distributed-load-testing-using-kubernetes/sample-webapp/
sed -i "s/python37/python312/g" app.yaml
cd ..

echo -e "${MAGENTA_TEXT}Building Docker image and submitting to Container Registry...${RESET_FORMAT}"
gcloud builds submit --tag gcr.io/$PROJECT/locust-tasks:latest docker-image/.

echo -e "${TEAL_TEXT}Initializing App Engine in region ${REGION}...${RESET_FORMAT}"
gcloud app create --region=$REGION || echo "App Engine might already be created."

gcloud projects add-iam-policy-binding qwiklabs-gcp-00-e744bd2c1012 \
  --member="serviceAccount:qwiklabs-gcp-00-e744bd2c1012@appspot.gserviceaccount.com" \
  --role="roles/storage.admin"

echo -e "${PURPLE_TEXT}Deploying web application to App Engine...${RESET_FORMAT}"
gcloud app deploy sample-webapp/app.yaml --quiet

echo -e "${GOLD_TEXT}Deploying Kubernetes cluster (this may take a few minutes)...${RESET_FORMAT}"
gcloud container clusters create $CLUSTER \
  --zone $ZONE \
  --num-nodes=5

echo -e "${LIME_TEXT}Fetching cluster credentials...${RESET_FORMAT}"
gcloud container clusters get-credentials $CLUSTER --zone $ZONE

echo -e "${MAROON_TEXT}Updating Kubernetes configuration files with TARGET_HOST and PROJECT_ID...${RESET_FORMAT}"
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-worker-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-worker-controller.yaml

echo -e "${NAVY_TEXT}Deploying Locust Master...${RESET_FORMAT}"
kubectl apply -f kubernetes-config/locust-master-controller.yaml

echo -e "${CYAN_TEXT}Deploying Locust Master Service...${RESET_FORMAT}"
kubectl apply -f kubernetes-config/locust-master-service.yaml

echo -e "${BLUE_TEXT}Deploying Locust Workers...${RESET_FORMAT}"
kubectl apply -f kubernetes-config/locust-worker-controller.yaml

echo -e "${GREEN_TEXT}Scaling Locust Workers to 20 replicas...${RESET_FORMAT}"
kubectl scale deployment/locust-worker --replicas=20

echo -e "${YELLOW_TEXT}Waiting for external IP assignment (this might take a minute)...${RESET_FORMAT}"
sleep 45

echo -e "${MAGENTA_TEXT}Fetching Locust Master External IP...${RESET_FORMAT}"
EXTERNAL_IP=$(kubectl get svc locust-master -o yaml | grep ip: | awk -F": " '{print $NF}')

echo -e "${GREEN_TEXT}${BOLD_TEXT}Lab deployment complete!${RESET_FORMAT}"
echo -e "${TEAL_TEXT}${BOLD_TEXT}Access your Locust Load Testing interface here:${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}http://$EXTERNAL_IP:8089${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
