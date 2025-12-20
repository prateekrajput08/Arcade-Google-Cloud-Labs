#!/bin/bash

# ========================= COLOR DEFINITIONS =========================
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

# ========================= TEXT FORMATTING =========================
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# ========================= WELCOME MESSAGE =========================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ========================= SET PROJECT & ZONE =========================
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute zones list --filter="status=UP" --limit=1 --format="value(name)")

echo "${GREEN_TEXT}${BOLD_TEXT}Using Project: $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Using Zone   : $ZONE${RESET_FORMAT}"
echo

# ========================= ENABLE COMPUTE API =========================
gcloud services enable compute.googleapis.com --quiet

# ========================= CREATE VM =========================
gcloud compute instances create my-instance \
    --machine-type=e2-medium \
    --zone=$ZONE \
    --image-project=debian-cloud \
    --image-family=debian-11 \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --create-disk=size=100GB,type=pd-standard,mode=rw,device-name=additional-disk \
    --tags=http-server

# ========================= CREATE & ATTACH DISK =========================
gcloud compute disks create mydisk \
    --size=200GB \
    --zone=$ZONE

gcloud compute instances attach-disk my-instance \
    --disk=mydisk \
    --zone=$ZONE

sleep 30

# ========================= PREPARE SCRIPT =========================
cat > prepare_disk.sh <<'EOF_END'
sudo apt update
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
EOF_END

# ========================= COPY & EXECUTE =========================
gcloud compute scp prepare_disk.sh my-instance:/tmp \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --quiet

gcloud compute ssh my-instance \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="bash /tmp/prepare_disk.sh"

# ========================= FINAL MESSAGE =========================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
