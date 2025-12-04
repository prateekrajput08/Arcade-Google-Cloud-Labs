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

set -euo pipefail
IFS=$'\n\t'

# NGFW Policy Challenge I - automated helper script
# Usage: ./ngfw_lab_script.sh

prompt_if_empty() {
  local var_name="$1"; local prompt_text="$2"
  if [ -z "${!var_name:-}" ]; then
    read -rp "${CYAN_TEXT:-}${BOLD_TEXT}${prompt_text}${RESET_FORMAT} " $var_name
    export $var_name
  fi
}

# Auto-detect project, region, and zone
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null || echo "")
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null || echo "")

# Auto-detect without prompting user
# If REGION is empty, derive it from ZONE
if [ -z "$REGION" ] && [ -n "$ZONE" ]; then
  REGION=$(echo "$ZONE" | awk -F- '{print $1 "-" $2}')
fi

# If any variable is still empty, set safe defaults instead of asking user
PROJECT_ID=${PROJECT_ID:-"$(gcloud config get-value project 2>/dev/null)"}
ZONE=${ZONE:-"us-central1-a"}
REGION=${REGION:-"us-central1"}

export PROJECT_ID REGION ZONE

echo "${GREEN_TEXT}${BOLD_TEXT}Auto-detected / defaulted to: project=$PROJECT_ID region=$REGION zone=$ZONE${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}Detected/Using project=$PROJECT_ID region=$REGION zone=$ZONE${RESET_FORMAT}"

# Enable required APIs
echo "${YELLOW_TEXT}Enabling required APIs...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com iap.googleapis.com monitoring.googleapis.com logging.googleapis.com --project="$PROJECT_ID"

# Set defaults
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Variables for resources
VPC_NAME="test-vpc"
CLIENT_SUBNET="client-subnet"
SERVER_SUBNET="server-subnet"
CLIENT_RANGE="10.10.10.0/24"
SERVER_RANGE="10.20.20.0/24"
WEB_SERVER_NAME="web-server"
CLIENT_NAME="client-instance"
IAP_TAG="iap-gce"
WEB_TAG="web-server-tag"
FIREWALL_POLICY_NAME="test-firewall-policy"
RULE_PRIORITY=100

# Create VPC and subnets
echo "${YELLOW_TEXT}Creating VPC and subnets...${RESET_FORMAT}"
gcloud compute networks create "$VPC_NAME" --subnet-mode=custom --project="$PROJECT_ID"

gcloud compute networks subnets create "$CLIENT_SUBNET" \
  --network="$VPC_NAME" --region="$REGION" --range="$CLIENT_RANGE" --project="$PROJECT_ID"

gcloud compute networks subnets create "$SERVER_SUBNET" \
  --network="$VPC_NAME" --region="$REGION" --range="$SERVER_RANGE" --project="$PROJECT_ID"

# Allow IAP SSH to instances tagged with $IAP_TAG
echo "${YELLOW_TEXT}Creating firewall rule to allow IAP SSH to instances with tag '$IAP_TAG'...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-iap-ssh \
  --network="$VPC_NAME" --action=ALLOW --direction=INGRESS \
  --rules=tcp:22 --target-tags="$IAP_TAG" --project="$PROJECT_ID" \
  --source-ranges=35.235.240.0/20 # Google IAP IP range (documented by Google)

# Create firewall rule to allow internal HTTP from anywhere within VPC (helps testing when NGFW rule changed)
gcloud compute firewall-rules create allow-internal-http \
  --network="$VPC_NAME" --action=ALLOW --direction=INGRESS \
  --rules=tcp:80 --source-ranges=10.0.0.0/8 --target-tags="$WEB_TAG" --project="$PROJECT_ID" || true

# Create web-server with startup script that installs nginx
echo "${YELLOW_TEXT}Creating web-server instance...${RESET_FORMAT}"
WEB_STARTUP='#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<EOF
Hello from web-server!\nEOF
systemctl restart nginx'

gcloud compute instances create "$WEB_SERVER_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --machine-type=e2-micro --subnet="$SERVER_SUBNET" --tags="$WEB_TAG,$IAP_TAG" \
  --metadata=startup-script="$WEB_STARTUP" \
  --scopes=https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write

# Create client instance
echo "${YELLOW_TEXT}Creating client-instance...${RESET_FORMAT}"
gcloud compute instances create "$CLIENT_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --machine-type=e2-micro --subnet="$CLIENT_SUBNET" --tags="$IAP_TAG" \
  --scopes=https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write

# Wait a short while for instances to initialize
echo "${YELLOW_TEXT}Waiting 30 seconds for instances to initialize...${RESET_FORMAT}"
sleep 30

# Get internal IP of web-server
WEBSERVER_IP=$(gcloud compute instances describe "$WEB_SERVER_NAME" --zone="$ZONE" --format="get(networkInterfaces[0].networkIP)" --project="$PROJECT_ID")
echo "${GREEN_TEXT}Web server internal IP: $WEBSERVER_IP${RESET_FORMAT}"

