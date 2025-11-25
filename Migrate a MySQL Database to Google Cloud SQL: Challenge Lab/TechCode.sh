#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

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

gcloud auth login --no-launch-browser  

echo "${BLUE_TEXT}${BOLD_TEXT}Waiting for VM 'blog' to be ready...${RESET_FORMAT}"

while true; do
    VM=$(gcloud compute instances list --filter="name=blog" --format="value(name)")
    if [[ "$VM" == "blog" ]]; then
        echo "${GREEN_TEXT}VM 'blog' is ready!${RESET_FORMAT}"
        break
    fi
    echo "${YELLOW_TEXT}VM not ready yet... retrying in 5 seconds${RESET_FORMAT}"
    sleep 5
done

# ===========================================
# AUTO-DETECT ZONE & REGION
# ===========================================
export ZONE=$(gcloud compute instances list --filter="name=blog" --format="value(zone)")
export REGION="${ZONE%-*}"

echo "${GREEN_TEXT}Detected ZONE: ${YELLOW_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Detected REGION: ${YELLOW_TEXT}$REGION${RESET_FORMAT}"

# ===========================================
# CREATE CLOUD SQL INSTANCE
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud SQL instance 'wordpress'...${RESET_FORMAT}"

gcloud sql instances create wordpress \
  --tier=db-n1-standard-1 \
  --activation-policy=ALWAYS \
  --region=$REGION

echo "${GREEN_TEXT}Cloud SQL instance 'wordpress' created.${RESET_FORMAT}"

echo "${BLUE_TEXT}Setting root password...${RESET_FORMAT}"

gcloud sql users set-password root \
  --host=% \
  --instance=wordpress \
  --password="Password1*"

# ===========================================
# AUTHORIZE BLOG VM TO ACCESS CLOUD SQL
# ===========================================
BLOG_IP=$(gcloud compute instances describe blog --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

gcloud sql instances patch wordpress \
  --authorized-networks=${BLOG_IP}/32 \
  --quiet

echo "${GREEN_TEXT}Authorized blog VM IP: ${YELLOW_TEXT}$BLOG_IP${RESET_FORMAT}"

# ===========================================
# GET CLOUD SQL PUBLIC IP
# ===========================================
SQL_IP=$(gcloud sql instances describe wordpress --format="value(ipAddresses.ipAddress)")

echo "${GREEN_TEXT}Cloud SQL Public IP: ${YELLOW_TEXT}$SQL_IP${RESET_FORMAT}"

# ===========================================
# CREATE VM MIGRATION SCRIPT
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Preparing migration script for VM...${RESET_FORMAT}"

cat > prepare_disk.sh <<EOF
#!/bin/bash

sudo apt-get update
sudo apt-get install -y mariadb-client

SQL_IP="$SQL_IP"

# Create DB + user
mariadb -h \$SQL_IP -u root -pPassword1* <<SQL_EOF
CREATE DATABASE wordpress;
CREATE USER 'blogadmin'@'%' IDENTIFIED BY 'Password1*';
GRANT ALL PRIVILEGES ON wordpress.* TO 'blogadmin'@'%';
FLUSH PRIVILEGES;
SQL_EOF

# Dump local DB
sudo mysqldump -u blogadmin -pPassword1* wordpress > /tmp/wp.sql

# Import into Cloud SQL
mariadb -h \$SQL_IP -u root -pPassword1* wordpress < /tmp/wp.sql

# Update WordPress config
cd /var/www/html/wordpress

sudo sed -i "s/'DB_USER',.*/'DB_USER', 'blogadmin')/" wp-config.php
sudo sed -i "s/'DB_PASSWORD',.*/'DB_PASSWORD', 'Password1*')/" wp-config.php
sudo sed -i "s/'DB_HOST',.*/'DB_HOST', '\$SQL_IP')/" wp-config.php

sudo service apache2 restart
EOF

echo "${GREEN_TEXT}Migration script created successfully.${RESET_FORMAT}"

# ===========================================
# COPY SCRIPT TO VM & EXECUTE
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Copying script to VM...${RESET_FORMAT}"
gcloud compute scp prepare_disk.sh blog:/tmp --zone=$ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Executing migration on VM...${RESET_FORMAT}"
gcloud compute ssh blog --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
