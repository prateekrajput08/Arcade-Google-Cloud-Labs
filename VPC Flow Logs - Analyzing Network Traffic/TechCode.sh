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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ------------------------------------------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Checking current gcloud authentication...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud auth list


# ------------------------------------------------------
echo "${MAGENTA_TEXT}${BOLD_TEXT}👉 Fetching ZONE and REGION automatically...${RESET_FORMAT}"
# ------------------------------------------------------
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


# ------------------------------------------------------
echo "${GREEN_TEXT}${BOLD_TEXT}👉 Creating VPC Network vpc-net...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute networks create vpc-net --project=$DEVSHELL_PROJECT_ID --description="Subscribe to Dr. Abhishek's YouTube Channel" --subnet-mode=custom


# ------------------------------------------------------
echo "${LIME_TEXT}${BOLD_TEXT}👉 Creating VPC Subnet vpc-subnet with custom range...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute networks subnets create vpc-subnet --project=$DEVSHELL_PROJECT_ID --network=vpc-net --region=$REGION --range=10.1.3.0/24 --enable-flow-logs


echo "${TEAL_TEXT}${BOLD_TEXT}⏳ Waiting 100 seconds for network propagation...${RESET_FORMAT}"
sleep 100


# ------------------------------------------------------
echo "${BLUE_TEXT}${BOLD_TEXT}👉 Creating Firewall Rule allow-http-ssh...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute firewall-rules create allow-http-ssh \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=vpc-net \
  --action=ALLOW \
  --rules=tcp:80,tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server


# ------------------------------------------------------
echo "${GOLD_TEXT}${BOLD_TEXT}👉 Creating Apache Web Server VM: web-server...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute instances create web-server \
  --zone=$ZONE \
  --project=$DEVSHELL_PROJECT_ID \
  --machine-type=e2-micro \
  --subnet=vpc-subnet \
  --tags=http-server \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    sudo apt update
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo systemctl enable apache2' \
  --labels=server=apache


# ------------------------------------------------------
echo "${GREEN_TEXT}${BOLD_TEXT}👉 Adding alternate HTTP firewall rule...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute firewall-rules create allow-http-alt \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP traffic on alternate rule"


# ------------------------------------------------------
echo "${CYAN_TEXT}${BOLD_TEXT}👉 Creating BigQuery dataset for VPC Flow Logs...${RESET_FORMAT}"
# ------------------------------------------------------
bq mk bq_vpcflows


# ------------------------------------------------------
echo "${PURPLE_TEXT}${BOLD_TEXT}👉 Fetching Public IP of web-server...${RESET_FORMAT}"
# ------------------------------------------------------
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
export MY_SERVER=$CP_IP


# ------------------------------------------------------
echo "${RED_TEXT}${BOLD_TEXT}👉 Generating sample traffic (50 HTTP requests)...${RESET_FORMAT}"
# ------------------------------------------------------
for ((i=1;i<=50;i++)); do curl $MY_SERVER; done


echo
echo -e "\e[1;33mEdit Firewall\e[0m \e[1;34mhttps://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-http-ssh?project=$DEVSHELL_PROJECT_ID\e[0m"
echo
echo -e "\e[1;33mCreate an export sink\e[0m \e[1;34mhttps://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_subnetwork%22%0Alog_name%3D%22projects%2F$DEVSHELL_PROJECT_ID%2Flogs%2Fcompute.googleapis.com%252Fvpc_flows%22;cursorTimestamp=2024-06-03T07:20:00.734122029Z;duration=PT1H?project=$DEVSHELL_PROJECT_ID\e[0m"
echo


# ------------------------------------------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Asking user to continue...${RESET_FORMAT}"
# ------------------------------------------------------
while true; do
    echo -ne "\e[1;93mDo you Want to proceed? (Y/n): \e[0m"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo -e "\e[34mRunning the command...\e[0m"
            break
            ;;
        [Nn]|"") 
            echo "Operation canceled."
            break
            ;;
        *) 
            echo -e "\e[31mInvalid input. Please enter Y or N.\e[0m" 
            ;;
    esac
done


# ------------------------------------------------------
echo "${RED_TEXT}${BOLD_TEXT}👉 Generating more sample traffic (50 requests x 2)...${RESET_FORMAT}"
# ------------------------------------------------------
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
export MY_SERVER=$CP_IP
for ((i=1;i<=50;i++)); do curl $MY_SERVER; done

CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
export MY_SERVER=$CP_IP
for ((i=1;i<=50;i++)); do curl $MY_SERVER; done


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
