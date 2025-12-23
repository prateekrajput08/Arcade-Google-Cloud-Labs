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

# ========================= ZONE CONFIGURATION =========================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ ZONE CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE (e.g., us-central1-a): ${RESET_FORMAT}" ZONE

if [[ -z "$ZONE" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Zone cannot be empty.${RESET_FORMAT}"
  exit 1
fi

export ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "${CYAN_TEXT}Selected Zone: ${WHITE_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${CYAN_TEXT}Derived Region: ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

# ========================= WEB SERVER SETUP =========================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ WEB SERVER SETUP ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"
echo "${YELLOW_TEXT}Creating web server instances...${RESET_FORMAT}"

create_web_server() {
  local server_name=$1
  echo "${CYAN_TEXT}Creating instance ${BOLD_TEXT}$server_name${RESET_FORMAT}..."
  gcloud compute instances create $server_name \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: '"$server_name"'</h3>" | tee /var/www/html/index.html'
  echo "${GREEN_TEXT}Instance $server_name created successfully!${RESET_FORMAT}"
  echo
}

create_web_server "www1"
create_web_server "www2"
create_web_server "www3"

# ========================= FIREWALL SETUP =========================
echo "${GREEN_TEXT}${BOLD_TEXT}FIREWALL SETUP${RESET_FORMAT}"
echo "${YELLOW_TEXT}Configuring firewall rules...${RESET_FORMAT}"

gcloud compute firewall-rules create www-firewall-network-lb \
  --target-tags network-lb-tag \
  --allow tcp:80

echo "${GREEN_TEXT}Firewall rule created successfully!${RESET_FORMAT}"
echo

# ========================= NETWORK LOAD BALANCER =========================
echo "${GREEN_TEXT}${BOLD_TEXT}NETWORK LOAD BALANCER${RESET_FORMAT}"
echo "${YELLOW_TEXT}Setting up network load balancer...${RESET_FORMAT}"

echo "${CYAN_TEXT}Creating IP address...${RESET_FORMAT}"
gcloud compute addresses create network-lb-ip-1 --region $REGION

echo "${CYAN_TEXT}Creating health check...${RESET_FORMAT}"
gcloud compute http-health-checks create basic-check

echo "${CYAN_TEXT}Creating target pool...${RESET_FORMAT}"
gcloud compute target-pools create www-pool \
  --region $REGION \
  --http-health-check basic-check

echo "${CYAN_TEXT}Adding instances to pool...${RESET_FORMAT}"
gcloud compute target-pools add-instances www-pool \
  --instances www1,www2,www3

echo "${CYAN_TEXT}Creating forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create www-rule \
  --region $REGION \
  --ports 80 \
  --address network-lb-ip-1 \
  --target-pool www-pool

IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region $REGION --format="json" | jq -r .IPAddress)

echo "${GREEN_TEXT}Network load balancer configured successfully!${RESET_FORMAT}"
echo "${CYAN_TEXT}Load Balancer IP: ${WHITE_TEXT}${BOLD_TEXT}$IPADDRESS${RESET_FORMAT}"
echo

# ========================= HTTP LOAD BALANCER =========================
echo "${GREEN_TEXT}${BOLD_TEXT}HTTP LOAD BALANCER${RESET_FORMAT}"
echo "${YELLOW_TEXT}Setting up HTTP load balancer...${RESET_FORMAT}"

echo "${CYAN_TEXT}Creating instance template...${RESET_FORMAT}"
gcloud compute instance-templates create lb-backend-template \
  --region=$REGION \
  --network=default \
  --subnet=default \
  --tags=allow-health-check \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    echo "Page served from: $vm_hostname" | tee /var/www/html/index.html
    systemctl restart apache2'

echo "${GREEN_TEXT}Instance template created successfully!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}Creating managed instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed create lb-backend-group \
  --template=lb-backend-template \
  --size=2 \
  --zone=$ZONE

echo "${GREEN_TEXT}Managed instance group created successfully!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}Configuring health check firewall...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

echo "${GREEN_TEXT}Firewall rule created successfully!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}Creating global IP address...${RESET_FORMAT}"
gcloud compute addresses create lb-ipv4-1 --ip-version=IPV4 --global

echo "${CYAN_TEXT}Creating health check...${RESET_FORMAT}"
gcloud compute health-checks create http http-basic-check --port 80

echo "${CYAN_TEXT}Creating backend service...${RESET_FORMAT}"
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

echo "${CYAN_TEXT}Adding backend to service...${RESET_FORMAT}"
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

echo "${CYAN_TEXT}Creating URL map...${RESET_FORMAT}"
gcloud compute url-maps create web-map-http --default-service web-backend-service

echo "${CYAN_TEXT}Creating target HTTP proxy...${RESET_FORMAT}"
gcloud compute target-http-proxies create http-lb-proxy --url-map web-map-http

echo "${CYAN_TEXT}Creating forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create http-content-rule \
  --address=lb-ipv4-1 \
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80

echo "${GREEN_TEXT}HTTP load balancer configured successfully!${RESET_FORMAT}"
echo

# ========================= CLEANUP =========================
echo "${GREEN_TEXT}${BOLD_TEXT}CLEANUP${RESET_FORMAT}"
echo "${YELLOW_TEXT}Removing script for security...${RESET_FORMAT}"
rm -- "$0"
echo "${GREEN_TEXT}Script removed successfully!${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
