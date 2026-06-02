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

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

#!/bin/bash
# ============================================================
# Script  : TechCode9.sh
# Channel : TechCode9 (https://youtube.com/@TechCode9)
# Lab     : GSP636 — Regional Internal Proxy Network Load Balancer
# Author  : TechCode9
# Desc    : Automates full GSP636 lab setup on Google Cloud.
#           Subscribe TechCode9 for more GCP lab solutions!
# ============================================================

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ─── AUTO-FETCH REGION ───────────────────────────────────────────────
# TechCode9: auto-detect region so no manual input needed
echo "${YELLOW_TEXT}${BOLD_TEXT}[INFO] Fetching project region... | TechCode9${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  export REGION=$(gcloud config get-value compute/region 2>/dev/null)
fi

if [ -z "$REGION" ]; then
  echo "${RED_TEXT}[ERROR] Region not found. Set manually: | TechCode9${RESET_FORMAT}"
  read -p "Enter region (e.g. us-central1): " REGION
fi

# TechCode9: derive zones from region
export ZONE_A="${REGION}-b"
export ZONE_C="${REGION}-c"

# TechCode9: channel tag embedded in description label for all GCP resources
export TECHCODE9_LABEL="created-by=techcode9"

echo "${GREEN_TEXT}  Region : ${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}  Zone A : ${ZONE_A}${RESET_FORMAT}"
echo "${GREEN_TEXT}  Zone C : ${ZONE_C}${RESET_FORMAT}"
echo "${GREEN_TEXT}  Label  : ${TECHCODE9_LABEL}${RESET_FORMAT}"
echo ""

# ─── TASK 1: NETWORK & SUBNETS ───────────────────────────────────────
# TechCode9: create custom VPC + backend-subnet + proxy-only-subnet
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 1] Creating VPC network and subnets... | TechCode9${RESET_FORMAT}"

gcloud compute networks create lb-network \
  --subnet-mode=custom \
  --description="TechCode9 - GSP636 custom VPC network" \
  --quiet

echo "${GREEN_TEXT}  ✔ lb-network created${RESET_FORMAT}"

# TechCode9: backend subnet 10.1.2.0/24
gcloud compute networks subnets create backend-subnet \
  --network=lb-network \
  --region=${REGION} \
  --range=10.1.2.0/24 \
  --description="TechCode9 - backend instances subnet" \
  --quiet

echo "${GREEN_TEXT}  ✔ backend-subnet created (10.1.2.0/24)${RESET_FORMAT}"

# TechCode9: proxy-only-subnet — reserved for Envoy proxies, DO NOT assign backends here
gcloud compute networks subnets create proxy-only-subnet \
  --network=lb-network \
  --region=${REGION} \
  --range=10.129.0.0/23 \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE \
  --description="TechCode9 - proxy-only subnet for internal NLB Envoy proxies" \
  --quiet

echo "${GREEN_TEXT}  ✔ proxy-only-subnet created (10.129.0.0/23)${RESET_FORMAT}"
echo ""

# ─── TASK 2: FIREWALL RULES ──────────────────────────────────────────
# TechCode9: three rules needed — SSH, GCP health check IPs, proxy-only-subnet range
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 2] Creating firewall rules... | TechCode9${RESET_FORMAT}"

# TechCode9: allow SSH from anywhere to tagged instances
gcloud compute firewall-rules create fw-allow-ssh \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-ssh \
  --source-ranges=0.0.0.0/0 \
  --rules=tcp:22 \
  --description="TechCode9 - allow SSH to backend and client VMs" \
  --quiet

echo "${GREEN_TEXT}  ✔ fw-allow-ssh${RESET_FORMAT}"

# TechCode9: GCP health checker source ranges — required for backend health probes
gcloud compute firewall-rules create fw-allow-health-check \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-health-check \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --rules=tcp:80 \
  --description="TechCode9 - allow GCP health checker IPs to reach backends on port 80" \
  --quiet

echo "${GREEN_TEXT}  ✔ fw-allow-health-check${RESET_FORMAT}"

# TechCode9: proxy-only-subnet range — Envoy proxies forward client traffic from this range
gcloud compute firewall-rules create fw-allow-proxy-only-subnet \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-proxy-only-subnet \
  --source-ranges=10.129.0.0/23 \
  --rules=tcp:80 \
  --description="TechCode9 - allow proxy-only-subnet (Envoy) traffic to backends on port 80" \
  --quiet

