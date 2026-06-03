#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
clear

check_status() {
    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ FAILED: $1"
        exit 1
    else
        echo "✔ $1"
    fi
}

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ─── AUTO-FETCH PROJECT & REGIONS ───────────────────────────────────────────
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

echo ""
read -p "Region A: " REGION_A
read -p "Region B: " REGION_B
SUBNET_INTERNAL=$(gcloud compute networks subnets list \
    --filter="network=lb-network AND region=$REGION_B" \
    --format="value(name)" | grep -v proxy | head -1)

echo "Internal subnet: $SUBNET_INTERNAL"

if [[ -z "$REGION_A" || -z "$REGION_B" ]]; then
    echo "Region A and Region B are required."
    exit 1
fi

export REGION_A REGION_B

echo "${GREEN_TEXT}  Project ID        : ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}  Region A          : ${WHITE_TEXT}$REGION_A${RESET_FORMAT}"
echo "${GREEN_TEXT}  Region B          : ${WHITE_TEXT}$REGION_B${RESET_FORMAT}"
echo "${GREEN_TEXT}  Internal subnet   : ${WHITE_TEXT}$SUBNET_INTERNAL${RESET_FORMAT}"
echo ""

# ─── TASK 1: REGIONAL INTERNAL PROXY NLB ────────────────────────────────────
# 1a. Create regional MIG in Region B
echo "${YELLOW_TEXT}[1/14] Creating MIG: mig-proxy-internal in $REGION_B ...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-proxy-internal \
  --template=template-proxy-internal \
  --size=2 \
  --region=$REGION_B \
  --quiet

check_status "mig-proxy-internal created"

gcloud compute instance-groups managed set-named-ports mig-proxy-internal \
  --named-ports=tcp80:80 \
  --region=$REGION_B \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ MIG mig-proxy-internal created${RESET_FORMAT}"
echo ""

# 1b. Firewall: health check → tag-proxy-internal
echo "${YELLOW_TEXT}[2/14] Creating firewall rule: allow health check for proxy-internal...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80 \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Health check firewall rule created${RESET_FORMAT}"
echo ""

# 1c. Firewall: proxy-only subnet → tag-proxy-internal
echo "${YELLOW_TEXT}[3/14] Creating firewall rule: allow proxy-only subnet for proxy-internal...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-proxy-only-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80 \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Proxy-only subnet firewall rule created${RESET_FORMAT}"
echo ""

# 1d. Reserve internal static IP
echo "${YELLOW_TEXT}[4/14] Reserving internal static IP: ip-internal-proxy in $REGION_B ...${RESET_FORMAT}"
echo ""
echo "Available subnets:"
gcloud compute networks subnets list \
    --filter="network:lb-network"

read -p "Enter internal subnet name: " SUBNET_INTERNAL

gcloud compute addresses create ip-internal-proxy \
  --region=$REGION_B \
  --subnet=$SUBNET_INTERNAL \
  --purpose=SHARED_LOADBALANCER_VIP \
  --quiet 2>&1

INTERNAL_IP=$(gcloud compute addresses describe ip-internal-proxy \
  --region=$REGION_B --format="value(address)")

echo "${GREEN_TEXT}  ✔ Internal IP reserved: $INTERNAL_IP${RESET_FORMAT}"
echo ""

# 1e. Health check for internal NLB
echo "${YELLOW_TEXT}[5/14] Creating health check for internal NLB...${RESET_FORMAT}"
gcloud compute health-checks create tcp hc-tcp-internal-proxy \
  --region=$REGION_B \
  --port=80 \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Health check created${RESET_FORMAT}"
echo ""

# 1f. Backend service
echo "${YELLOW_TEXT}[6/14] Creating backend service for internal proxy NLB...${RESET_FORMAT}"
gcloud compute backend-services create service-internal-proxy \
  --region=$REGION_B \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=TCP \
  --health-checks=hc-tcp-internal-proxy \
  --health-checks-region=$REGION_B \
  --quiet

check_status "service-internal-proxy created"

gcloud compute backend-services add-backend service-internal-proxy \
  --region=$REGION_B \
  --instance-group=mig-proxy-internal \
  --instance-group-region=$REGION_B \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Backend service created and backend added${RESET_FORMAT}"
echo ""

# 1g. Target TCP proxy
echo "${YELLOW_TEXT}[7/14] Creating target TCP proxy...${RESET_FORMAT}"
gcloud compute target-tcp-proxies create proxy-internal-proxy \
  --backend-service=service-internal-proxy \
  --backend-service-region=$REGION_B \
  --region=$REGION_B \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Target TCP proxy created${RESET_FORMAT}"
echo ""

# 1h. Forwarding rule on port 110
echo "${YELLOW_TEXT}[8/14] Creating forwarding rule: rule-internal-proxy on port 110...${RESET_FORMAT}"
gcloud compute forwarding-rules create rule-internal-proxy \
  --region=$REGION_B \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network=lb-network \
  --subnet=$SUBNET_INTERNAL \
  --address=ip-internal-proxy \
  --target-tcp-proxy=proxy-internal-proxy \
  --target-tcp-proxy-region=$REGION_B \
  --ports=110 \
  --quiet

check_status "rule-internal-proxy created"

echo "${GREEN_TEXT}  ✔ Forwarding rule rule-internal-proxy created on port 110${RESET_FORMAT}"
echo ""

# 1i. Client VM for validation
echo "${YELLOW_TEXT}[9/14] Creating client VM: vm-client-internal in $REGION_B ...${RESET_FORMAT}"
echo ""
echo "Available zones in $REGION_B:"
gcloud compute zones list --filter="region:$REGION_B"

