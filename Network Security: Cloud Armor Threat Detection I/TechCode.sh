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

echo "${YELLOW_TEXT}${BOLD_TEXT}# Auto-fetch project, region, and zone${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -n "$ZONE" ]; then
  REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
fi

if [ -z "$REGION" ]; then
  REGION=$(gcloud compute regions list --format="value(name)" | head -n 1)
fi

if [ -z "$ZONE" ]; then
  ZONE=$(gcloud compute zones list --filter="region:$REGION" --format="value(name)" | head -n 1)
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: ${RESET_FORMAT}$PROJECT_ID"
echo "${GREEN_TEXT}${BOLD_TEXT}Region:     ${RESET_FORMAT}$REGION"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone:       ${RESET_FORMAT}$ZONE"

echo "${YELLOW_TEXT}${BOLD_TEXT}# Setting gcloud configurations${RESET_FORMAT}"
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo "${YELLOW_TEXT}${BOLD_TEXT}# Enabling required APIs${RESET_FORMAT}"
gcloud services enable compute.googleapis.com container.googleapis.com iap.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating VPC and subnet${RESET_FORMAT}"
gcloud compute networks create test-vpc --subnet-mode=custom
gcloud compute networks subnets create test-subnet-us --network=test-vpc --region="$REGION" --range=10.10.10.0/24

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating firewall rules${RESET_FORMAT}"
gcloud compute firewall-rules create allow-iap-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=test-vpc \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=iap-gce

gcloud compute firewall-rules create allow-http \
    --direction=INGRESS \
    --priority=1500 \
    --network=test-vpc \
    --allow=tcp:80,tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server,https-server

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating health check and backend service${RESET_FORMAT}"
gcloud compute health-checks create http health-check-http --port=80
gcloud compute backend-services create backend-service --health-checks=health-check-http --global

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating instance template for backend${RESET_FORMAT}"
gcloud compute instance-templates create backend-template \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --subnet=test-subnet-us \
  --tags=http-server,https-server,iap-gce \
  --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install -y apache2 php libapache2-mod-php
a2ensite default-ssl
a2enmod ssl
systemctl restart apache2
rm /var/www/html/index.html
echo "
<p>Query string: <!--?php echo \$_SERVER['QUERY_STRING']; ?--></p>" > /var/www/html/index.php
systemctl restart apache2'

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating Managed Instance Group${RESET_FORMAT}"
gcloud compute instance-groups managed create backend-mig \
  --base-instance-name=backend-vm \
  --size=2 \
  --template=backend-template \
  --zone="$ZONE"

gcloud compute backend-services add-backend backend-service \
  --instance-group=backend-mig \
  --instance-group-zone="$ZONE" \
  --global

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating URL map and HTTP proxy${RESET_FORMAT}"
gcloud compute url-maps create url-map --default-service=backend-service
gcloud compute target-http-proxies create http-proxy --url-map=url-map

echo "${YELLOW_TEXT}${BOLD_TEXT}# Allocating global IP${RESET_FORMAT}"
gcloud compute addresses create global-ip-address --global

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating global forwarding rule${RESET_FORMAT}"
gcloud compute forwarding-rules create http-forwarding-rule \
  --address=$(gcloud compute addresses describe global-ip-address --global --format='value(address)') \
  --global \
  --target-http-proxy=http-proxy \
  --ports=80

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating vulnerable test VM (no Cloud Armor)${RESET_FORMAT}"
gcloud compute instances create test-instance \
  --subnet=test-subnet-us \
  --machine-type=e2-medium \
  --tags=http-server,iap-gce \
  --zone="$ZONE" \
  --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install -y apache2 php libapache2-mod-php
a2ensite default-ssl
a2enmod ssl
systemctl restart apache2
rm /var/www/html/index.html
echo "
<p>Query string: <!--?php echo \$_SERVER['QUERY_STRING']; ?--></p>" > /var/www/html/index.php
systemctl restart apache2'

TEST_IP=$(gcloud compute instances describe test-instance --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "${GREEN_TEXT}${BOLD_TEXT}Unprotected Test Instance IP: $TEST_IP${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}# Creating Cloud Armor Security Policy${RESET_FORMAT}"
gcloud compute security-policies create "threat-policy" --description="Blocks traffic from potential threats"

echo "${YELLOW_TEXT}${BOLD_TEXT}# Adding rule to block XSS + SQLi${RESET_FORMAT}"
gcloud compute security-policies rules create 1 \
  --security-policy="threat-policy" \
  --description="Block XSS and SQLi attacks" \
  --expression="evaluatePreconfiguredExpr('xss-stable') || evaluatePreconfiguredExpr('sqli-stable')" \
  --action=deny-403

echo "${YELLOW_TEXT}${BOLD_TEXT}# Attaching Cloud Armor policy to backend service${RESET_FORMAT}"
gcloud compute backend-services update backend-service \
  --security-policy="threat-policy" \
  --global

BACKEND_IP=$(gcloud compute addresses describe global-ip-address --global --format='value(address)')
echo "${GREEN_TEXT}${BOLD_TEXT}Protected Backend IP: $BACKEND_IP${RESET_FORMAT}"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
