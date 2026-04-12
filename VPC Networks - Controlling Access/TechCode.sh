
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
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# 1. Ask for Zone and Autofetch Region
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE (e.g., us-central1-a): ${RESET_FORMAT}"
read ZONE
# Strip the last part of the zone (e.g., "-a") to get the region
REGION=${ZONE%-*}
echo -e "${GREEN_TEXT}${BOLD_TEXT}Auto-fetched Region: ${REGION}${RESET_FORMAT}"

# Get the current Project ID
PROJECT_ID=$(gcloud config get-value project)

# --- NEW: Create startup script files locally to avoid metadata escaping errors ---
cat << 'EOF' > blue-startup.sh
#!/bin/bash
apt-get update
apt-get install nginx-light -y
echo "<h1>Welcome to the blue server!</h1><p>If you see this page, the nginx web server is successfully installed and working. Further configuration is required.</p>" > /var/www/html/index.nginx-debian.html
EOF

cat << 'EOF' > green-startup.sh
#!/bin/bash
apt-get update
apt-get install nginx-light -y
echo "<h1>Welcome to the green server!</h1><p>If you see this page, the nginx web server is successfully installed and working. Further configuration is required.</p>" > /var/www/html/index.nginx-debian.html
EOF
# ---------------------------------------------------------------------------------

# 2. Create the web servers (Task 1)
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating 'blue' server with Nginx and web-server tag...${RESET_FORMAT}"
gcloud compute instances create blue \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --tags=web-server \
    --metadata-from-file=startup-script=blue-startup.sh

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating 'green' server with Nginx (no tag)...${RESET_FORMAT}"
gcloud compute instances create green \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --metadata-from-file=startup-script=green-startup.sh

# 3. Create the firewall rule (Task 2)
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating tagged firewall rule 'allow-http-web-server'...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http-web-server \
    --network=default \
    --action=allow \
    --direction=ingress \
    --rules=tcp:80,icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=web-server

echo -e "${YELLOW_TEXT}Creating 'test-vm'...${RESET_FORMAT}"
gcloud compute instances create test-vm \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --subnet=default

# 4. Explore Network and Security Admin roles (Task 3)
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Service Account 'Network-admin'...${RESET_FORMAT}"
gcloud iam service-accounts create Network-admin \
    --display-name="Network-admin"

SA_EMAIL="Network-admin@${PROJECT_ID}.iam.gserviceaccount.com"

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Assigning Compute Network Admin role to the Service Account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.networkAdmin" > /dev/null 2>&1

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Generating JSON key 'credentials.json'...${RESET_FORMAT}"
gcloud iam service-accounts keys create credentials.json \
    --iam-account=${SA_EMAIL}

# Pause for checkpoints
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}====================================================${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}WAIT! Please click 'Check my progress' in the lab manual for:${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Create the blue server${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Create the green server${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Install Nginx and customize the welcome page${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Create the tagged firewall rule${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Create a test-vm${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}- Create a Network-admin service account${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}====================================================${RESET_FORMAT}\n"

read -p "${MAGENTA_TEXT}${BOLD_TEXT}Press [ENTER] once you have collected those points to proceed with the final steps...${RESET_FORMAT}"

# 5. Final Role Swap and Deletion
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Removing Compute Network Admin role...${RESET_FORMAT}"
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.networkAdmin" > /dev/null 2>&1

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Adding Compute Security Admin role...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.securityAdmin" > /dev/null 2>&1

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Waiting 15 seconds for IAM changes to propagate...${RESET_FORMAT}"
sleep 15

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Deleting firewall rule 'allow-http-web-server'...${RESET_FORMAT}"
gcloud compute firewall-rules delete allow-http-web-server --quiet

# Clean up local temporary files
rm blue-startup.sh green-startup.sh
rm -f TechCode.sh

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
