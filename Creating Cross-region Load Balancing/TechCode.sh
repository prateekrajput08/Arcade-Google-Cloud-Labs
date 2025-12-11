#!/bin/bash  

# ---------------------------------------------
# COLOR DEFINITIONS
# ---------------------------------------------

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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the second zone (Example: us-central1-b):${RESET_FORMAT}"
read ZONE_2
export ZONE_2

export ZONE_1=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

gcloud compute instances create www-1 \
     --image-family debian-11 \
     --image-project debian-cloud \
     --zone $ZONE_1 \
     --tags http-tag \
     --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo 'Server 1' > /var/www/html/index.html"

gcloud compute instances create www-2 \
     --image-family debian-11 \
     --image-project debian-cloud \
     --zone $ZONE_1 \
     --tags http-tag \
     --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo 'Server 2' > /var/www/html/index.html"

gcloud compute instances create www-3 \
     --image-family debian-11 \
     --image-project debian-cloud \
     --zone $ZONE_2 \
     --tags http-tag \
     --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo 'Server 3' > /var/www/html/index.html"

gcloud compute instances create www-4 \
     --image-family debian-11 \
     --image-project debian-cloud \
     --zone $ZONE_2 \
     --tags http-tag \
     --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo 'Server 4' > /var/www/html/index.html"

gcloud compute firewall-rules create www-firewall \
     --target-tags http-tag --allow tcp:80

gcloud compute instances list

gcloud compute addresses create lb-ip-cr \
     --ip-version=IPV4 \
     --global

gcloud compute instance-groups unmanaged create $REGION_1-resources-w --zone $ZONE_1
gcloud compute instance-groups unmanaged create $REGION_2-resources-w --zone $ZONE_2

gcloud compute instance-groups unmanaged add-instances $REGION_1-resources-w \
     --instances www-1,www-2 \
     --zone $ZONE_1

gcloud compute instance-groups unmanaged add-instances $REGION_2-resources-w \
     --instances www-3,www-4 \
     --zone $ZONE_2

gcloud compute health-checks create http http-basic-check

gcloud compute instance-groups unmanaged set-named-ports $REGION_1-resources-w \
     --named-ports http:80 \
     --zone $ZONE_1

gcloud compute instance-groups unmanaged set-named-ports $REGION_2-resources-w \
     --named-ports http:80 \
     --zone $ZONE_2

gcloud compute backend-services create web-map-backend-service \
     --protocol HTTP \
     --health-checks http-basic-check \
     --global

gcloud compute backend-services add-backend web-map-backend-service \
     --balancing-mode UTILIZATION \
     --max-utilization 0.8 \
     --capacity-scaler 1 \
     --instance-group $REGION_1-resources-w \
     --instance-group-zone $ZONE_1 \
     --global

gcloud compute backend-services add-backend web-map-backend-service \
     --balancing-mode UTILIZATION \
     --max-utilization 0.8 \
     --capacity-scaler 1 \
     --instance-group $REGION_2-resources-w \
     --instance-group-zone $ZONE_2 \
     --global

gcloud compute url-maps create web-map \
     --default-service web-map-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
     --url-map web-map

LB_IP_ADDRESS=$(gcloud compute addresses list --format="get(ADDRESS)")

gcloud compute forwarding-rules create http-cr-rule \
     --address $LB_IP_ADDRESS \
     --global \
     --target-http-proxy http-lb-proxy \
     --ports 80

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe!${RESET_FORMAT}"
