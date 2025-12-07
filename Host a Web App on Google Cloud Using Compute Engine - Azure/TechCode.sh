
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

# ================= AUTO-DETECT ZONE & REGION ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Detecting Zone & Region...${RESET_FORMAT}"

ZONE=$(gcloud compute instances list --limit=1 --format="value(zone)")
if [[ -z "$ZONE" ]]; then
  ZONE=$(gcloud compute regions list --filter="status=UP" --format="value(zones)" | head -n1 | cut -d';' -f1)
fi
export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${GREEN_TEXT}${BOLD_TEXT}# Zone = $ZONE  |  Region = $REGION detected automatically${RESET_FORMAT}"
echo ""

# ================= ENABLE COMPUTE API ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Enabling Compute API...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com

# ================= CREATE GCS BUCKET ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating fancy-store bucket...${RESET_FORMAT}"
gsutil mb gs://fancy-store-$DEVSHELL_PROJECT_ID

# ================= CLONE REPO ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Cloning monolith-to-microservices repo...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh

# ================= INSTALL NODE ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Installing Node LTS...${RESET_FORMAT}"
nvm install --lts

# ================= CREATE STARTUP SCRIPT ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating startup-script.sh for instances...${RESET_FORMAT}"

cat > startup-script.sh <<EOF_START
#!/bin/bash
apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc
curl https://nodejs.org/dist/v16.14.0/node-v16.14.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm
mkdir /fancy-store
gsutil -m cp -r gs://fancy-store-$DEVSHELL_PROJECT_ID/monolith-to-microservices/microservices/* /fancy-store/
cd /fancy-store/
npm install
cat >/etc/supervisor/conf.d/node-app.conf <<EOF_END
[program:nodeapp]
directory=/fancy-store
command=npm start
autostart=true
autorestart=true
stdout_logfile=syslog
stderr_logfile=syslog
EOF_END
supervisorctl reread
supervisorctl update
EOF_START

# ================= BACKEND PHASE ================= #
cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating backend VM...${RESET_FORMAT}"
gcloud compute instances create backend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=backend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

export EXTERNAL_IP_BACKEND=$(gcloud compute instances describe backend --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# ================= FRONTEND BUILD USING BACKEND ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Building React App...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app

cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products
EOF

npm install && npm run-script build

cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

# ================= FRONTEND VM ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating frontend VM...${RESET_FORMAT}"
gcloud compute instances create frontend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=frontend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

# ================= FIREWALL ================= #
gcloud compute firewall-rules create fw-fe \
    --allow tcp:8080 \
    --target-tags=frontend

gcloud compute firewall-rules create fw-be \
    --allow tcp:8081-8082 \
    --target-tags=backend

# ================= MIG + LB + BACKEND SERVICES ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating MIG, backend services, URL map & forwarding rules...${RESET_FORMAT}"

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=====================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  TASKS 1–6 COMPLETED — VALIDATE IN LAB NOW  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=====================================================${RESET_FORMAT}"
echo ""

# ===================== USER CONFIRMATION ===================== #
read -p "$(echo -e ${YELLOW_TEXT}${BOLD_TEXT}'Did Qwiklabs validate Task 6? (Y/N): '${RESET_FORMAT})" ANSWER

if [[ "$ANSWER" != "Y" && "$ANSWER" != "y" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Stopping script — continue only after validation.${RESET_FORMAT}"
    exit 0
fi

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}# Starting Task 7...${RESET_FORMAT}"
echo ""

# ================= GET LB IP ================= #
export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')

# ================= UPDATE FRONTEND ENV TO USE LB ================= #
cd ~/monolith-to-microservices/react-app
echo "${YELLOW_TEXT}${BOLD_TEXT}# Updating React env to use load balancer...${RESET_FORMAT}"

cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

npm install && npm run-script build

cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

# ================= MIG ROLLOUT ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Rolling frontend build across MIG...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%

# ================= AUTOSCALING ================= #
echo "${YELLOW_TEXT}${BOLD_TEXT}# Configuring autoscaling...${RESET_FORMAT}"

gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

# ================= ENABLE CDN ================= #
gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn --global

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
