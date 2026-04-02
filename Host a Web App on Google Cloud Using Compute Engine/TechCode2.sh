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

#!/bin/bash

echo "${YELLOW_TEXT}${BOLD_TEXT}Starting${RESET_FORMAT} ${GREEN_TEXT}${BOLD_TEXT}Execution${RESET_FORMAT}"

export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

cd ~/monolith-to-microservices/react-app/

echo "${CYAN_TEXT}Fetching forwarding rules...${RESET_FORMAT}"
gcloud compute forwarding-rules list --global

export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')

echo "${CYAN_TEXT}Updating environment variables...${RESET_FORMAT}"
cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

cd ~

cd ~/monolith-to-microservices/react-app
echo "${CYAN_TEXT}Building React app...${RESET_FORMAT}"
npm install && npm run-script build

cd ~

echo "${CYAN_TEXT}Uploading updated code to Cloud Storage...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}Rolling update on frontend MIG...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable=100%

echo "${CYAN_TEXT}Configuring autoscaling...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas=2 \
  --target-load-balancing-utilization=0.60

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas=2 \
  --target-load-balancing-utilization=0.60

echo "${CYAN_TEXT}Enabling CDN...${RESET_FORMAT}"
gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn --global

echo "${CYAN_TEXT}Updating machine type...${RESET_FORMAT}"
gcloud compute instances set-machine-type frontend \
  --zone=$ZONE \
  --machine-type e2-small

echo "${CYAN_TEXT}Creating new instance template...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe-new \
    --region=$REGION \
    --source-instance=frontend \
    --source-instance-zone=$ZONE

echo "${CYAN_TEXT}Starting rolling update with new template...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone=$ZONE \
  --version template=fancy-fe-new

echo "${CYAN_TEXT}Updating React source file...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js

cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js

cd ~/monolith-to-microservices/react-app
echo "${CYAN_TEXT}Rebuilding React app...${RESET_FORMAT}"
npm install && npm run-script build

cd ~

echo "${CYAN_TEXT}Uploading final build...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${GREEN_TEXT}${BOLD_TEXT}Final rolling update...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%
  
# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
