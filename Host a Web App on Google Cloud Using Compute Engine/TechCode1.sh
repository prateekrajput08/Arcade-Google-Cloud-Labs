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

echo "${YELLOW_TEXT}${BOLD_TEXT}Starting Execution...${RESET_FORMAT}"

read -p "Enter Zone (e.g., us-central1-a): " ZONE
read -p "Enter Project ID: " DEVSHELL_PROJECT_ID

export REGION="${ZONE%-*}"

echo "Zone set to: $ZONE"
echo "Region set to: $REGION"
echo "Project ID: $DEVSHELL_PROJECT_ID"

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${CYAN_TEXT}Enabling required services...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com

echo "${CYAN_TEXT}Creating storage bucket...${RESET_FORMAT}"
gsutil mb gs://fancy-store-$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}Cloning repository...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

cd ~/monolith-to-microservices
./setup.sh

echo "${CYAN_TEXT}Installing Node.js...${RESET_FORMAT}"
nvm install --lts

cd monolith-to-microservices/

cat > startup-script.sh <<EOF_START
#!/bin/bash
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &

apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc

mkdir /opt/nodejs
curl https://nodejs.org/dist/v16.14.0/node-v16.14.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1

ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm

mkdir /fancy-store
gsutil -m cp -r gs://fancy-store-$DEVSHELL_PROJECT_ID/monolith-to-microservices/microservices/* /fancy-store/

cd /fancy-store/
npm install

useradd -m -d /home/nodeapp nodeapp
chown -R nodeapp:nodeapp /opt/app

cat >/etc/supervisor/conf.d/node-app.conf <<EOF_END
[program:nodeapp]
directory=/fancy-store
command=npm start
autostart=true
autorestart=true
user=nodeapp
environment=HOME="/home/nodeapp",USER="nodeapp",NODE_ENV="production"
stdout_logfile=syslog
stderr_logfile=syslog
EOF_END

supervisorctl reread
supervisorctl update
EOF_START

cd ~

echo "${CYAN_TEXT}Uploading startup script...${RESET_FORMAT}"
gsutil cp ~/monolith-to-microservices/startup-script.sh gs://fancy-store-$DEVSHELL_PROJECT_ID

rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}Creating backend instance...${RESET_FORMAT}"
gcloud compute instances create backend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=backend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

gcloud compute instances list

export EXTERNAL_IP_BACKEND=$(gcloud compute instances describe backend --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

cd monolith-to-microservices/react-app

cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products
EOF

echo "${CYAN_TEXT}Building frontend...${RESET_FORMAT}"
npm install && npm run-script build

cd ~

rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}Creating frontend instance...${RESET_FORMAT}"
gcloud compute instances create frontend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=frontend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

echo "${CYAN_TEXT}Configuring firewall rules...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-fe --allow tcp:8080 --target-tags=frontend
gcloud compute firewall-rules create fw-be --allow tcp:8081-8082 --target-tags=backend

gcloud compute instances list

echo "${YELLOW_TEXT}Stopping instances...${RESET_FORMAT}"
gcloud compute instances stop frontend --zone=$ZONE
gcloud compute instances stop backend --zone=$ZONE

echo "${CYAN_TEXT}Creating instance templates...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe --source-instance-zone=$ZONE --source-instance=frontend
gcloud compute instance-templates create fancy-be --source-instance-zone=$ZONE --source-instance=backend

gcloud compute instance-templates list

echo "${RED_TEXT}Deleting backend instance...${RESET_FORMAT}"
gcloud compute instances delete --quiet backend --zone=$ZONE

echo "${CYAN_TEXT}Creating managed instance groups...${RESET_FORMAT}"
gcloud compute instance-groups managed create fancy-fe-mig \
    --zone=$ZONE \
    --base-instance-name fancy-fe \
    --size 2 \
    --template fancy-fe

gcloud compute instance-groups managed create fancy-be-mig \
    --zone=$ZONE \
    --base-instance-name fancy-be \
    --size 2 \
    --template fancy-be

gcloud compute instance-groups set-named-ports fancy-fe-mig --zone=$ZONE --named-ports frontend:8080
gcloud compute instance-groups set-named-ports fancy-be-mig --zone=$ZONE --named-ports orders:8081,products:8082

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              CHECK THE TASK UPTO TASK 6               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Do not forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