echo "${GREEN_TEXT}  ✔ fw-allow-proxy-only-subnet${RESET_FORMAT}"
echo ""

# ─── TASK 3: INSTANCE TEMPLATE & MIGs ───────────────────────────────
# TechCode9: template includes Apache + hostname page + all 3 network tags
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 3] Creating instance template... | TechCode9${RESET_FORMAT}"

gcloud compute instance-templates create int-tcp-proxy-backend-template \
  --region=${REGION} \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh,allow-health-check,allow-proxy-only-subnet \
  --description="TechCode9 - backend template for GSP636 internal proxy NLB" \
  --metadata=startup-script='#! /bin/bash
# TechCode9 - GSP636 backend startup script
apt-get update
apt-get install apache2 -y
a2ensite default-ssl
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://metadata.google.internal/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname | TechCode9" | \
tee /var/www/html/index.html
systemctl restart apache2' \
  --quiet

echo "${GREEN_TEXT}  ✔ int-tcp-proxy-backend-template created${RESET_FORMAT}"
echo ""

# TechCode9: mig-a in zone-b
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 3] Creating MIG mig-a in ${ZONE_A}... | TechCode9${RESET_FORMAT}"

gcloud compute instance-groups managed create mig-a \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --zone=${ZONE_A} \
  --description="TechCode9 - mig-a backend group zone ${ZONE_A}" \
  --quiet

# TechCode9: named port tcp80→80 used by backend service port-name mapping
gcloud compute instance-groups managed set-named-ports mig-a \
  --named-ports=tcp80:80 \
  --zone=${ZONE_A} \
  --quiet

echo "${GREEN_TEXT}  ✔ mig-a created (zone: ${ZONE_A})${RESET_FORMAT}"

# TechCode9: mig-c in zone-c for zonal redundancy
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 3] Creating MIG mig-c in ${ZONE_C}... | TechCode9${RESET_FORMAT}"

gcloud compute instance-groups managed create mig-c \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --zone=${ZONE_C} \
  --description="TechCode9 - mig-c backend group zone ${ZONE_C}" \
  --quiet

gcloud compute instance-groups managed set-named-ports mig-c \
  --named-ports=tcp80:80 \
  --zone=${ZONE_C} \
  --quiet

echo "${GREEN_TEXT}  ✔ mig-c created (zone: ${ZONE_C})${RESET_FORMAT}"
echo ""

# ─── TASK 4: LOAD BALANCER ───────────────────────────────────────────
# TechCode9: reserve internal VIP, build health check → backend service → proxy → forwarding rule
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 4] Reserving internal IP address... | TechCode9${RESET_FORMAT}"

# TechCode9: SHARED_LOADBALANCER_VIP purpose required for internal proxy NLB
gcloud compute addresses create int-tcp-ip-address \
  --region=${REGION} \
  --subnet=backend-subnet \
  --purpose=SHARED_LOADBALANCER_VIP \
  --description="TechCode9 - internal VIP for GSP636 proxy NLB" \
  --quiet

export LB_IP=$(gcloud compute addresses describe int-tcp-ip-address \
  --region=${REGION} \
  --format='value(address)')

echo "${GREEN_TEXT}  ✔ Reserved IP: ${LB_IP}${RESET_FORMAT}"
echo ""

# TechCode9: TCP health check probes backends on port 80
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 4] Creating health check... | TechCode9${RESET_FORMAT}"

gcloud compute health-checks create tcp tcp-health-check \
  --region=${REGION} \
  --port=80 \
  --description="TechCode9 - TCP health check for GSP636 backends" \
  --quiet

echo "${GREEN_TEXT}  ✔ tcp-health-check created${RESET_FORMAT}"

# TechCode9: backend service uses named port tcp80 matching MIG port mapping
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 4] Creating backend service... | TechCode9${RESET_FORMAT}"

gcloud compute backend-services create my-int-tcp-lb \
  --protocol=TCP \
  --health-checks=tcp-health-check \
  --health-checks-region=${REGION} \
  --region=${REGION} \
  --port-name=tcp80 \
  --description="TechCode9 - GSP636 internal proxy NLB backend service" \
  --quiet

# TechCode9: add mig-a backend
gcloud compute backend-services add-backend my-int-tcp-lb \
  --instance-group=mig-a \
  --instance-group-zone=${ZONE_A} \
  --region=${REGION} \
  --balancing-mode=CONNECTION \
  --quiet

