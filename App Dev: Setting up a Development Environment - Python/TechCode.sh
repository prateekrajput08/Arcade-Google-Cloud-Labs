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

echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo -ne "${YELLOW_TEXT}Enter your zone: ${RESET_FORMAT}"
read ZONE                          # ← capital ZONE now, matches usage below

if [ -z "$ZONE" ]; then
  echo -e "${YELLOW_TEXT}No zone entered. Please try again.${RESET_FORMAT}"
  exit 1
fi

echo -e "${YELLOW_TEXT}You entered zone: $ZONE${RESET_FORMAT}"

gcloud auth list

export ZONE                        # ← export so child processes see it
export REGION=${ZONE%-*}
export PROJECT_ID=$DEVSHELL_PROJECT_ID

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

gcloud compute instances create dev-instance \
  --project="$DEVSHELL_PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=http-server \
  --create-disk=auto-delete=yes,boot=yes,image=projects/debian-cloud/global/images/family/debian-11,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Firewall rule may already exist — ignore that error
gcloud compute firewall-rules create allow-http \
  --action=ALLOW \
  --direction=INGRESS \
  --description="Allow HTTP traffic" \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server 2>/dev/null || echo "Firewall rule already exists, skipping."

sleep 30   # ← give the VM more time to fully boot before SSH

cat > techcode.sh <<'EOF_CP'
sudo apt-get update
sudo apt-get install git -y
sudo apt-get install python3-setuptools python3-dev build-essential -y
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py --break-system-packages
python3 --version
pip3 --version
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
ln -s ~/training-data-analyst/courses/developingapps/v1.3/python/devenv ~/devenv
cd ~/devenv/
sudo pip3 install -r requirements.txt --break-system-packages
EOF_CP

sleep 10

gcloud compute scp techcode.sh dev-instance:/tmp \
  --project="$DEVSHELL_PROJECT_ID" \
  --zone="$ZONE" \
  --quiet

gcloud compute ssh dev-instance \
  --project="$DEVSHELL_PROJECT_ID" \
  --zone="$ZONE" \
  --quiet \
  --command='bash /tmp/TechCode.sh'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
