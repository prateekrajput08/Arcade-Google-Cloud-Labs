#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
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

echo "${CYAN_TEXT}Enter compute zone${RESET_FORMAT}"
read -p "Zone (e.g. us-central1-a): " ZONE

echo "${GREEN_TEXT}Setting compute zone...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${BLUE_TEXT}Cloning repository...${RESET_FORMAT}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

echo "${BLUE_TEXT}Entering project directory...${RESET_FORMAT}"
cd monolith-to-microservices

echo "${BLUE_TEXT}Running setup script...${RESET_FORMAT}"
./setup.sh

echo "${YELLOW_TEXT}Enabling Kubernetes Engine API...${RESET_FORMAT}"
gcloud services enable container.googleapis.com

echo "${YELLOW_TEXT}Creating GKE cluster...${RESET_FORMAT}"
gcloud container clusters create fancy-cluster \
  --num-nodes 3 \
  --machine-type=e2-standard-4

echo "${MAGENTA_TEXT}Deploying monolith application...${RESET_FORMAT}"
./deploy-monolith.sh

wait_for_ip() {
  SERVICE_NAME=$1
  echo "${TEAL}Waiting for external IP for $SERVICE_NAME...${RESET_FORMAT}"

  while true; do
    IP=$(kubectl get svc $SERVICE_NAME \
      --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

    if [[ -n "$IP" ]]; then
      echo "${GREEN_TEXT}$SERVICE_NAME IP: $IP${RESET_FORMAT}"
      break
    fi

    echo "${YELLOW_TEXT}Still waiting...${RESET_FORMAT}"
    sleep 10
  done
}

echo "${CYAN_TEXT}Building Orders microservice...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/orders

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/orders:1.0.0 .

echo "${CYAN_TEXT}Deploying Orders...${RESET_FORMAT}"
kubectl create deployment orders \
  --image=gcr.io/$GOOGLE_CLOUD_PROJECT/orders:1.0.0

echo "${CYAN_TEXT}Exposing Orders service...${RESET_FORMAT}"
kubectl expose deployment orders \
  --type=LoadBalancer \
  --port 80 \
  --target-port 8081

wait_for_ip orders
ORDERS_IP=$(kubectl get svc orders \
  --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "${BLUE_TEXT}Updating monolith config for Orders...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
sed -i "s|REACT_APP_ORDERS_URL=.*|REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders|" .env.monolith

echo "${BLUE_TEXT}Rebuilding monolith...${RESET_FORMAT}"
npm run build:monolith

cd ~/monolith-to-microservices/monolith
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/monolith:2.0.0 .

echo "${GREEN_TEXT}Updating monolith deployment...${RESET_FORMAT}"
kubectl set image deployment/monolith \
  monolith=gcr.io/$GOOGLE_CLOUD_PROJECT/monolith:2.0.0

echo "${CYAN_TEXT}Building Products microservice...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/products

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/products:1.0.0 .

echo "${CYAN_TEXT}Deploying Products...${RESET_FORMAT}"
kubectl create deployment products \
  --image=gcr.io/$GOOGLE_CLOUD_PROJECT/products:1.0.0

echo "${CYAN_TEXT}Exposing Products service...${RESET_FORMAT}"
kubectl expose deployment products \
  --type=LoadBalancer \
  --port 80 \
  --target-port 8082

wait_for_ip products
PRODUCTS_IP=$(kubectl get svc products \
  --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "${BLUE_TEXT}Updating monolith config for Products...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
sed -i "s|REACT_APP_PRODUCTS_URL=.*|REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP/api/products|" .env.monolith

echo "${BLUE_TEXT}Rebuilding monolith...${RESET_FORMAT}"
npm run build:monolith

cd ~/monolith-to-microservices/monolith
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/monolith:3.0.0 .

echo "${GREEN_TEXT}Updating monolith deployment...${RESET_FORMAT}"
kubectl set image deployment/monolith \
  monolith=gcr.io/$GOOGLE_CLOUD_PROJECT/monolith:3.0.0

echo "${CYAN_TEXT}Preparing frontend build...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
cp .env.monolith .env
npm run build

echo "${CYAN_TEXT}Building frontend container...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/frontend

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend:1.0.0 .

echo "${CYAN_TEXT}Deploying frontend...${RESET_FORMAT}"
kubectl create deployment frontend \
  --image=gcr.io/$GOOGLE_CLOUD_PROJECT/frontend:1.0.0

echo "${CYAN_TEXT}Exposing frontend service...${RESET_FORMAT}"
kubectl expose deployment frontend \
  --type=LoadBalancer \
  --port 80 \
  --target-port 8080

wait_for_ip frontend

echo "${RED_TEXT}Deleting monolith...${RESET_FORMAT}"
kubectl delete deployment monolith
kubectl delete service monolith

echo "${GREEN_TEXT}Final Services:${RESET_FORMAT}"
kubectl get services

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
