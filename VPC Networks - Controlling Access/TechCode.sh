
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

# ------------------ ASK FOR ZONE ------------------
echo "${YELLOW}${BOLD}Enter zone (e.g., us-central1-a):${RESET}"
read ZONE
export ZONE

echo "${CYAN}${BOLD}Creating Blue & Green servers...${RESET}"

# ------------------ CREATE BLUE SERVER (TAGGED) ------------------
gcloud compute instances create blue \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --tags=web-server \
  --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced \
  --quiet

# ------------------ CREATE GREEN SERVER (NO TAG) ------------------
gcloud compute instances create green \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --create-disk=auto-delete=yes,boot=yes,device-name=green,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced \
  --quiet

echo "${GREEN}${BOLD}VMs Created Successfully!${RESET}"

# ------------------ CREATE FIREWALL RULE ------------------
echo "${CYAN}${BOLD}Creating Firewall Rule...${RESET}"

gcloud compute firewall-rules create allow-http-web-server \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --allow=tcp:80,icmp \
  --source-ranges=0.0.0.0/0 \
  --target-tags=web-server \
  --quiet

echo "${GREEN}${BOLD}Firewall Rule Created Successfully!${RESET}"

# ------------------ CREATE TEST VM ------------------
echo "${CYAN}${BOLD}Creating test-vm...${RESET}"

gcloud compute instances create test-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=default \
  --quiet

echo "${GREEN}${BOLD}test-vm Created Successfully!${RESET}"

# ------------------ CREATE SERVICE ACCOUNT ------------------
echo "${CYAN}${BOLD}Creating Service Account & Keys...${RESET}"

gcloud iam service-accounts create network-admin \
  --description="Service account for Network Admin role" \
  --display-name="Network-admin" \
  --quiet

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.networkAdmin \
  --quiet

gcloud iam service-accounts keys create credentials.json \
  --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --quiet

echo "${GREEN}${BOLD}Service Account + Key Created Successfully!${RESET}"

# ------------------ BLUE SERVER NGINX SETUP ------------------
echo "${CYAN}${BOLD}Configuring Blue Server...${RESET}"

cat > bluessh.sh <<'EOF_END'
sudo apt-get update -y
sudo apt-get install nginx-light -y
sudo sed -i '14c\<h1>Welcome to the blue server!</h1>' /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF_END

gcloud compute scp bluessh.sh blue:/tmp --zone=$ZONE --quiet
gcloud compute ssh blue --zone=$ZONE --quiet --command="bash /tmp/bluessh.sh"

# ------------------ GREEN SERVER NGINX SETUP ------------------
echo "${CYAN}${BOLD}Configuring Green Server...${RESET}"

cat > greenssh.sh <<'EOF_END'
sudo apt-get update -y
sudo apt-get install nginx-light -y
sudo sed -i '14c\<h1>Welcome to the green server!</h1>' /var/www/html/index-nginx-debian.html
sudo systemctl restart nginx
EOF_END

gcloud compute scp greenssh.sh green:/tmp --zone=$ZONE --quiet
gcloud compute ssh green --zone=$ZONE --quiet --command="bash /tmp/greenssh.sh"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
