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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud auth login --quiet

# Step 1: Set Compute Zone & Region
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting Compute Zone & Region${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Configure Compute Settings
echo "${BOLD_TEXT}${YELLOW_TEXT}Configuring Compute Settings${RESET_FORMAT}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Step 3: Create lab-1 Instance
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating lab-1 VM instance${RESET_FORMAT}"
gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2

# Step 4: Choose a new zone in the same region
echo "${BOLD_TEXT}${YELLOW_TEXT}Selecting a new zone in same region${RESET_FORMAT}"
export NEWZONE=$(gcloud compute zones list --filter="name~'^$REGION'" \
  --format="value(name)" | grep -v "^$ZONE$" | head -n 1)

# Step 5: Set new zone in gcloud config
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting new zone in gcloud config${RESET_FORMAT}"
gcloud config set compute/zone $NEWZONE

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD_TEXT}${YELLOW_TEXT}Have you checked your progress for Task 1 ? (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD_TEXT}${GREEN_TEXT}Great! Proceeding to the next steps...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD_TEXT}${RED_TEXT}Please check your progress for Task 1 and then press Y to continue.${RESET_FORMAT}"
        else
            echo
            echo "${BOLD_TEXT}${YELLOW_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 6: Create a new gcloud config for user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating a new gcloud config for user2${RESET_FORMAT}"
gcloud config configurations create user2 --quiet

# Step 7: Authenticate user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Authenticating user2${RESET_FORMAT}"
gcloud auth login --no-launch-browser --quiet

# Step 8: Set default project/zone/region for user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting project, zone, region for user2${RESET_FORMAT}"
gcloud config set project $(gcloud config get-value project --configuration=default) --configuration=user2
gcloud config set compute/zone $(gcloud config get-value compute/zone --configuration=default) --configuration=user2
gcloud config set compute/region $(gcloud config get-value compute/region --configuration=default) --configuration=user2

# Step 9: Switch back to default config
echo "${BOLD_TEXT}${YELLOW_TEXT}Switching back to default config${RESET_FORMAT}"
gcloud config configurations activate default

# Step 10: Install dependencies
echo "${BOLD_TEXT}${YELLOW_TEXT}Installing epel-release and jq${RESET_FORMAT}"
sudo yum -y install epel-release
sudo yum -y install jq

echo

# Step 11: Prompt for input values and export
echo "${BOLD_TEXT}${YELLOW_TEXT}Prompting for PROJECTID2, USERID2, and ZONE2${RESET_FORMAT}"
echo
get_and_export_values() {
  # Prompt user for PROJECTID2
echo -n "${BOLD_TEXT}${YELLOW_TEXT}Enter the PROJECTID2: ${RESET_FORMAT}"
read PROJECTID2
echo

# Prompt user for USERID2
echo -n "${BOLD_TEXT}${YELLOW_TEXT}Enter the USERID2: ${RESET_FORMAT}"
read USERID2
echo

# Prompt user for ZONE2
echo -n "${BOLD_TEXT}${YELLOW_TEXT}Enter the ZONE2: ${RESET_FORMAT}"
read ZONE2
echo

  # Export the values in the current session
  export PROJECTID2
  export USERID2
  export ZONE2

  # Append the export statements to ~/.bashrc with actual values
  echo "export PROJECTID2=$PROJECTID2" >> ~/.bashrc
  echo "export USERID2=$USERID2" >> ~/.bashrc
  echo "export ZONE2=$ZONE2" >> ~/.bashrc
}

get_and_export_values

echo

# Step 12: Grant viewer role to user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Granting viewer role to user2${RESET_FORMAT}"
. ~/.bashrc
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/viewer

# Step 13: Switch to user2 config
echo "${BOLD_TEXT}${YELLOW_TEXT}Switching to user2 config${RESET_FORMAT}"
gcloud config configurations activate user2

# Step 14: Set project for user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting project for user2${RESET_FORMAT}"
gcloud config set project $PROJECTID2

# Step 14: Switch to default config again
echo "${BOLD_TEXT}${YELLOW_TEXT}Switching to default config${RESET_FORMAT}"
gcloud config configurations activate default

# Step 15: Create custom role devops
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating custom IAM role 'devops'${RESET_FORMAT}"
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"

# Step 16: Assign roles to user2
echo "${BOLD_TEXT}${YELLOW_TEXT}Assigning IAM roles to user2${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=projects/$PROJECTID2/roles/devops

# Step 17: Switch to user2 config again
echo "${BOLD_TEXT}${YELLOW_TEXT}Switching to user2 config${RESET_FORMAT}"
gcloud config configurations activate user2

# Step 18: Create lab-2 instance
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating lab-2 VM instance${RESET_FORMAT}"
gcloud compute instances create lab-2 --zone $ZONE2 --machine-type=e2-standard-2

# Step 19: Switch to default config
echo "${BOLD_TEXT}${YELLOW_TEXT}Switching to default config${RESET_FORMAT}"
gcloud config configurations activate default

# Step 20: Set project to PROJECTID2
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting project to PROJECTID2${RESET_FORMAT}"
gcloud config set project $PROJECTID2

# Step 21: Create service account named devops
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating service account 'devops'${RESET_FORMAT}"

# FIX: prevent error if already exist
gcloud iam service-accounts create devops --display-name devops || true

# Step 22: Get service account email
echo "${BOLD_TEXT}${YELLOW_TEXT}Retrieving service account email${RESET_FORMAT}"
SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

# Step 23: Grant service account ro
echo "${BOLD_TEXT}${YELLOW_TEXT}Granting IAM roles to service account${RESET_FORMAT}"

# FIX: safer quoting
gcloud projects add-iam-policy-binding $PROJECTID2 --member="serviceAccount:$SA" --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECTID2 --member="serviceAccount:$SA" --role=roles/compute.instanceAdmin

# Step 24: Create lab-3 instance with service account
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating lab-3 VM instance using service account${RESET_FORMAT}"
gcloud compute instances create lab-3 --zone $ZONE2 --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"

echo

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
