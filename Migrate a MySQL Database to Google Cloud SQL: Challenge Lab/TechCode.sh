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


ZONE="ZONE"
REGION="${ZONE%-*}"

echo "${GREEN_TEXT}Using ZONE: $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Using REGION: $REGION${RESET_FORMAT}"

# ===========================================
# TASK 1 — Create Cloud SQL Instance
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud SQL instance...${RESET_FORMAT}"

gcloud sql instances create wordpress \
  --tier=db-n1-standard-1 \
  --activation-policy=ALWAYS \
  --region=$REGION

echo "${GREEN_TEXT}Cloud SQL instance created.${RESET_FORMAT}"

echo "${BLUE_TEXT}Setting root password...${RESET_FORMAT}"
gcloud sql users set-password root \
  --host=% \
  --instance=wordpress \
  --password="Password1*"

# Authorize VM to access Cloud SQL
echo "${BLUE_TEXT}Authorizing VM IP...${RESET_FORMAT}"

ADDRESS=$(gcloud compute instances describe blog \
  --zone=$ZONE \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")/32

gcloud sql instances patch wordpress \
  --authorized-networks=$ADDRESS \
  --quiet

echo "${GREEN_TEXT}Authorized networks updated.${RESET_FORMAT}"

# ===========================================
# CREATE REMOTE SCRIPT
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Preparing migration script for VM...${RESET_FORMAT}"

cat > prepare_disk.sh <<'EOF'
#!/bin/bash

sudo apt-get update
sudo apt-get install -y mysql-client

# Get Cloud SQL public IP
MYSQLIP=$(gcloud sql instances describe wordpress --format="value(ipAddresses.ipAddress)")

# Create DB + user inside Cloud SQL
mysql --host=$MYSQLIP --user=root -pPassword1* <<SQL_EOF
CREATE DATABASE wordpress;
CREATE USER 'blogadmin'@'%' IDENTIFIED BY 'Password1*';
GRANT ALL PRIVILEGES ON wordpress.* TO 'blogadmin'@'%';
FLUSH PRIVILEGES;
SQL_EOF

# Dump local MySQL database
sudo mysqldump -u blogadmin -pPassword1* wordpress > /tmp/wordpress_backup.sql

# Import into Cloud SQL
mysql --host=$MYSQLIP --user=root -pPassword1* wordpress < /tmp/wordpress_backup.sql

# Update wp-config.php
cd /var/www/html/wordpress

sudo sed -i "s/define('DB_USER', .*)/define('DB_USER', 'blogadmin')/" wp-config.php
sudo sed -i "s/define('DB_PASSWORD', .*)/define('DB_PASSWORD', 'Password1*')/" wp-config.php
sudo sed -i "s/define('DB_HOST', .*)/define('DB_HOST', '$MYSQLIP')/" wp-config.php

sudo service apache2 restart
EOF

echo "${GREEN_TEXT}Migration script created.${RESET_FORMAT}"

# ===========================================
# COPY SCRIPT TO VM & RUN IT
# ===========================================
echo "${BLUE_TEXT}${BOLD_TEXT}Copying script to VM...${RESET_FORMAT}"

gcloud compute scp prepare_disk.sh blog:/tmp \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Executing migration on VM...${RESET_FORMAT}"

gcloud compute ssh blog \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE --quiet \
  --command="bash /tmp/prepare_disk.sh"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
