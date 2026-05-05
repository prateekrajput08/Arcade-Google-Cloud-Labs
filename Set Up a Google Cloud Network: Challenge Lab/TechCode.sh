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
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

#----------------------------------------------------inputs--------------------------------------------------#

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter VPC Network Name (VPC_NAME)       : ${RESET_FORMAT}" VPC_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Subnet A Name    (SUBNET_A)       : ${RESET_FORMAT}" SUBNET_A
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Subnet B Name    (SUBNET_B)       : ${RESET_FORMAT}" SUBNET_B
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 1  (FWL_1)          : ${RESET_FORMAT}" FWL_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 2  (FWL_2)          : ${RESET_FORMAT}" FWL_2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 3  (FWL_3)          : ${RESET_FORMAT}" FWL_3
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 1           (ZONE_1)         : ${RESET_FORMAT}" ZONE_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 2           (ZONE_2)         : ${RESET_FORMAT}" ZONE_2

export REGION_1=${ZONE_1%-*}
export REGION_2=${ZONE_2%-*}
export VM_1=us-test-01
export VM_2=us-test-02

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating VPC Network...${RESET_FORMAT}"
gcloud compute networks create $VPC_NAME \
    --project=$DEVSHELL_PROJECT_ID \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating Subnet A...${RESET_FORMAT}"
gcloud compute networks subnets create $SUBNET_A \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION_1 \
    --network=$VPC_NAME \
    --range=10.10.10.0/24 \
    --stack-type=IPV4_ONLY

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating Subnet B...${RESET_FORMAT}"
gcloud compute networks subnets create $SUBNET_B \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION_2 \
    --network=$VPC_NAME \
    --range=10.10.20.0/24 \
    --stack-type=IPV4_ONLY

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating Firewall Rule 1 (SSH)...${RESET_FORMAT}"
gcloud compute firewall-rules create $FWL_1 \
    --project=$DEVSHELL_PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=0.0.0.0/0

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating Firewall Rule 2 (RDP)...${RESET_FORMAT}"
gcloud compute firewall-rules create $FWL_2 \
    --project=$DEVSHELL_PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=65535 \
    --action=ALLOW \
    --rules=tcp:3389 \
    --source-ranges=0.0.0.0/0

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating Firewall Rule 3 (ICMP)...${RESET_FORMAT}"
gcloud compute firewall-rules create $FWL_3 \
    --project=$DEVSHELL_PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=10.10.10.0/24,10.10.20.0/24

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating VM 1 (us-test-01) in $ZONE_1...${RESET_FORMAT}"
gcloud compute instances create $VM_1 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_1 \
    --subnet=$SUBNET_A

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating VM 2 (us-test-02) in $ZONE_2...${RESET_FORMAT}"
gcloud compute instances create $VM_2 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_2 \
    --subnet=$SUBNET_B

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}>>> Waiting 10 seconds for VMs to initialize...${RESET_FORMAT}"
sleep 10

# Get internal IP of VM_2
export INTERNAL_IP2=$(gcloud compute instances describe $VM_2 \
    --zone=$ZONE_2 \
    --format='get(networkInterfaces[0].networkIP)')
echo "${GREEN_TEXT}Internal IP of $VM_2: $INTERNAL_IP2${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Testing connectivity from $VM_1 to $VM_2...${RESET_FORMAT}"
gcloud compute ssh $VM_1 \
    --zone=$ZONE_1 \
    --project=$DEVSHELL_PROJECT_ID \
    --quiet \
    --command="ping -c 3 $INTERNAL_IP2 && ping -c 3 $VM_2.$ZONE_2"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
