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

echo "${PURPLE_TEXT}${BOLD_TEXT}# Checking gcloud version${RESET_FORMAT}"
gcloud --version

echo "${PURPLE_TEXT}${BOLD_TEXT}# Authenticating user${RESET_FORMAT}"
gcloud auth login

echo "${PURPLE_TEXT}${BOLD_TEXT}# Fetching default PROJECT, ZONE and REGION${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${GOLD_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo "${GOLD_TEXT}Region: $REGION${RESET_FORMAT}"

echo "${PURPLE_TEXT}${BOLD_TEXT}# Setting gcloud region and zone${RESET_FORMAT}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "${PURPLE_TEXT}${BOLD_TEXT}# Creating first VM instance${RESET_FORMAT}"
gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2

echo "${PURPLE_TEXT}${BOLD_TEXT}# Showing current gcloud config${RESET_FORMAT}"
gcloud config list

echo "${PURPLE_TEXT}${BOLD_TEXT}# Listing available zones in current region${RESET_FORMAT}"
gcloud compute zones list --filter="region:($REGION)" --format="value(name)" | while read -r zone; do
  echo "${GOLD_TEXT}${BOLD_TEXT}$zone${RESET_FORMAT}"
done

read -e -p "${GOLD_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
gcloud config set compute/zone $ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}Zone updated to: $ZONE${RESET_FORMAT}"

cat ~/.config/gcloud/configurations/config_default

echo "${PURPLE_TEXT}${BOLD_TEXT}# Running gcloud init in no-browser mode${RESET_FORMAT}"
gcloud init --no-launch-browser

echo ""
echo "${PURPLE_TEXT}${BOLD_TEXT}# IAM Console link to verify permissions${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/iam-admin/iam?invt=AbutQA&project=$PROJECT_ID${RESET_FORMAT}"
echo ""

# Confirmation loop
while true; do
    echo -ne "${GOLD_TEXT}${BOLD_TEXT}Do you want to proceed? (Y/n): ${RESET_FORMAT}"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo "${BLUE_TEXT}${BOLD_TEXT}Running the command...${RESET_FORMAT}"
            break
            ;;
        [Nn]|"") 
            echo "${RED_TEXT}Operation canceled.${RESET_FORMAT}"
            break
            ;;
        *) 
            echo "${RED_TEXT}${BOLD_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}" 
            ;;
    esac
done

echo "${PURPLE_TEXT}${BOLD_TEXT}# Displaying available IAM roles${RESET_FORMAT}"
gcloud iam roles list | grep "name:"

echo "${PURPLE_TEXT}${BOLD_TEXT}# Showing compute.instanceAdmin role details${RESET_FORMAT}"
gcloud iam roles describe roles/compute.instanceAdmin

read -e -p "${GOLD_TEXT}${BOLD_TEXT}Enter USER2: ${RESET_FORMAT}" USER2
read -e -p "${GOLD_TEXT}${BOLD_TEXT}Enter PROJECT_ID2: ${RESET_FORMAT}" PROJECT_ID2
read -e -p "${GOLD_TEXT}${BOLD_TEXT}Enter VM ZONE: ${RESET_FORMAT}" ZONE

gcloud config configurations activate user2

echo "${PURPLE_TEXT}${BOLD_TEXT}# Storing PROJECTID2 in bashrc${RESET_FORMAT}"
echo "export PROJECTID2=$PROJECT_ID2" >> ~/.bashrc
source ~/.bashrc

gcloud config configurations activate default

echo "${PURPLE_TEXT}${BOLD_TEXT}# Installing essential tools (epel-release + jq)${RESET_FORMAT}"
sudo yum -y install epel-release
sudo yum -y install jq

echo "export USERID2=$USER2" >> ~/.bashrc
source ~/.bashrc

echo "${PURPLE_TEXT}${BOLD_TEXT}# Assigning viewer role to USER2${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/viewer

gcloud config configurations activate user2
gcloud config set project $PROJECT_ID2

gcloud compute instances list

echo "${PURPLE_TEXT}${BOLD_TEXT}# Creating custom DevOps role${RESET_FORMAT}"
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"

echo "${PURPLE_TEXT}${BOLD_TEXT}# Binding roles to USER2${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=projects/$PROJECT_ID2/roles/devops

gcloud config configurations activate user2

echo "${PURPLE_TEXT}${BOLD_TEXT}# Creating VM using DevOps role${RESET_FORMAT}"
gcloud compute instances create lab-2 --zone $ZONE

gcloud compute instances list

gcloud config configurations activate default
gcloud config set project $PROJECT_ID2

echo "${PURPLE_TEXT}${BOLD_TEXT}# Creating service account (devops)${RESET_FORMAT}"
gcloud iam service-accounts create devops --display-name devops

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

echo "${PURPLE_TEXT}${BOLD_TEXT}# Assigning permissions to service account${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin

echo "${PURPLE_TEXT}${BOLD_TEXT}# Creating VM using service account${RESET_FORMAT}"
gcloud compute instances create lab-3 --zone $ZONE --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
