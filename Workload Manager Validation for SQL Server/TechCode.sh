
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

#!/bin/bash

set -e

############################################
# Colors
############################################
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

############################################
# Variables
############################################
SECRET_NAME="qwiklabs"
SECRET_VALUE="LabP@ssw0rd!"
EVALUATION_NAME="sqlserver-evaluation"
VM_NAME="qlab-win-sql01"
SQL_USER="sqluser"
SQL_PASSWORD="LabP@ssw0rd!"

PROJECT_ID=$(gcloud config get-value project)
ZONE=$(gcloud compute instances list \
  --filter="name=$VM_NAME" \
  --format="value(zone)")

############################################
# Banner
############################################
echo -e "${CYAN}=================================================="
echo -e "  Workload Manager SQL Server Automation (GSP1182)"
echo -e "==================================================${RESET}"

############################################
# Step 1: Create Secret Manager Secret
############################################
echo -e "${CYAN}▶ Creating Secret Manager secret...${RESET}"

if gcloud secrets describe $SECRET_NAME &>/dev/null; then
  echo -e "${YELLOW}Secret already exists. Skipping.${RESET}"
else
  echo -n "$SECRET_VALUE" | \
  gcloud secrets create $SECRET_NAME \
    --replication-policy=automatic \
    --data-file=-
  echo -e "${GREEN}Secret created.${RESET}"
fi

############################################
# Step 2: Check Workload Manager Evaluation
############################################
echo -e "${CYAN}▶ Checking Workload Manager Evaluation...${RESET}"

if ! gcloud beta workload-manager evaluations list \
  --format="value(name)" | grep -q "$EVALUATION_NAME"; then

  echo -e "${RED}❌ Evaluation NOT found!${RESET}"
  echo -e "${YELLOW}ACTION REQUIRED:${RESET}"
  echo "1. Go to: Workload Manager → Evaluations"
  echo "2. Create evaluation named: $EVALUATION_NAME"
  echo "3. Workload type: SQL Server"
  echo "4. Select ALL rules"
  echo "5. Schedule: Does not repeat"
  echo
  echo -e "${YELLOW}Re-run this script after creation.${RESET}"
  exit 1
fi

echo -e "${GREEN}Evaluation detected.${RESET}"

echo -e "${CYAN}▶ Configuring SQL Server & Agent on Windows VM...${RESET}"

gcloud compute ssh $VM_NAME \
  --zone=$ZONE \
  --command='powershell -ExecutionPolicy Bypass -Command "
  ##########################################
  # Install Agent
  ##########################################
  googet addrepo google-cloud-workload-agent https://packages.cloud.google.com/yuck/repos/google-cloud-workload-agent-windows-x86_64
  googet install google-cloud-workload-agent

  ##########################################
  # Configure Agent
  ##########################################
  $conf = @\"
{
  \"log_level\": \"INFO\",
  \"common_discovery\": {
    \"collection_frequency\": \"10800s\"
  },
  \"sqlserver_configuration\": {
    \"enabled\": true,
    \"collection_configuration\": {
      \"collect_guest_os_metrics\": true,
      \"collect_sql_metrics\": true,
      \"collection_frequency\": \"60s\"
    },
    \"credential_configurations\": [
      {
        \"connection_parameters\": [
          {
            \"host\": \".\",
            \"username\": \"$SQL_USER\",
            \"secret\": {
              \"project_id\": \"$PROJECT_ID\",
              \"secret_name\": \"$SECRET_NAME\"
            },
            \"port\": 1433
          }
        ],
        \"local_collection\": true
      }
    ],
    \"collection_timeout\": \"60s\",
    \"max_retries\": 5,
    \"retry_frequency\": \"3600s\"
  }
}
\"@

  $path = \"C:\\Program Files\\Google\\google-cloud-workload-agent\\conf\\configuration.json\"
  $conf | Set-Content $path -Encoding UTF8

  ##########################################
  # Fix MAXDOP
  ##########################################
  sqlcmd -S localhost -U $SQL_USER -P $SQL_PASSWORD -Q \"EXEC sp_configure 'show advanced options',1;RECONFIGURE;EXEC sp_configure 'max degree of parallelism',4;RECONFIGURE;\"

  ##########################################
  # Restart Agent
  ##########################################
  Restart-Service google-cloud-workload-agent
  "'


echo -e "${GREEN}Windows VM configuration completed.${RESET}"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
