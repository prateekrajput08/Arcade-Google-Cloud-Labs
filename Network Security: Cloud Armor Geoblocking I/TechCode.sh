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

echo "${BLUE_TEXT}${BOLD_TEXT}Fetching project, zone and region...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "${GREEN_TEXT}${BOLD_TEXT}Project: ${RESET_FORMAT}$PROJECT_ID"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone: ${RESET_FORMAT}$ZONE"
echo "${GREEN_TEXT}${BOLD_TEXT}Region: ${RESET_FORMAT}$REGION"

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting configuration...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling services...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com container.googleapis.com iap.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating VPC and subnets...${RESET_FORMAT}"
gcloud compute networks create test-vpc --subnet-mode=custom

gcloud compute networks subnets create test-subnet-us \
  --network=test-vpc --region=$REGION --range=10.10.10.0/24

gcloud compute networks subnets create test-subnet-eu \
  --network=test-vpc --region=europe-west1 --range=10.20.20.0/24

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating firewall rules...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-iap-ssh \
  --direction=INGRESS --priority=1000 --network=test-vpc \
  --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20 \
  --target-tags=iap-gce

gcloud compute firewall-rules create allow-http \
  --direction=INGRESS --priority=1500 --network=test-vpc \
  --allow=tcp:80,tcp:443 --source-ranges=0.0.0.0/0 \
  --target-tags=http-server,https-server

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating backend health check and service...${RESET_FORMAT}"
gcloud compute health-checks create http health-check-http --port=80

gcloud compute backend-services create backend-service \
  --health-checks=health-check-http --global

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating instance template...${RESET_FORMAT}"
gcloud compute instance-templates create backend-template \
  --machine-type=e2-medium \
  --image-family=debian-11 --image-project=debian-cloud \
  --subnet=test-subnet-us \
  --tags=http-server,https-server,iap-gce \
  --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install -y apache2 php libapache2-mod-php
a2ensite default-ssl
a2enmod ssl
systemctl restart apache2
rm /var/www/html/index.html
echo "<p>Query string: <!--?php echo \$_SERVER['QUERY_STRING']; ?--></p>" > /var/www/html/index.php
systemctl restart apache2'

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating managed instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed create backend-mig \
  --base-instance-name=backend-vm --size=2 \
  --template=backend-template --zone=$ZONE

gcloud compute backend-services add-backend backend-service \
  --instance-group=backend-mig \
  --instance-group-zone=$ZONE --global

echo "${YELLOW_TEXT}${BOLD_TEXT}Updating health check...${RESET_FORMAT}"
gcloud compute health-checks create http http-health-check --request-path=/

gcloud compute backend-services update backend-service \
  --health-checks=http-health-check --global

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating frontend config...${RESET_FORMAT}"
gcloud compute url-maps create url-map --default-service=backend-service

gcloud compute target-http-proxies create http-proxy --url-map=url-map

gcloud compute addresses create global-ip-address --global

gcloud compute forwarding-rules create http-forwarding-rule \
  --address=$(gcloud compute addresses describe global-ip-address --global --format='value(address)') \
  --global --target-http-proxy=http-proxy --ports=80

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring Cloud Armor geoblocking...${RESET_FORMAT}"
gcloud compute security-policies create geoblocking-policy \
  --description="Blocks traffic from specific countries"

gcloud compute security-policies rules create 1000 \
  --security-policy=geoblocking-policy \
  --description="Allow traffic from US" \
  --expression="origin.region_code == 'US'" \
  --action=allow

gcloud compute security-policies rules create 10 \
  --security-policy=geoblocking-policy \
  --description="Deny traffic from Belgium" \
  --expression="origin.region_code == 'BE'" \
  --action=deny-403

gcloud compute backend-services update backend-service \
  --security-policy=geoblocking-policy --global

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating test instances...${RESET_FORMAT}"
gcloud compute instances create test-vm-us \
  --subnet=test-subnet-us --machine-type=e2-medium \
  --tags=iap-gce --zone=$ZONE

gcloud compute instances create test-vm-europe \
  --subnet=test-subnet-eu --machine-type=e2-medium \
  --tags=iap-gce --zone=europe-west1-b

BACKEND_IP=$(gcloud compute addresses describe global-ip-address --global --format='value(address)')
echo "${YELLOW_TEXT}${BOLD_TEXT}Backend IP: $BACKEND_IP${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}Run manually:${RESET_FORMAT}"
echo "gcloud compute ssh test-vm-us --zone=$ZONE --tunnel-through-iap --command \"curl -v $BACKEND_IP\""
echo "gcloud compute ssh test-vm-europe --zone=europe-west1-b --tunnel-through-iap --command \"curl -v $BACKEND_IP\""


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
