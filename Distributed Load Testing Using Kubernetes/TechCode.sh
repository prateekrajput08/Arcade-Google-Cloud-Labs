
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

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Configuration Setup${RESET_FORMAT}"
read -p "Enter your preferred ZONE (e.g., us-central1-a): " ZONE

if [ -z "$ZONE" ]; then
  echo "${RED_TEXT}Error: Zone cannot be empty${RESET_FORMAT}"
  exit 1
fi

# Set Project and Region
PROJECT=$(gcloud config get-value project)
REGION="${ZONE%-*}"
CLUSTER="gke-load-test"
TARGET="${PROJECT}.appspot.com"

echo "${GREEN_TEXT}✓ Configuration:${RESET_FORMAT}"
echo "  Project: ${PROJECT}"
echo "  Region: ${REGION}"
echo "  Zone: ${ZONE}"
echo

# Set GCP Configuration
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Setting Up GCP Environment${RESET_FORMAT}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo "${GREEN_TEXT}✓ GCP configuration updated${RESET_FORMAT}"
echo

# Download Resources
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Downloading Required Resources${RESET_FORMAT}"
if [ -d "distributed-load-testing-using-kubernetes" ]; then
  echo "${YELLOW_TEXT}✓ Directory already exists, skipping download${RESET_FORMAT}"
else
  gsutil -m cp -r gs://spls/gsp182/distributed-load-testing-using-kubernetes .
fi
echo "${GREEN_TEXT}✓ Resources downloaded${RESET_FORMAT}"
echo

# Configure Web Application
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4: Configuring Sample Web Application${RESET_FORMAT}"
cd distributed-load-testing-using-kubernetes/sample-webapp/
sed -i "s/python37/python312/g" app.yaml
cd ..
echo "${GREEN_TEXT}✓ Web application configured${RESET_FORMAT}"
echo

# Build Docker Image
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5: Building Locust Docker Image${RESET_FORMAT}"
gcloud builds submit --tag gcr.io/$PROJECT/locust-tasks:latest docker-image/.
echo "${GREEN_TEXT}✓ Docker image built and pushed${RESET_FORMAT}"
echo

# Deploy Web Application
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Deploying Web Application${RESET_FORMAT}"
gcloud app create --region=$REGION || echo "${YELLOW}App already exists, continuing...${RESET_FORMAT}"
gcloud app deploy sample-webapp/app.yaml --quiet
echo "${GREEN_TEXT}✓ Web application deployed${RESET_FORMAT}"
echo

# Create GKE Cluster
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 7: Creating GKE Cluster${RESET_FORMAT}"
gcloud container clusters create $CLUSTER \
  --zone $ZONE \
  --num-nodes=5 \
  --machine-type=e2-standard-4
echo "${GREEN_TEXT}✓ GKE cluster created${RESET_FORMAT}"
echo

# Configure Locust Files
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8: Configuring Load Testing Components${RESET_FORMAT}"
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-worker-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-worker-controller.yaml
echo "${GREEN_TEXT}✓ Configuration files updated${RESET_FORMAT}"
echo

# Deploy Locust Master
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 9: Deploying Locust Master${RESET_FORMAT}"
kubectl apply -f kubernetes-config/locust-master-controller.yaml
kubectl apply -f kubernetes-config/locust-master-service.yaml
echo "${GREEN_TEXT}✓ Locust master deployed${RESET_FORMAT}"
echo

# Get Master Service Details
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 10: Locust Master Service Details${RESET_FORMAT}"
kubectl get svc locust-master
echo
echo "${GREEN_TEXT}✓ You can access the Locust web interface at the EXTERNAL-IP above on port 8089${RESET_FORMAT}"
echo

# Deploy Locust Workers
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 11: Deploying Locust Workers${RESET_FORMAT}"
kubectl apply -f kubernetes-config/locust-worker-controller.yaml
echo "${GREEN_TEXT}✓ Initial workers deployed${RESET_FORMAT}"
echo

# Scale Workers
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 12: Scaling Workers${RESET_FORMAT}"
kubectl scale deployment/locust-worker --replicas=20
echo "${GREEN_TEXT}✓ Scaled to 20 workers${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