read -p "Enter zone for client VM: " ZONE_B

gcloud compute instances create vm-client-internal \
  --zone=$ZONE_B \
  --network=lb-network \
  --subnet=$SUBNET_INTERNAL \
  --tags=allow-ssh \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ VM vm-client-internal created in zone $ZONE_B${RESET_FORMAT}"
echo ""

# ─── TASK 2: GLOBAL EXTERNAL ALB ────────────────────────────────────────────

# 2a. MIG in Region A
echo "${YELLOW_TEXT}[10/14] Creating MIG: mig-alb-api-a in $REGION_A ...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-a \
  --template=template-alb-api \
  --size=2 \
  --region=$REGION_A \
  --quiet

check_status "mig-alb-api-a created"

gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
  --named-ports=http80:80 \
  --region=$REGION_A \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ MIG mig-alb-api-a created in $REGION_A${RESET_FORMAT}"
echo ""

# 2b. MIG in Region B
echo "${YELLOW_TEXT}[11/14] Creating MIG: mig-alb-api-b in $REGION_B ...${RESET_FORMAT}"
gcloud compute instance-groups managed create mig-alb-api-b \
  --template=template-alb-api \
  --size=2 \
  --region=$REGION_B \
  --quiet

check_status "mig-alb-api-b created"

gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
  --named-ports=http80:80 \
  --region=$REGION_B \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ MIG mig-alb-api-b created in $REGION_B${RESET_FORMAT}"
echo ""

# 2c. Global HTTP health check
echo "${YELLOW_TEXT}[12/14] Creating global HTTP health check: http-check-alb on port 80...${RESET_FORMAT}"
gcloud compute health-checks create http http-check-alb \
  --port=80 \
  --global \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Health check http-check-alb created${RESET_FORMAT}"
echo ""

# 2d. Global backend service
echo "${YELLOW_TEXT}[13/14] Creating global backend service: service-alb-global...${RESET_FORMAT}"
gcloud compute backend-services create service-alb-global \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --health-checks=http-check-alb \
  --global-health-checks \
  --quiet

check_status "service-alb-global created"

# Add Region A backend — Rate mode, max-rate-per-instance RPS=1
gcloud compute backend-services add-backend service-alb-global \
  --global \
  --instance-group=mig-alb-api-a \
  --instance-group-region=$REGION_A \
  --balancing-mode=RATE \
  --max-rate-per-instance=1 \
  --quiet 2>&1

# Add Region B backend — Rate mode, max-rate-per-instance RPS=1
gcloud compute backend-services add-backend service-alb-global \
  --global \
  --instance-group=mig-alb-api-b \
  --instance-group-region=$REGION_B \
  --balancing-mode=RATE \
  --max-rate-per-instance=1 \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ Backend service service-alb-global created with both backends${RESET_FORMAT}"
echo ""

# 2e. SSL certificate
echo "${YELLOW_TEXT}[14/14] Creating self-signed SSL cert and configuring ALB frontend...${RESET_FORMAT}"
openssl genrsa -out /tmp/key.pem 2048 2>/dev/null
openssl req -new -x509 -key /tmp/key.pem -out /tmp/cert.pem -days 1 -subj "/CN=example.com" 2>/dev/null

gcloud compute ssl-certificates create cert-self-signed \
  --certificate=/tmp/cert.pem \
  --private-key=/tmp/key.pem \
  --global \
  --quiet 2>&1

echo "${GREEN_TEXT}  ✔ SSL certificate cert-self-signed created${RESET_FORMAT}"
echo ""

# 2f. Reserve global external IP
echo "${YELLOW_TEXT}    Reserving global external IP: ip-alb-global...${RESET_FORMAT}"
gcloud compute addresses create ip-alb-global \
  --ip-version=IPV4 \
  --global \
  --quiet 2>&1

ALB_IP=$(gcloud compute addresses describe ip-alb-global \
  --global --format="value(address)")

echo "${GREEN_TEXT}  ✔ Global IP reserved: $ALB_IP${RESET_FORMAT}"
echo ""

# 2g. URL map
gcloud compute url-maps create urlmap-alb-global \
  --default-service=service-alb-global \
  --global \
  --quiet 2>&1

# 2h. Target HTTPS proxy
gcloud compute target-https-proxies create proxy-alb-global \
  --url-map=urlmap-alb-global \
  --ssl-certificates=cert-self-signed \
  --global \
  --quiet 2>&1

# 2i. Forwarding rule HTTPS 443
gcloud compute forwarding-rules create rule-alb-global \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --address=ip-alb-global \
  --target-https-proxy=proxy-alb-global \
  --ports=443 \
  --quiet

check_status "rule-alb-global created"

echo "${GREEN_TEXT}  ✔ HTTPS frontend configured on port 443${RESET_FORMAT}"
echo ""

# 2j. Firewall: health check + proxy → backends
echo "${YELLOW_TEXT}    Creating firewall rule: fw-allow-health-check-and-proxy...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --rules=tcp:80 \
  --target-tags=tag-alb-api \
  --quiet 2>&1

# Also apply to all instances as fallback if no tag on template
gcloud compute firewall-rules create fw-allow-health-check-and-proxy-all \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --rules=tcp:80 \
  --quiet 2>&1 || true

echo "${GREEN_TEXT}  ✔ Firewall rule fw-allow-health-check-and-proxy created${RESET_FORMAT}"
echo ""

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
