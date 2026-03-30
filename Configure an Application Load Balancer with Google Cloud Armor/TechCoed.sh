#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Please set the below values correctly${RESET_FORMAT}"
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION1 (e.g., us-central1): ${RESET_FORMAT}" REGION1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION2 (e.g., us-east4): ${RESET_FORMAT}" REGION2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the VM_ZONE (e.g., europe-west1-b): ${RESET_FORMAT}" VM_ZONE

export REGION1 REGION2 VM_ZONE
DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Firewall Rules...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-http --project=$DEVSHELL_PROJECT_ID --direction=INGRESS --priority=1000 --network=default --source-ranges=0.0.0.0/0 --target-tags=http-server --action=ALLOW --rules=tcp:80 
gcloud compute firewall-rules create default-allow-health-check --project=$DEVSHELL_PROJECT_ID --direction=INGRESS --priority=1000 --network=default --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server --action=ALLOW --rules=tcp

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Instance Templates...${RESET_FORMAT}"
gcloud compute instance-templates create $REGION1-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://spls/gsp215/gcpnet/httplb/startup.sh --region=$REGION1 --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image-family=debian-11,image-project=debian-cloud,mode=rw,size=10,type=pd-balanced

gcloud compute instance-templates create $REGION2-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://spls/gsp215/gcpnet/httplb/startup.sh --region=$REGION2 --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image-family=debian-11,image-project=debian-cloud,mode=rw,size=10,type=pd-balanced

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Managed Instance Groups...${RESET_FORMAT}"
gcloud compute instance-groups managed create $REGION1-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION1-mig --size=1 --template=$REGION1-template --region=$REGION1
gcloud compute instance-groups managed set-autoscaling $REGION1-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION1 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --target-cpu-utilization=0.8
gcloud compute instance-groups managed set-named-ports $REGION1-mig --named-ports=http:80 --region=$REGION1

gcloud compute instance-groups managed create $REGION2-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION2-mig --size=1 --template=$REGION2-template --region=$REGION2
gcloud compute instance-groups managed set-autoscaling $REGION2-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION2 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --target-cpu-utilization=0.8
gcloud compute instance-groups managed set-named-ports $REGION2-mig --named-ports=http:80 --region=$REGION2

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Global Application Load Balancer...${RESET_FORMAT}"
gcloud compute health-checks create tcp http-health-check --port=80 --project=$DEVSHELL_PROJECT_ID

gcloud compute backend-services create http-backend \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=http-health-check \
    --global \
    --enable-logging \
    --logging-sample-rate=1 \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute backend-services add-backend http-backend \
    --instance-group=$REGION1-mig \
    --instance-group-region=$REGION1 \
    --global \
    --balancing-mode=RATE \
    --max-rate-per-instance=50 \
    --capacity-scaler=1.0 \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute backend-services add-backend http-backend \
    --instance-group=$REGION2-mig \
    --instance-group-region=$REGION2 \
    --global \
    --balancing-mode=UTILIZATION \
    --max-utilization=0.8 \
    --capacity-scaler=1.0 \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute url-maps create http-lb --default-service=http-backend --project=$DEVSHELL_PROJECT_ID
gcloud compute target-http-proxies create http-lb-target-proxy --url-map=http-lb --project=$DEVSHELL_PROJECT_ID

gcloud compute forwarding-rules create http-lb-forwarding-rule \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --global \
    --target-http-proxy=http-lb-target-proxy \
    --ports=80 \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute forwarding-rules create http-lb-forwarding-rule-2 \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --global \
    --target-http-proxy=http-lb-target-proxy \
    --ports=80 \
    --ip-version=IPV6 \
    --project=$DEVSHELL_PROJECT_ID

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Siege Test VM...${RESET_FORMAT}"
gcloud compute instances create siege-vm --project=$DEVSHELL_PROJECT_ID --zone=$VM_ZONE --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image-family=debian-11,image-project=debian-cloud,mode=rw,size=10,type=pd-balanced
sleep 15
export EXTERNAL_IP=$(gcloud compute instances describe siege-vm --zone=$VM_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)" --project=$DEVSHELL_PROJECT_ID)

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Cloud Armor Policy...${RESET_FORMAT}"
gcloud compute security-policies create denylist-siege \
    --description="Deny traffic from siege-vm" \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute security-policies rules create 1000 \
    --security-policy=denylist-siege \
    --src-ip-ranges=$EXTERNAL_IP \
    --action=deny-403 \
    --project=$DEVSHELL_PROJECT_ID

gcloud compute backend-services update http-backend \
    --security-policy=denylist-siege \
    --global \
    --project=$DEVSHELL_PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting 90 seconds for IPs to propagate before testing...${RESET_FORMAT}"
sleep 90

echo "${BLUE_TEXT}${BOLD_TEXT}Running Siege Test on Load Balancer...${RESET_FORMAT}"
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)" --project=$DEVSHELL_PROJECT_ID)
gcloud compute ssh siege-vm --zone=$VM_ZONE --project=$DEVSHELL_PROJECT_ID --quiet --command="sudo apt-get -y update && sudo apt-get -y install siege && export LB_IP=$LB_IP_ADDRESS && siege -c 150 -t 15s http://\$LB_IP"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
