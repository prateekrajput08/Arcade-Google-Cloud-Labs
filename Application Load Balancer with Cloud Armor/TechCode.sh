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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          INITIATING EXECUTION     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the first REGION: ${RESET_FORMAT}" REGION1
echo "${GREEN_TEXT}${BOLD_TEXT}First REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the second REGION: ${RESET_FORMAT}" REGION2
echo "${GREEN_TEXT}${BOLD_TEXT}Second REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the VM_ZONE: ${RESET_FORMAT}" VM_ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}VM_ZONE set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$VM_ZONE${RESET_FORMAT}"
echo

# Export variables after collecting input
export REGION1 REGION2 VM_ZONE

export INSTANCE_NAME=$REGION1-mig
export INSTANCE_NAME_2=$REGION2-mig

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring firewall rule to permit incoming HTTP traffic...${RESET_FORMAT}"
echo
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up firewall rule to allow health check probes...${RESET_FORMAT}"
echo
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating instance template for the first region: ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud compute instance-templates create $REGION1-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION1 --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating instance template for the second region: ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud compute instance-templates create $REGION2-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION2 --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Establishing managed instance group and enabling autoscaling for region: ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud beta compute instance-groups managed create $REGION1-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION1-mig --size=1 --template=$REGION1-template --region=$REGION1 --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling $REGION1-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION1 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Establishing managed instance group and enabling autoscaling for region: ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud beta compute instance-groups managed create $REGION2-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION2-mig --size=1 --template=$REGION2-template --region=$REGION2 --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION2 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8
echo

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

echo "${RED_TEXT}${BOLD_TEXT}Creating corrected Cloud Armor policy...${RESET_FORMAT}"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
        \"name\": \"denylist-siege\",
        \"type\": \"CLOUD_ARMOR\",
        \"rules\": [
            {
                \"priority\": 1000,
                \"action\": \"deny(403)\",
                \"match\": {
                    \"versionedExpr\": \"SRC_IPS_V1\",
                    \"config\": {\"srcIpRanges\": [\"$EXTERNAL_IP\"]}
                }
            }
        ]
     }" \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"

echo "Waiting for policy create..."
sleep 30

echo "${RED_TEXT}${BOLD_TEXT}Attaching Cloud Armor policy using correct PATCH method...${RESET_FORMAT}"

curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
        \"securityPolicy\": \"projects/$DEVSHELL_PROJECT_ID/global/securityPolicies/denylist-siege\"
      }" \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend"

echo "Waiting for enforcement..."
sleep 180

echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
