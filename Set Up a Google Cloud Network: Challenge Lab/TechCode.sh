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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter VPC Network Name (VPC_NAME)  : ${RESET_FORMAT}" VPC_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Subnet A Name    (SUBNET_A)  : ${RESET_FORMAT}" SUBNET_A
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Subnet B Name    (SUBNET_B)  : ${RESET_FORMAT}" SUBNET_B
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 1  (FWL_1)     : ${RESET_FORMAT}" FWL_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 2  (FWL_2)     : ${RESET_FORMAT}" FWL_2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Firewall Rule 3  (FWL_3)     : ${RESET_FORMAT}" FWL_3
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 1           (ZONE_1)    : ${RESET_FORMAT}" ZONE_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 2           (ZONE_2)    : ${RESET_FORMAT}" ZONE_2

export REGION_1=${ZONE_1%-*}
export REGION_2=${ZONE_2%-*}
export VM_1=us-test-01
export VM_2=us-test-02

#----------------------------------------------------network--------------------------------------------------#

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

#----------------------------------------------------VM helper--------------------------------------------------#

# All e2 machine types from smallest to largest for best availability
MACHINE_TYPES=("e2-micro" "e2-small" "e2-medium" "e2-standard-2" "e2-standard-4" "n1-standard-1" "n2-standard-2")

create_vm() {
    local VM_NAME=$1
    local SUBNET=$2
    local PRIMARY_ZONE=$3
    local REGION=${PRIMARY_ZONE%-*}

    # Check if VM already exists anywhere
    echo "${YELLOW_TEXT}Checking if $VM_NAME already exists...${RESET_FORMAT}"
    EXISTING_ZONE=$(gcloud compute instances list \
        --filter="name=$VM_NAME" \
        --format="get(zone)" 2>/dev/null | awk -F'/' '{print $NF}')

    if [[ -n "$EXISTING_ZONE" ]]; then
        echo "${GREEN_TEXT}${BOLD_TEXT}$VM_NAME already exists in $EXISTING_ZONE. Skipping.${RESET_FORMAT}"
        # Return just the zone as last line
        echo "$EXISTING_ZONE"
        return 0
    fi

    # Build zone list: primary zone first, then all other UP zones in region
    echo "${YELLOW_TEXT}Fetching available zones in $REGION...${RESET_FORMAT}"
    ZONE_LIST=("$PRIMARY_ZONE")
    while IFS= read -r z; do
        [[ "$z" != "$PRIMARY_ZONE" ]] && ZONE_LIST+=("$z")
    done <<< "$(gcloud compute zones list \
        --filter="region:$REGION AND status:UP" \
        --format="get(name)" 2>/dev/null)"

    echo "${YELLOW_TEXT}Will try zones: ${ZONE_LIST[*]}${RESET_FORMAT}"

    for ZONE_TRY in "${ZONE_LIST[@]}"; do
        for MTYPE in "${MACHINE_TYPES[@]}"; do
            echo "${YELLOW_TEXT}Trying zone: $ZONE_TRY | machine-type: $MTYPE ...${RESET_FORMAT}"
            ERR=$(gcloud compute instances create "$VM_NAME" \
                --project="$DEVSHELL_PROJECT_ID" \
                --zone="$ZONE_TRY" \
                --machine-type="$MTYPE" \
                --subnet="$SUBNET" 2>&1)
            EXIT_CODE=$?

            if echo "$ERR" | grep -qE "ZONE_RESOURCE_POOL_EXHAUSTED|does not have enough resources"; then
                echo "${RED_TEXT}  ✗ Zone/type exhausted. Trying next...${RESET_FORMAT}"
                continue

            elif echo "$ERR" | grep -q "already exists"; then
                echo "${GREEN_TEXT}${BOLD_TEXT}  ✓ $VM_NAME already exists. Skipping.${RESET_FORMAT}"
                echo "$ZONE_TRY"
                return 0

            elif [ $EXIT_CODE -eq 0 ]; then
                echo "${GREEN_TEXT}${BOLD_TEXT}  ✓ SUCCESS: $VM_NAME created in $ZONE_TRY with $MTYPE${RESET_FORMAT}"
                echo "$ZONE_TRY"
                return 0

            else
                echo "${RED_TEXT}  ✗ Unexpected error in $ZONE_TRY/$MTYPE — skipping zone.${RESET_FORMAT}"
                echo "${RED_TEXT}    $ERR${RESET_FORMAT}"
                break  # skip remaining machine types for this zone, try next zone
            fi
        done
    done

    echo "${RED_TEXT}${BOLD_TEXT}ERROR: Could not create $VM_NAME in any zone in region $REGION.${RESET_FORMAT}"
    return 1
}

#----------------------------------------------------create VMs--------------------------------------------------#

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating VM 1 ($VM_1) in region $REGION_1...${RESET_FORMAT}"
RESULT_1=$(create_vm "$VM_1" "$SUBNET_A" "$ZONE_1")
if [ $? -ne 0 ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Could not create $VM_1. Exiting.${RESET_FORMAT}"
    exit 1
fi
ZONE_1=$(echo "$RESULT_1" | tail -1)
echo "${GREEN_TEXT}${BOLD_TEXT}$VM_1 is running in zone: $ZONE_1${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}>>> Creating VM 2 ($VM_2) in region $REGION_2...${RESET_FORMAT}"
RESULT_2=$(create_vm "$VM_2" "$SUBNET_B" "$ZONE_2")
if [ $? -ne 0 ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Could not create $VM_2. Exiting.${RESET_FORMAT}"
    exit 1
fi
ZONE_2=$(echo "$RESULT_2" | tail -1)
echo "${GREEN_TEXT}${BOLD_TEXT}$VM_2 is running in zone: $ZONE_2${RESET_FORMAT}"

#----------------------------------------------------connectivity test--------------------------------------------------#

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}>>> Waiting 15 seconds for VMs to initialize...${RESET_FORMAT}"
sleep 15

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

#----------------------------------------------------done--------------------------------------------------#

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