# TechCode9: add mig-c backend
gcloud compute backend-services add-backend my-int-tcp-lb \
  --instance-group=mig-c \
  --instance-group-zone=${ZONE_C} \
  --region=${REGION} \
  --balancing-mode=CONNECTION \
  --quiet

echo "${GREEN_TEXT}  ✔ Backend service created with mig-a + mig-c${RESET_FORMAT}"

# TechCode9: target TCP proxy sits between forwarding rule and backend service
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 4] Creating target TCP proxy... | TechCode9${RESET_FORMAT}"

gcloud compute target-tcp-proxies create my-int-tcp-lb-proxy \
  --backend-service=my-int-tcp-lb \
  --region=${REGION} \
  --description="TechCode9 - target TCP proxy for GSP636 internal NLB" \
  --quiet

echo "${GREEN_TEXT}  ✔ Target TCP proxy created${RESET_FORMAT}"

# TechCode9: forwarding rule exposes LB on port 110 (client connects here)
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 4] Creating forwarding rule on port 110... | TechCode9${RESET_FORMAT}"

gcloud compute forwarding-rules create int-tcp-forwarding-rule \
  --region=${REGION} \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network=lb-network \
  --subnet=backend-subnet \
  --address=int-tcp-ip-address \
  --ports=110 \
  --target-tcp-proxy=my-int-tcp-lb-proxy \
  --target-tcp-proxy-region=${REGION} \
  --description="TechCode9 - frontend forwarding rule port 110 for GSP636 NLB" \
  --quiet

echo "${GREEN_TEXT}  ✔ Forwarding rule created (port 110 → proxy → backends:80)${RESET_FORMAT}"
echo ""

# ─── TASK 5: CLIENT VM ───────────────────────────────────────────────
# TechCode9: client VM must be inside lb-network to reach internal LB VIP
echo "${CYAN_TEXT}${BOLD_TEXT}[TASK 5] Creating client VM... | TechCode9${RESET_FORMAT}"

gcloud compute instances create client-vm \
  --zone=${ZONE_A} \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh \
  --description="TechCode9 - internal client VM to test GSP636 NLB" \
  --quiet

echo "${GREEN_TEXT}  ✔ client-vm created in ${ZONE_A}${RESET_FORMAT}"
echo ""

# ─── WAIT FOR BACKENDS ───────────────────────────────────────────────
# TechCode9: wait for MIG VMs to boot and Apache startup script to complete
echo "${YELLOW_TEXT}${BOLD_TEXT}[WAIT] Pausing 5 min for MIG instances + startup scripts... | TechCode9${RESET_FORMAT}"
for i in {1..5}; do
  echo "${BLACK_TEXT}  ${i}/5 min... | TechCode9${RESET_FORMAT}"
  sleep 60
done
echo ""

# ─── HEALTH CHECK ────────────────────────────────────────────────────
# TechCode9: both mig-a and mig-c must show HEALTHY before testing
echo "${YELLOW_TEXT}${BOLD_TEXT}[CHECK] Backend health status: | TechCode9${RESET_FORMAT}"
gcloud compute backend-services get-health my-int-tcp-lb --region=${REGION}
echo ""


# ─── SUMMARY ─────────────────────────────────────────────────────────
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         LAB SETUP COMPLETE!               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo ""
echo "${WHITE_TEXT}  LB Internal IP : ${BOLD_TEXT}${LB_IP}${RESET_FORMAT}"
echo "${WHITE_TEXT}  Frontend Port  : ${BOLD_TEXT}110${RESET_FORMAT}"
echo "${WHITE_TEXT}  Client VM Zone : ${BOLD_TEXT}${ZONE_A}${RESET_FORMAT}"
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}[TEST] SSH to client-vm and run: | TechCode9${RESET_FORMAT}"
echo "${CYAN_TEXT}  gcloud compute ssh client-vm --zone=${ZONE_A}${RESET_FORMAT}"
echo "${CYAN_TEXT}  curl ${LB_IP}:110${RESET_FORMAT}"
echo "${CYAN_TEXT}  # Run multiple times — hostname alternates between mig-a-XXXX / mig-c-XXXX${RESET_FORMAT}"
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}  If you found this helpful, Subscribe → TechCode9          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  https://youtube.com/@TechCode9                             ${RESET_FORMAT}"
echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Done. | TechCode9${RESET_FORMAT}"
echo ""

# ─── SELF CLEANUP ────────────────────────────────────────────────────
# TechCode9: remove this script from terminal after execution
rm -- "$0"
