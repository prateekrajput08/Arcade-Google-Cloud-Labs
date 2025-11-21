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

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Fetch zone and region with fallback to prompt
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Detecting default zone and region... ${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)


if [ -z "$ZONE" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Could not detect default zone.${RESET_FORMAT}"
    echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter your preferred zone (e.g., us-central1-a):${RESET_FORMAT}"
    read -p "Zone: " ZONE
    REGION=${ZONE%-*}
else
    echo "${YELLOW_TEXT}${BOLD_TEXT}Detected Zone: $ZONE${RESET_FORMAT}"
    echo "${YELLOW_TEXT}${BOLD_TEXT}Detected Region: $REGION${RESET_FORMAT}"
fi
echo ""

# Create web instances
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating web instances (web1, web2, web3)...${RESET_FORMAT}"
for i in {1..3}; do
    echo -n "Creating web$i... "
    gcloud compute instances create web$i \
        --zone=$ZONE \
        --machine-type=e2-small \
        --tags=network-lb-tag \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
        apt-get update
        apt-get install apache2 -y
        service apache2 restart
        echo "<h3>Web Server: web'$i'</h3>" | tee /var/www/html/index.html' > /dev/null 2>&1 &
     
    echo "Done"
done
echo ""

# Create firewall rule
echo -n "Creating firewall rule for network load balancer... "
gcloud compute firewall-rules create www-firewall-network-lb \
    --allow tcp:80 \
    --target-tags network-lb-tag > /dev/null 2>&1 &
 
echo "Done"
echo ""

# Network Load Balancer Setup
echo "Setting up Network Load Balancer..."
echo -n "Creating static IP address... "
gcloud compute addresses create network-lb-ip-1 \
    --region=$REGION > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating health check... "
gcloud compute http-health-checks create basic-check > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating target pool... "
gcloud compute target-pools create www-pool \
    --region=$REGION \
    --http-health-check basic-check > /dev/null 2>&1 &
 
echo "Done"

echo -n "Adding instances to target pool... "
gcloud compute target-pools add-instances www-pool \
    --instances web1,web2,web3 \
    --zone=$ZONE > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating forwarding rule... "
gcloud compute forwarding-rules create www-rule \
    --region=$REGION \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool > /dev/null 2>&1 &
 
echo "Done"

IPADDRESS=$(gcloud compute forwarding-rules describe www-rule \
    --region=$REGION \
    --format="json" | jq -r .IPAddress)
echo "Network Load Balancer IP: $IPADDRESS"
echo ""

# HTTP Load Balancer Setup
echo "Setting up HTTP Load Balancer..."
echo -n "Creating instance template... "
gcloud compute instance-templates create lb-backend-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-12 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2' > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating managed instance group... "
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template \
   --size=2 \
   --zone=$ZONE > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating health check firewall rule... "
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80 > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating global IPv4 address... "
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global > /dev/null 2>&1 &
 
echo "Done"

LB_IP=$(gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global)
echo "HTTP Load Balancer IP: $LB_IP"

echo -n "Creating HTTP health check... "
gcloud compute health-checks create http http-basic-check \
  --port 80 > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating backend service... "
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global > /dev/null 2>&1 &
 
echo "Done"

echo -n "Adding backend to service... "
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating URL map... "
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating target HTTP proxy... "
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http > /dev/null 2>&1 &
 
echo "Done"

echo -n "Creating forwarding rule... "
gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1 \
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80 > /dev/null 2>&1 &
 
echo "Done"
echo ""


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
