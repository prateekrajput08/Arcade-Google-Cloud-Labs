
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

echo "${YELLOW_TEXT}${BOLD_TEXT}Checking gcloud authentication...${RESET_FORMAT}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
   echo "${RED_TEXT}${BOLD_TEXT}No active login detected.${RESET_FORMAT}"
   echo "${YELLOW_TEXT}Starting browserless login...${RESET_FORMAT}"
   gcloud auth login --no-launch-browser
fi

echo "${YELLOW_TEXT}${BOLD_TEXT}Detecting current project...${RESET_FORMAT}"

PROJECT=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT" ]; then
    read -p "${BOLD_TEXT}Enter Project ID: ${RESET_FORMAT}" PROJECT
    gcloud config set project "$PROJECT"
fi

export PROJECT

echo "${GREEN_TEXT}${BOLD}ACTIVE PROJECT: $PROJECT${RESET_FORMAT}"

if [ -z "$ZONE" ]; then
  echo "${YELLOW}${BOLD}Detecting recommended zone...${RESET_FORMAT}"
  ZONE=$(gcloud compute zones list --format="value(name)" | head -n 1)
  echo "${GREEN_TEXT}Using zone: $ZONE${RESET_FORMAT}"
  gcloud config set compute/zone "$ZONE"
fi
export ZONE

if [ -z "$REGION" ]; then
  REGION=$(echo "$ZONE" | awk -F "-" '{print $1"-"$2}')
  echo "${GREEN_TEXT}Using region: $REGION${RESET_FORMAT}"
  gcloud config set compute/region "$REGION"
fi
export REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Instance lab-1...${RESET_FORMAT}"
gcloud compute instances create lab-1 --zone "$ZONE" --quiet

read -p "${BOLD_TEXT}Enter SECOND USER email (user2): ${RESET_FORMAT}" USER2
export USER2

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating gcloud configuration for user2...${RESET_FORMAT}"
gcloud config configurations create user2 --quiet
gcloud config configurations activate user2 --quiet

echo "${YELLOW_TEXT}Starting login for user2...${RESET_FORMAT}"
gcloud auth login --no-launch-browser

gcloud config configurations activate default --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}Back to admin account.${RESET_FORMAT}"

read -p "${BOLD_TEXT}Enter SECOND PROJECT ID: ${RESET_FORMAT}" PROJECT2
export PROJECT2

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting VIEWER role on $PROJECT2 to $USER2...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding "$PROJECT2" \
  --member=user:"$USER2" \
  --role=roles/viewer --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating custom role: devops${RESET_FORMAT}"

gcloud iam roles create devops \
  --project "$PROJECT2" \
  --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" \
  --quiet

echo "${GREEN_TEXT}Custom role created.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Binding IAM roles to USER2...${RESET_FORMAT}"

gcloud projects add-iam-policy-binding "$PROJECT2" \
  --member=user:"$USER2" \
  --role=roles/iam.serviceAccountUser --quiet

gcloud projects add-iam-policy-binding "$PROJECT2" \
  --member=user:"$USER2" \
  --role=projects/$PROJECT2/roles/devops --quiet

echo "${GREEN_TEXT}${BOLD_TEXT}USER2 now has devops rights on project2.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating service account 'devops'...${RESET_FORMAT}"
gcloud iam service-accounts create devops --display-name devops --project "$PROJECT2" --quiet

SA=$(gcloud iam service-accounts list --project "$PROJECT2" --format="value(email)" --filter="displayName=devops")

echo "${GREEN_TEXT}${BOLD_TEXT}Service Account: $SA${RESET_FORMAT}"

gcloud projects add-iam-policy-binding "$PROJECT2" \
  --member=serviceAccount:"$SA" \
  --role=roles/iam.serviceAccountUser --quiet

gcloud projects add-iam-policy-binding "$PROJECT2" \
  --member=serviceAccount:"$SA" \
  --role=roles/compute.instanceAdmin --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating lab-3 with service account...${RESET_FORMAT}"

gcloud compute instances create lab-3 \
   --zone="$ZONE" \
   --project "$PROJECT2" \
   --service-account "$SA" \
   --scopes="https://www.googleapis.com/auth/compute" --quiet


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