# Create a global network firewall policy
echo "${YELLOW_TEXT}Creating global network firewall policy '$FIREWALL_POLICY_NAME'...${RESET_FORMAT}"
gcloud compute network-firewall-policies create "$FIREWALL_POLICY_NAME" --global --project="$PROJECT_ID" || true

# Add a misconfigured rule that DENIES TCP:80 from client-subnet to server-subnet
# We use layer4-configs to specify tcp:80 and src-ip-ranges for the client subnet.
# Rule number is set to $RULE_PRIORITY so later we can update it by priority.
echo "${YELLOW_TEXT}Creating misconfigured DENY rule (priority $RULE_PRIORITY) in firewall policy...${RESET_FORMAT}"

gcloud compute network-firewall-policies rules create "$RULE_PRIORITY" \
  --firewall-policy="$FIREWALL_POLICY_NAME" --global \
  --action=deny \
  --description="Deny HTTP from client-subnet to server-subnet" \
  --layer4-configs=tcp:80 \
  --src-ip-ranges="$CLIENT_RANGE" \
  --dest-ip-ranges="$SERVER_RANGE" || true

# Associate the network firewall policy with the VPC network
echo "${YELLOW_TEXT}Associating firewall policy with VPC network '$VPC_NAME'...${RESET_FORMAT}"

gcloud compute network-firewall-policies associations create \
  --firewall-policy="$FIREWALL_POLICY_NAME" \
  --network="$VPC_NAME" --global \
  --project="$PROJECT_ID" || true

# Validate that curl from client to web server is blocked
echo "${YELLOW_TEXT}Testing connectivity from client to web-server (expected: timeout)...${RESET_FORMAT}"

gcloud compute ssh "$CLIENT_NAME" --zone="$ZONE" --tunnel-through-iap --project="$PROJECT_ID" --command "curl -m 5 http://$WEBSERVER_IP:80 || echo 'curl failed or timed out'"

echo "${YELLOW_TEXT}Check Cloud Logging / Logs Explorer for entries related to the firewall policy: protoPayload.resourceName=\"projects/$PROJECT_ID/global/firewallPolicies/$FIREWALL_POLICY_NAME\"${RESET_FORMAT}"

# Now update the rule to allow traffic (resolve the misconfiguration)
echo "${YELLOW_TEXT}Updating firewall policy rule to ALLOW traffic (resolving denial)...${RESET_FORMAT}"

# Update by deleting and recreating allowed rule or update action
# Some gcloud versions support 'rules update' — attempt update first, otherwise delete/create
if gcloud compute network-firewall-policies rules update "$RULE_PRIORITY" --firewall-policy="$FIREWALL_POLICY_NAME" --global --action=allow --layer4-configs=tcp:80 --src-ip-ranges="$CLIENT_RANGE" --dest-ip-ranges="$SERVER_RANGE" >/dev/null 2>&1; then
  echo "Updated rule $RULE_PRIORITY to allow"
else
  echo "Could not update rule directly; deleting and recreating as allow"
  gcloud compute network-firewall-policies rules delete "$RULE_PRIORITY" --firewall-policy="$FIREWALL_POLICY_NAME" --global --quiet || true
  gcloud compute network-firewall-policies rules create "$RULE_PRIORITY" \
    --firewall-policy="$FIREWALL_POLICY_NAME" --global --action=allow \
    --description="Allow HTTP from client-subnet to server-subnet" \
    --layer4-configs=tcp:80 --src-ip-ranges="$CLIENT_RANGE" --dest-ip-ranges="$SERVER_RANGE" || true
fi

# Re-test connectivity (should succeed)
echo "${YELLOW_TEXT}Re-testing connectivity from client to web-server (expected: success)...${RESET_FORMAT}"

gcloud compute ssh "$CLIENT_NAME" --zone="$ZONE" --tunnel-through-iap --project="$PROJECT_ID" --command "curl -m 5 http://$WEBSERVER_IP:80 || echo 'curl failed or timed out'"

echo "${GREEN_TEXT}${BOLD_TEXT}Script completed. If the final curl returned the web page, the NGFW policy update worked.${RESET_FORMAT}"

# Helpful reminders
cat <<EOF

Notes:
- This script creates GCE instances and a global network firewall policy. You will be charged for resources while they exist.
- To clean up after testing, delete the instances, network-firewall-policy associations, and the VPC.
  Example cleanup commands:
    gcloud compute instances delete $WEB_SERVER_NAME $CLIENT_NAME --zone=$ZONE --project=$PROJECT_ID --quiet
    gcloud compute network-firewall-policies associations delete --firewall-policy=$FIREWALL_POLICY_NAME --network=$VPC_NAME --global --project=$PROJECT_ID || true
    gcloud compute network-firewall-policies delete $FIREWALL_POLICY_NAME --global --project=$PROJECT_ID || true
    gcloud compute networks subnets delete $CLIENT_SUBNET $SERVER_SUBNET --region=$REGION --project=$PROJECT_ID --quiet || true
    gcloud compute networks delete $VPC_NAME --project=$PROJECT_ID --quiet || true

EOF


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
