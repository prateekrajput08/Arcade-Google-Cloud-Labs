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

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Starting NGFW migration and firewall policy setup${RESET_FORMAT}"

echo -ne "${CYAN_TEXT}${BOLD_TEXT}Enter Zone (e.g., us-central1-a): ${RESET_FORMAT}"
read ZONE

if [ -z "$ZONE" ]; then
  echo -e "${RED_TEXT}Zone is required${RESET_FORMAT}"
  exit 1
fi

echo -e "${YELLOW_TEXT}Deriving region from zone${RESET_FORMAT}"
REGION=$(echo $ZONE | sed 's/-[a-z]$//')

NETWORK_NAME="external-network"
POLICY_NAME="fw-policy"
TAG_KEY="vpc-tags"
TAG_MAPPING_FILE="tag-mapping.json"

echo -e "${YELLOW_TEXT}Setting gcloud configuration${RESET_FORMAT}"
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION
export PROJECT_ID=$(gcloud config get-value project)

echo -e "${YELLOW_TEXT}Creating firewall rules${RESET_FORMAT}"
gcloud compute firewall-rules create allow-ssh \
  --direction=INGRESS --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=10.1.0.0/24,10.2.0.0/24 \
  --network=$NETWORK_NAME --target-tags=ssh --description="allow-ssh"

gcloud compute firewall-rules create allow-web \
  --allow tcp:80,tcp:443 \
  --source-ranges=10.0.0.0/16 \
  --network=$NETWORK_NAME --target-tags=web --description="allow-web"

echo -e "${YELLOW_TEXT}Exporting tag mapping${RESET_FORMAT}"
gcloud beta compute firewall-rules migrate \
  --source-network=$NETWORK_NAME \
  --export-tag-mapping \
  --tag-mapping-file=$TAG_MAPPING_FILE

echo -e "${YELLOW_TEXT}Creating tag key${RESET_FORMAT}"
gcloud resource-manager tags keys create $TAG_KEY \
  --parent=projects/$PROJECT_ID \
  --purpose=GCE_FIREWALL \
  --purpose-data=network=$PROJECT_ID/$NETWORK_NAME

echo -e "${YELLOW_TEXT}Fetching tag key ID${RESET_FORMAT}"
for i in {1..5}; do
  TAG_KEY_ID=$(gcloud resource-manager tags keys list \
    --parent=projects/$PROJECT_ID \
    --filter="shortName=$TAG_KEY" \
    --format="value(name)")
  [ ! -z "$TAG_KEY_ID" ] && break
  sleep 2
done

if [ -z "$TAG_KEY_ID" ]; then
  echo -e "${RED_TEXT}Failed to get TAG_KEY_ID${RESET_FORMAT}"
  exit 1
fi

echo -e "${YELLOW_TEXT}Creating tag values${RESET_FORMAT}"
SSH_TAG=$(gcloud resource-manager tags values create ssh --parent=$TAG_KEY_ID --format="value(name)")
WEB_TAG=$(gcloud resource-manager tags values create web --parent=$TAG_KEY_ID --format="value(name)")
EXT_TAG=$(gcloud resource-manager tags values create external --parent=$TAG_KEY_ID --format="value(name)")

echo -e "${YELLOW_TEXT}Creating mapping file${RESET_FORMAT}"
cat > $TAG_MAPPING_FILE <<EOF
{
  "ssh": "$SSH_TAG",
  "web": "$WEB_TAG",
  "external": "$EXT_TAG"
}
EOF

echo -e "${YELLOW_TEXT}Binding tags to instances${RESET_FORMAT}"
gcloud beta compute firewall-rules migrate \
  --source-network=$NETWORK_NAME \
  --bind-tags-to-instances \
  --tag-mapping-file=$TAG_MAPPING_FILE

echo -e "${YELLOW_TEXT}Migrating firewall rules to global policy${RESET_FORMAT}"
gcloud beta compute firewall-rules migrate \
  --source-network=$NETWORK_NAME \
  --tag-mapping-file=$TAG_MAPPING_FILE \
  --target-firewall-policy=$POLICY_NAME

echo -e "${YELLOW_TEXT}Associating firewall policy with network${RESET_FORMAT}"
gcloud compute network-firewall-policies associations create \
  --firewall-policy=$POLICY_NAME \
  --network=$NETWORK_NAME \
  --global-firewall-policy

echo -e "${YELLOW_TEXT}Setting enforcement order${RESET_FORMAT}"
gcloud compute networks update $NETWORK_NAME \
  --network-firewall-policy-enforcement-order=BEFORE_CLASSIC_FIREWALL

echo -e "${YELLOW_TEXT}Enabling firewall logging${RESET_FORMAT}"
gcloud compute network-firewall-policies rules update 1000 \
  --firewall-policy=$POLICY_NAME \
  --enable-logging \
  --global-firewall-policy

# ================================
# FETCH DYNAMIC IPS
# ================================
echo -e "${YELLOW_TEXT}Fetching VM IP addresses${RESET_FORMAT}"

EXTERNAL_IP=$(gcloud compute instances list \
  --filter="name:external-server" \
  --format="value(EXTERNAL_IP)")

INTERNAL_IP=$(gcloud compute instances list \
  --filter="name:internal-server-1" \
  --format="value(INTERNAL_IP)")

echo -e "${TEAL}---------------------------------${RESET_FORMAT}"
echo -e "${GREEN_TEXT}External Server IP: $EXTERNAL_IP${RESET_FORMAT}"
echo -e "${GREEN_TEXT}Internal Server IP: $INTERNAL_IP${RESET_FORMAT}"
echo -e "${TEAL}---------------------------------${RESET_FORMAT}"

# ================================
# TASK 11
# ================================
echo ""
echo -e "${CYAN_TEXT}${BOLD_TEXT}Manual Step Required: Connectivity Test (Task 11)${RESET_FORMAT}"

echo -e "${YELLOW_TEXT}Open Connectivity Test:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}https://console.cloud.google.com/net-intelligence/connectivity/tests${RESET_FORMAT}"

echo ""
echo -e "${YELLOW_TEXT}Create Test 1 (External → Internal):${RESET_FORMAT}"
echo -e "Source IP: $EXTERNAL_IP"
echo -e "Type: External IP"
echo -e "Destination IP: $INTERNAL_IP"
echo -e "Port: 80"

echo ""
echo -e "${YELLOW_TEXT}Create Test 2 (Internal → External):${RESET_FORMAT}"
echo -e "Source IP: $INTERNAL_IP"
echo -e "Type: Internal IP"
echo -e "Source network: internal-network"
echo -e "Destination IP: $EXTERNAL_IP"

echo ""
echo -e "${YELLOW_TEXT}Wait for results, then click 'Check my progress'${RESET_FORMAT}"

echo ""
read -p "Press Enter after completing Task 11..." USER_CONFIRM

# ================================
# CLEANUP
# ================================
echo -e "${YELLOW_TEXT}Deleting old firewall rules${RESET_FORMAT}"
gcloud compute firewall-rules delete allow-ssh -q
gcloud compute firewall-rules delete allow-web -q

echo -e "${GREEN_TEXT}Execution completed. Lab should be fully completed.${RESET_FORMAT}"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echopleted. Proceed to check lab progress.${RESET_FORMAT}"
