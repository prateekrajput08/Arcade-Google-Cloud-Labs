#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      GSP216 - Internal Load Balancing Lab                       ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "=== Configuration Setup ==="
read -p "Enter your region (e.g., us-east4): " REGION
read -p "Enter zone for subnet-a (e.g., ${REGION}-a): " ZONE_A
read -p "Enter zone for subnet-b (e.g., ${REGION}-b): " ZONE_B
read -p "Enter zone for utility VM (same as subnet-a, e.g., ${REGION}-a): " UTILITY_ZONE

echo ""
echo "Using configuration:"
echo "Region:       $REGION"
echo "Zone A:       $ZONE_A"
echo "Zone B:       $ZONE_B"
echo "Utility Zone: $UTILITY_ZONE"
echo ""

PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# ============================================================
# TASK 1: Firewall Rules
# ============================================================
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=== TASK 1: Configuring Firewall Rules ===${RESET_FORMAT}"

echo "Creating HTTP firewall rule..."
gcloud compute firewall-rules create app-allow-http \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=10.10.0.0/16 \
    --rules=tcp:80

echo "Creating health check firewall rule..."
gcloud compute firewall-rules create app-allow-health-check \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --rules=tcp

echo "${GREEN_TEXT}Firewall rules created!${RESET_FORMAT}"

# ============================================================
# TASK 2: Instance Templates, Instance Groups, Utility VM
# ============================================================
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=== TASK 2: Instance Templates and Groups ===${RESET_FORMAT}"

# --- FIX 1: Use --region for templates (no --no-address for subnet-a/b with no external IP)
echo "Creating instance-template-1 (subnet-a)..."
gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --region=$REGION \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh

echo "Creating instance-template-2 (subnet-b)..."
gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-b \
    --region=$REGION \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh

echo "Waiting 20s for templates..."
sleep 20

# --- FIX 2: Create managed instance groups (single-zone, correct flags)
echo "Creating instance-group-1 in $ZONE_A..."
gcloud compute instance-groups managed create instance-group-1 \
    --template=instance-template-1 \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --zone=$ZONE_A

echo "Creating instance-group-2 in $ZONE_B..."
gcloud compute instance-groups managed create instance-group-2 \
    --template=instance-template-2 \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --zone=$ZONE_B

# --- FIX 3: Autoscaling MUST include --cool-down-period=45 (initialization period)
echo "Configuring autoscaling for instance-group-1..."
gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --zone=$ZONE_A \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.80 \
    --cool-down-period=45

echo "Configuring autoscaling for instance-group-2..."
gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --zone=$ZONE_B \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.80 \
    --cool-down-period=45

echo "Waiting 60s for instance groups to initialize..."
sleep 60

# --- FIX 4: Utility VM — NO lb-backend tag, correct subnet, custom IP
echo "Creating utility-vm..."
gcloud compute instances create utility-vm \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --private-network-ip=10.10.20.50 \
    --no-address \
    --zone=$UTILITY_ZONE

echo "Waiting 30s for utility VM..."
sleep 30

echo "${GREEN_TEXT}Instance groups and utility VM created!${RESET_FORMAT}"

# Verify backend IPs
echo ""
echo "Fetching backend IPs..."
INSTANCE_1_IP=$(gcloud compute instances list \
    --filter="name~'instance-group-1'" \
    --zones=$ZONE_A \
    --format="value(networkInterfaces[0].networkIP)" 2>/dev/null)
INSTANCE_2_IP=$(gcloud compute instances list \
    --filter="name~'instance-group-2'" \
    --zones=$ZONE_B \
    --format="value(networkInterfaces[0].networkIP)" 2>/dev/null)

[ -z "$INSTANCE_1_IP" ] && INSTANCE_1_IP="10.10.20.2"
[ -z "$INSTANCE_2_IP" ] && INSTANCE_2_IP="10.10.30.2"

echo "Instance 1 IP: $INSTANCE_1_IP"
echo "Instance 2 IP: $INSTANCE_2_IP"

echo "Waiting 60s for startup scripts to finish on backends..."
sleep 60

echo "Testing backends via utility-vm..."
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --quiet --command="
    echo '--- Backend 1 ($INSTANCE_1_IP) ---'
    curl -s --connect-timeout 15 $INSTANCE_1_IP || echo 'Not reachable yet'
    echo ''
    echo '--- Backend 2 ($INSTANCE_2_IP) ---'
    curl -s --connect-timeout 15 $INSTANCE_2_IP || echo 'Not reachable yet'
" || echo "SSH test skipped (instances may still be starting). Continue to Task 3."

# ============================================================
# TASK 3: Internal Load Balancer
# ============================================================
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=== TASK 3: Configuring Internal Load Balancer ===${RESET_FORMAT}"

echo "Creating health check..."
gcloud compute health-checks create tcp my-ilb-health-check \
    --port=80 \
    --region=$REGION

echo "Creating backend service..."
gcloud compute backend-services create my-ilb-backend-service \
    --load-balancing-scheme=INTERNAL \
    --protocol=TCP \
    --health-checks=my-ilb-health-check \
    --health-checks-region=$REGION \
    --region=$REGION

echo "Adding instance-group-1 to backend service..."
gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-1 \
    --instance-group-zone=$ZONE_A \
    --region=$REGION

echo "Adding instance-group-2 to backend service..."
gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-2 \
    --instance-group-zone=$ZONE_B \
    --region=$REGION

echo "Reserving static IP 10.10.30.5 in subnet-b..."
gcloud compute addresses create my-ilb-ip \
    --region=$REGION \
    --subnet=subnet-b \
    --addresses=10.10.30.5

echo "Creating forwarding rule..."
gcloud compute forwarding-rules create my-ilb \
    --load-balancing-scheme=INTERNAL \
    --network=my-internal-app \
    --subnet=subnet-b \
    --address=10.10.30.5 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=my-ilb-backend-service \
    --backend-service-region=$REGION \
    --region=$REGION

echo "${GREEN_TEXT}ILB created!${RESET_FORMAT}"
echo "Waiting 90s for load balancer to become operational..."
sleep 90

# ============================================================
# TASK 4: Verify Load Balancer
# ============================================================
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=== TASK 4: Testing Internal Load Balancer ===${RESET_FORMAT}"

gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --quiet --command="
    echo '--- Load Balancer Test (10.10.30.5) ---'
    for i in 1 2 3 4 5; do
        echo 'Request '\$i:
        curl -s --connect-timeout 15 10.10.30.5 | grep -E 'Hostname|Location' | head -2
        sleep 2
    done
" || echo "SSH test failed. You can test manually from the console."

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED!                           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}If score is still not 30/30, manually verify in Console:${RESET_FORMAT}"
echo "  1. Both instance-group-1 and instance-group-2 are RUNNING"
echo "  2. utility-vm has internal IP 10.10.20.50 in subnet-a"
echo "  3. Autoscaling shows min=1, max=1, CPU target=80%, cooldown=45s"
echo "  4. ILB forwarding rule shows 10.10.30.5:80 pointing to backend service"
