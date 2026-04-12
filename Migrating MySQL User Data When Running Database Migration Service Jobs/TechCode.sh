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
echo "${CYAN_TEXT}${BOLD_TEXT}            SUBSCRIBE TECH & CODE- INITIATING EXECUTION...        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# User inputs
echo -e "${BOLD_TEXT}${YELLOW_TEXT}Please enter the connection profile details:${RESET_FORMAT}"

read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the region: ${RESET_FORMAT}")" REGION
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the host or IP address: ${RESET_FORMAT}")" HOST_OR_IP
read -s -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter MySQL Password: ${RESET_FORMAT}")" MYSQL_PASS
echo

# Enable APIs
echo -e "${YELLOW_TEXT}Enabling Database Migration API...${RESET_FORMAT}"
gcloud services enable datamigration.googleapis.com --quiet

echo -e "${YELLOW_TEXT}Enabling Service Networking API...${RESET_FORMAT}"
gcloud services enable servicenetworking.googleapis.com --quiet

sleep 5

# ================= MYSQL FIX =================
echo -e "${YELLOW_TEXT}Connecting to MySQL and updating DEFINER...${RESET_FORMAT}"

mysql -h "$HOST_OR_IP" -u admin -p"$MYSQL_PASS" <<EOF
USE sales_data;

DROP VIEW IF EXISTS invoices_storenum_3656;

CREATE SQL SECURITY INVOKER VIEW invoices_storenum_3656 AS
SELECT * FROM invoices WHERE storeNum = 3656;

SELECT definer, security_type, table_schema, table_name 
FROM information_schema.views
WHERE definer NOT LIKE '%mysql%' 
  AND definer NOT LIKE '%debian%'
ORDER BY definer;
EOF

echo -e "${GREEN_TEXT}${BOLD_TEXT}DEFINER updated successfully.${RESET_FORMAT}"

# ================= SOURCE PROFILE =================
CONNECTION_PROFILE_NAME="techcode"
CONNECTION_PROFILE_ID="techcode"

EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)

if [ "$EXISTS" == "" ]; then
  gcloud database-migration connection-profiles create mysql "$CONNECTION_PROFILE_ID" \
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=3306 \
    --username="admin" \
    --password="$MYSQL_PASS"

  echo -e "${GREEN_TEXT}${BOLD_TEXT}Source connection profile created.${NO_COLOR}"
else
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}Source profile already exists.${NO_COLOR}"
fi

# ================= CLOUD SQL =================
echo -e "${YELLOW_TEXT}Creating Cloud SQL instance...${RESET_FORMAT}"

gcloud sql instances create mysql-cloudsql \
  --database-version=MYSQL_8_0 \
  --region="$REGION" \
  --root-password="supersecret!" \
  --tier=db-f1-micro \
  --quiet 2>/dev/null

echo -e "${GREEN_TEXT}${BOLD_TEXT}Cloud SQL instance ready.${RESET_FORMAT}"

# ================= DEST PROFILE =================
DEST_PROFILE_ID="cloudsql-dest"

gcloud database-migration connection-profiles create cloudsql "$DEST_PROFILE_ID" \
  --display-name="cloudsql-destination" \
  --region="$REGION" \
  --cloudsql-instance=mysql-cloudsql \
  --quiet 2>/dev/null

echo -e "${GREEN_TEXT}${BOLD_TEXT}Destination profile ready.${RESET_FORMAT}"

# ================= MIGRATION JOB =================
MIGRATION_JOB_ID="migration-job-1"

gcloud database-migration migration-jobs create "$MIGRATION_JOB_ID" \
  --region="$REGION" \
  --type=one-time \
  --source="$CONNECTION_PROFILE_ID" \
  --destination="$DEST_PROFILE_ID" \
  --quiet 2>/dev/null

echo -e "${GREEN_TEXT}${BOLD_TEXT}Migration job created.${RESET_FORMAT}"

echo -e "${YELLOW_TEXT}Starting migration job...${RESET_FORMAT}"

gcloud database-migration migration-jobs start "$MIGRATION_JOB_ID" \
  --region="$REGION" --quiet

sleep 10

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
