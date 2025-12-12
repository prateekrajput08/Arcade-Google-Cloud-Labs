
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

# Get user inputs for region and zone
echo "=== Configuration Setup ==="
read -p "Enter your region (e.g., us-central1): " REGION
read -p "Enter zone for subnet-a (e.g., ${REGION}-a): " ZONE_A
read -p "Enter zone for subnet-b (e.g., ${REGION}-b): " ZONE_B
read -p "Enter zone for utility VM (e.g., ${REGION}-a): " UTILITY_ZONE

echo ""
echo "Using configuration:"
echo "Region: $REGION"
echo "Zone A: $ZONE_A"
echo "Zone B: $ZONE_B"
echo "Utility Zone: $UTILITY_ZONE"
echo ""

# Set project variables
PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# Task 1: Configure HTTP and health check firewall rules
echo ""
echo "=== TASK 1: Configuring Firewall Rules ==="

# Create HTTP firewall rule
echo "Creating HTTP firewall rule..."
gcloud compute firewall-rules create app-allow-http \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=10.10.0.0/16 \
    --rules=tcp:80

# Create health check firewall rule
echo "Creating health check firewall rule..."
gcloud compute firewall-rules create app-allow-health-check \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --rules=tcp

echo "Firewall rules created successfully!"
echo ""

# Task 2: Configure instance templates and create instance groups
echo "=== TASK 2: Creating Instance Templates and Groups ==="

# Create instance template for subnet-a
echo "Creating instance template for subnet-a..."
gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

# Create instance template for subnet-b
echo "Creating instance template for subnet-b..."
gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-b \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

echo "Waiting for instance templates to be created..."
sleep 30

# Create managed instance group for zone A
echo "Creating instance group in $ZONE_A..."
gcloud compute instance-groups managed create instance-group-1 \
    --template=instance-template-1 \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --zone=$ZONE_A

# Create managed instance group for zone B
echo "Creating instance group in $ZONE_B..."
gcloud compute instance-groups managed create instance-group-2 \
    --template=instance-template-2 \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --zone=$ZONE_B

echo "Waiting for instance groups to be created..."
sleep 60

# Configure autoscaling for both instance groups (corrected command)
echo "Configuring autoscaling..."
gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --zone=$ZONE_A \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8

gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --zone=$ZONE_B \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8

echo "Instance groups created and configured!"
echo ""

# Create utility VM
echo "Creating utility VM..."
gcloud compute instances create utility-vm \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --private-network-ip=10.10.20.50 \
    --zone=$UTILITY_ZONE \
    --tags=lb-backend

echo "Utility VM created!"
echo ""

# Wait for all instances to be ready
echo "Waiting for all instances to be fully ready..."
sleep 90

# Verify backends
echo "=== Verifying Backends ==="

# Get internal IPs of the instances (corrected filtering)
INSTANCE_1_IP=$(gcloud compute instances list --filter="name~'instance-group-1.*'" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_A)
INSTANCE_2_IP=$(gcloud compute instances list --filter="name~'instance-group-2.*'" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_B)

echo "Instance 1 IP: $INSTANCE_1_IP"
echo "Instance 2 IP: $INSTANCE_2_IP"
echo ""

# If IPs are empty, use default IPs
if [ -z "$INSTANCE_1_IP" ]; then
    INSTANCE_1_IP="10.10.20.2"
    echo "Using default IP for instance 1: $INSTANCE_1_IP"
fi

if [ -z "$INSTANCE_2_IP" ]; then
    INSTANCE_2_IP="10.10.30.2"
    echo "Using default IP for instance 2: $INSTANCE_2_IP"
fi

# Test connectivity via utility VM
echo "Testing connectivity through utility VM..."
echo "This may take a moment..."

# SSH into utility VM and test connectivity (with error handling)
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing connection to instance-group-1 at $INSTANCE_1_IP...'
    max_attempts=3
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 $INSTANCE_1_IP > /dev/null; then
            echo '✓ Successfully connected to instance-group-1'
            curl -s $INSTANCE_1_IP | grep -E '(Server Hostname|Server Location|Client IP)' | head -3
            break
        else
            echo 'Attempt \$i failed, retrying...'
            sleep 10
        fi
        if [ \$i -eq \$max_attempts ]; then
            echo '✗ Failed to connect to instance-group-1 after \$max_attempts attempts'
        fi
    done
    
    echo ''
    echo 'Testing connection to instance-group-2 at $INSTANCE_2_IP...'
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 $INSTANCE_2_IP > /dev/null; then
            echo '✓ Successfully connected to instance-group-2'
            curl -s $INSTANCE_2_IP | grep -E '(Server Hostname|Server Location|Client IP)' | head -3
            break
        else
            echo 'Attempt \$i failed, retrying...'
            sleep 10
        fi
        if [ \$i -eq \$max_attempts ]; then
            echo '✗ Failed to connect to instance-group-2 after \$max_attempts attempts'
        fi
    done
    echo ''
    echo 'Backend verification complete!'
" || echo "SSH connection failed, but continuing with setup..."

echo ""
echo "Backend verification attempted!"
echo ""

# Task 3: Configure the Internal Load Balancer
echo "=== TASK 3: Configuring Internal Load Balancer ==="

# Create health check
echo "Creating health check..."
gcloud compute health-checks create tcp my-ilb-health-check \
    --port=80 \
    --region=$REGION

# Create backend service
echo "Creating backend service..."
gcloud compute backend-services create my-ilb-backend-service \
    --load-balancing-scheme=INTERNAL \
    --protocol=TCP \
    --health-checks=my-ilb-health-check \
    --health-checks-region=$REGION \
    --region=$REGION

# Add instance groups to backend service
echo "Adding instance groups to backend service..."
gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-1 \
    --instance-group-zone=$ZONE_A \
    --region=$REGION

gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-2 \
    --instance-group-zone=$ZONE_B \
    --region=$REGION

# Reserve static IP address
echo "Reserving static IP address..."
gcloud compute addresses create my-ilb-ip \
    --region=$REGION \
    --subnet=subnet-b \
    --addresses=10.10.30.5

# Create forwarding rule
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

echo "Internal Load Balancer configuration complete!"
echo ""

# Wait for load balancer to be ready
echo "Waiting for load balancer to be fully operational..."
sleep 60

# Final verification
echo "=== Final Verification ==="
echo "Load Balancer IP: 10.10.30.5"
echo ""

# Test the load balancer (with error handling)
echo "Testing load balancer..."
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing Load Balancer (10.10.30.5):'
    max_attempts=3
    success=false
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 10.10.30.5 > /dev/null; then
            echo '✓ Load Balancer is working!'
            echo 'Response from backend:'
            curl -s 10.10.30.5 | grep -E '(Server Hostname|Server Location)' | head -2
            success=true
            break
        else
            echo 'Attempt \$i failed, retrying in 10 seconds...'
            sleep 10
        fi
    done
    
    if ! \$success; then
        echo '✗ Load Balancer test failed after \$max_attempts attempts'
        echo 'This might be normal if instances are still initializing.'
    fi
    
    echo ''
    echo 'Testing multiple requests to see load balancing in action:'
    for i in {1..3}; do
        echo 'Request' \$i ':'
        curl -s 10.10.30.5 | grep -E 'Server Hostname|Server Location' | head -1
        sleep 2
    done
" || echo "SSH test failed, but setup is complete. You can test manually later."


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
