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

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE  -  EXECUTION STARTED...              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}      https://www.youtube.com/@TechCode9 ${RESET_FORMAT}"
echo

# ----------- Detect Project, Zone, Region -------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Detecting Zone & Region...${RESET_FORMAT}"

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -z "$ZONE" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Default zone not found. Enter zone (us-east1-d):${RESET_FORMAT}"
    read -p "Zone: " ZONE
fi

REGION="${ZONE%-*}"
PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN_TEXT}${BOLD_TEXT}Using Zone: $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Using Region: $REGION${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}Tech & Code - https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo

# ---------------- Task 1: Create Web Servers -------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating web1, web2, web3...${RESET_FORMAT}"

for i in 1 2 3; do
    echo "${BLUE_TEXT}Creating web$i ...${RESET_FORMAT}"
    gcloud compute instances create web$i \
        --zone=$ZONE \
        --machine-type=e2-small \
        --tags=network-lb-tag \
        --network=default \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --metadata=startup-script="#!/bin/bash
            apt-get update
            apt-get install apache2 -y
            service apache2 restart
            echo \"<h3>Web Server: web$i</h3>\" > /var/www/html/index.html"
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Web servers created successfully.${RESET_FORMAT}"
echo

# Firewall for Network LB
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating firewall rule www-firewall-network-lb...${RESET_FORMAT}"

gcloud compute firewall-rules create www-firewall-network-lb \
    --allow tcp:80 \
    --network=default \
    --target-tags=network-lb-tag

echo "${GREEN_TEXT}${BOLD_TEXT}Firewall rule created.${RESET_FORMAT}"
echo

# ---------------- Task 2: Network Load Balancer -------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring Network Load Balancer...${RESET_FORMAT}"

gcloud compute addresses create network-lb-ip-1 \
    --region=$REGION

gcloud compute http-health-checks create basic-check

gcloud compute target-pools create www-pool \
    --region=$REGION \
    --http-health-check basic-check

gcloud compute target-pools add-instances www-pool \
    --instances=web1,web2,web3 \
    --zone=$ZONE

gcloud compute forwarding-rules create www-rule \
    --region=$REGION \
    --ports=80 \
    --address=network-lb-ip-1 \
    --target-pool=www-pool

NLB_IP=$(gcloud compute forwarding-rules describe www-rule \
    --region=$REGION --format="get(IPAddress)")

echo "${GREEN_TEXT}${BOLD_TEXT}Network Load Balancer created. IP: $NLB_IP ${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}Tech & Code - https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo

# ---------------- Task 3: HTTP Load Balancer -------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up HTTP Load Balancer...${RESET_FORMAT}"

# Instance Template
gcloud compute instance-templates create lb-backend-template \
  --machine-type=e2-medium \
  --tags=allow-health-check \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script="#!/bin/bash
       apt-get update
       apt-get install apache2 -y
       vm=\$(hostname)
       echo \"Page served from: \$vm\" > /var/www/html/index.html
       systemctl restart apache2"

# Managed Instance Group
gcloud compute instance-groups managed create lb-backend-group \
  --template=lb-backend-template \
  --size=2 \
  --zone=$ZONE

# Firewall for HC
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Global IP
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

LB_IP=$(gcloud compute addresses describe lb-ipv4-1 \
  --global --format="get(address)")

# Health check
gcloud compute health-checks create http http-basic-check --port=80

# Backend service
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

# URL Map & Proxy
gcloud compute url-maps create web-map-http \
  --default-service web-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
  --url-map=web-map-http

# Forwarding rule
gcloud compute forwarding-rules create http-content-rule \
  --address=lb-ipv4-1 \
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80

echo
echo "${GREEN_TEXT}${BOLD_TEXT}HTTP Load Balancer created successfully.${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}HTTP LB IP: $LB_IP${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe!${RESET_FORMAT}"
