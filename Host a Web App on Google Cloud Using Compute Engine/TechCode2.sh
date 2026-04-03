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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE

gcloud config set compute/region $REGION

cd ~/monolith-to-microservices/react-app/

gcloud compute forwarding-rules list --global

export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')

cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products

REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

cd ~

cd ~/monolith-to-microservices/react-app
npm install && npm run-script build

cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable 100%

gcloud compute instance-groups managed set-autoscaling \
  fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute instance-groups managed set-autoscaling \
  fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn --global

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

cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js

cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js

cd ~/monolith-to-microservices/react-app
npm install && npm run-script build

cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%

FILE="TechCode1.sh"

if [ -f "$FILE" ]; then
rm "$FILE"
echo "${GREEN_TEXT}$FILE removed successfully.${RESET_FORMAT}"
else
echo "${RED_TEXT}$FILE not found.${RESET_FORMAT}"
fi

FILE="TechCode2.sh"

if [ -f "$FILE" ]; then
rm "$FILE"
echo "${GREEN_TEXT}$FILE removed successfully.${RESET_FORMAT}"
else
echo "${RED_TEXT}$FILE not found.${RESET_FORMAT}"
fi

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
