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

echo -e "${GREEN_TEXT}REGION_A=$REGION_A${RESET_FORMAT}"
echo -e "${GREEN_TEXT}REGION_B=$REGION_B${RESET_FORMAT}"

echo -e "\n${BLUE_TEXT}Creating MIG A...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-a \
    --template=template-alb-api \
    --size=1 \
    --region=$REGION_A

gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
    --named-ports=http80:80 \
    --region=$REGION_A

echo -e "${BLUE_TEXT}Creating MIG B...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-b \
    --template=template-alb-api \
    --size=1 \
    --region=$REGION_B

gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
    --named-ports=http80:80 \
    --region=$REGION_B

sleep 120

echo -e "${BLUE_TEXT}Creating Firewall Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
    --network=default \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=tag-alb-api

echo -e "${BLUE_TEXT}Creating Health Check...${RESET_FORMAT}"
gcloud compute health-checks create http http-check-alb \
    --global \
    --port=80

echo -e "${BLUE_TEXT}Creating Backend Service...${RESET_FORMAT}"
gcloud compute backend-services create service-alb-global \
    --global \
    --protocol=HTTP \
    --health-checks=http-check-alb \
    --port-name=http80

echo -e "${BLUE_TEXT}Adding Backends...${RESET_FORMAT}"
gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-a \
    --instance-group-region=$REGION_A \
    --balancing-mode=RATE \
    --max-rate-per-instance=1

gcloud compute backend-services add-backend service-alb-global \
    --global \
    --instance-group=mig-alb-api-b \
    --instance-group-region=$REGION_B \
    --balancing-mode=RATE \
    --max-rate-per-instance=1
    
echo "Waiting for backend initialization..."
sleep 60

echo -e "${BLUE_TEXT}Generating SSL Certificate...${RESET_FORMAT}"
openssl genrsa -out key.pem 2048

openssl req -new -x509 \
    -key key.pem \
    -out cert.pem \
    -days 1 \
    -subj "/CN=example.com"

gcloud compute ssl-certificates create cert-self-signed \
    --certificate=cert.pem \
    --private-key=key.pem \
    --global

echo -e "${BLUE_TEXT}Creating Global IP...${RESET_FORMAT}"
gcloud compute addresses create ip-alb-global \
    --global

echo -e "${BLUE_TEXT}Creating URL Map...${RESET_FORMAT}"
gcloud compute url-maps create url-map-alb \
    --default-service=service-alb-global

echo -e "${BLUE_TEXT}Creating HTTPS Proxy...${RESET_FORMAT}"
gcloud compute target-https-proxies create https-proxy-alb \
    --url-map=url-map-alb \
    --ssl-certificates=cert-self-signed

echo -e "${BLUE_TEXT}Creating Forwarding Rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create https-forwarding-rule \
    --global \
    --target-https-proxy=https-proxy-alb \
    --ports=443 \
    --address=ip-alb-global

echo -e "${MAGENTA_TEXT}Checking Backend Health...${RESET_FORMAT}"
echo "Waiting 120 seconds for health checks..."
sleep 120

gcloud compute backend-services get-health service-alb-global --global

echo -e "${MAGENTA_TEXT}Checking Port Name...${RESET_FORMAT}"
# Create SSH key automatically if needed
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q <<< y >/dev/null 2>&1 || true

LB_IP=$(gcloud compute addresses describe ip-alb-global \
  --global \
  --format="get(address)")

INSTANCE=$(gcloud compute instances list \
  --filter="name~'^mig-alb-api-a'" \
  --format="value(name)" | head -1)

ZONE=$(gcloud compute instances list \
  --filter="name=$INSTANCE" \
  --format="value(zone.basename())")

(
  sleep 10

  gcloud compute ssh "$INSTANCE" \
    --zone="$ZONE" \
    --quiet \
    --command="sudo systemctl stop nginx"

  echo ""
  echo "===== Nginx stopped on $INSTANCE ====="
) &

while true; do
  curl -k -s https://$LB_IP | grep "Hello from"
  sleep 0.5
done

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
