
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

# Check gcloud version
gcloud --version

# Authenticate
gcloud auth login

# Set environment variables
export PROJECT_ID=$(gcloud config get-value core/project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo $ZONE
echo $REGION

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Create a VM instance
gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2

# Show config
gcloud config list

# Update Region and Zone if needed
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo ""
echo -e "\033[1;33mThis is your current zone: $ZONE.\033[0m" 
echo "You could select a different zone from those listed below:"
echo ""

gcloud compute zones list --filter="region:($REGION)" --format="value(name)" | while read -r zone; do
  echo -e "\033[1;33m$zone\033[0m"
done

read -e -p $'\033[1;33mEnter the ZONE: \033[0m' ZONE

gcloud config set compute/zone $ZONE

echo -e "\033[1;33mNow this is your new zone: $ZONE.\033[0m"

gcloud config list

cat ~/.config/gcloud/configurations/config_default

# Init without browser launch
gcloud init --no-launch-browser

echo ""
echo -e "\033[1;33mOpen this link.\033[0m \033[1;34mhttps://console.cloud.google.com/iam-admin/iam?invt=AbutQA&project=$PROJECT_ID\033[0m"
echo ""

# Confirmation loop
while true; do
    echo -ne "\e[1;93mDo you want to proceed? (Y/n): \e[0m"
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

# IAM role and permissions setup
gcloud iam roles list | grep "name:"
gcloud iam roles describe roles/compute.instanceAdmin

read -e -p $'\033[1;33mEnter the USER2: \033[0m' USER2
read -e -p $'\033[1;33mEnter the PROJECT_ID2: \033[0m' PROJECT_ID2
read -e -p $'\033[1;33mEnter the VM ZONE: \033[0m' ZONE

gcloud config configurations activate user2

echo "export PROJECTID2=$PROJECT_ID2" >> ~/.bashrc
source ~/.bashrc

gcloud config configurations activate default

# Install utilities
sudo yum -y install epel-release
sudo yum -y install jq

echo "export USERID2=$USER2" >> ~/.bashrc
source ~/.bashrc

# Assign viewer role
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/viewer

gcloud config configurations activate user2
gcloud config set project $PROJECT_ID2

gcloud compute instances list

# Optional VM creation
# gcloud compute instances create lab-2 --zone $ZONE 

gcloud config configurations activate default

# Create a custom DevOps role
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"

# Bind IAM roles
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=projects/$PROJECT_ID2/roles/devops

gcloud config configurations activate user2

# Create instance with new role
gcloud compute instances create lab-2 --zone $ZONE

gcloud compute instances list

gcloud config configurations activate default
gcloud config set project $PROJECT_ID2

# Create service account
gcloud iam service-accounts create devops --display-name devops

gcloud iam service-accounts list --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

# Bind service account permissions
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin

# Create instance with service account
export ZONE=$ZONE
gcloud compute instances create lab-3 --zone $ZONE --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
