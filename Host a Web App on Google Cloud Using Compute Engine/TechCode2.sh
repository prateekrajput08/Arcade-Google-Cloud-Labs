#!/bin/bash

# ==============================
# COLORS & FORMATTING
# ==============================
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

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        TECH & CODE - EXECUTION STARTED               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

# ==============================
# SET REGION & ZONE
# ==============================
export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# ==============================
# STEP 1: AUTOSCALING + CDN
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring Autoscaling and CDN...${RESET_FORMAT}"

gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute backend-services update fancy-fe-frontend \
  --enable-cdn --global

# ==============================
# STEP 2: UPDATE MACHINE TEMPLATE
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating Instance Template...${RESET_FORMAT}"

gcloud compute instances set-machine-type frontend \
  --zone=$ZONE \
  --machine-type e2-small

gcloud compute instance-templates create fancy-fe-new \
  --region=$REGION \
  --source-instance=frontend \
  --source-instance-zone=$ZONE

gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone=$ZONE \
  --version template=fancy-fe-new

echo "${BLUE_TEXT}Waiting 3 minutes for template rollout...${RESET_FORMAT}"
sleep 180

# ==============================
# STEP 3: UPDATE WEBSITE FILE
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating Website Content...${RESET_FORMAT}"

cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js

# ==============================
# STEP 4: SET ENV VARIABLES
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring Environment Variables...${RESET_FORMAT}"

EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule \
  --global --format='get(IPAddress)')

cat > ~/monolith-to-microservices/react-app/.env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

# ==============================
# STEP 5: BUILD & DEPLOY
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Building React App...${RESET_FORMAT}"

cd ~/monolith-to-microservices/react-app
npm install && npm run build

echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading to Cloud Storage...${RESET_FORMAT}"

cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

# ==============================
# STEP 6: ROLLING REPLACE
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Rolling Replace Instances...${RESET_FORMAT}"

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%

echo "${BLUE_TEXT}Waiting 3 minutes for instances to stabilize...${RESET_FORMAT}"
sleep 180

# ==============================
# STEP 7: HEALTH CHECK
# ==============================
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Backend Health...${RESET_FORMAT}"

gcloud compute backend-services get-health fancy-fe-frontend --global

# ==============================
# FINAL OUTPUT
# ==============================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}All tasks executed successfully.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Autoscaling, CDN, and deployment configured.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Website updated and running.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Load Balancer IP:${RESET_FORMAT} ${WHITE_TEXT}$EXTERNAL_IP_FANCY${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Like | Share | Subscribe${RESET_FORMAT}"
echo
