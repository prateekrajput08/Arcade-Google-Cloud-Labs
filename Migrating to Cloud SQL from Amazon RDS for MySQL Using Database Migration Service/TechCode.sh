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
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

#!/bin/bash
# ------------------------------------------------------------------
# GSP859: Migrating to Cloud SQL from Amazon RDS for MySQL
# Using Database Migration Service (DMS)
# ------------------------------------------------------------------

# Text colors
YELLOW_TEXT=$'\033[0;93m'
GREEN_TEXT=$'\033[0;92m'
RED_TEXT=$'\033[0;91m'
RESET_TEXT=$'\033[0m'

echo "${YELLOW_TEXT}Step 1: Update system and install required utilities${RESET_TEXT}"
sudo apt-get update -y && sudo apt-get install -y dnsutils unzip

echo "${YELLOW_TEXT}Step 2: Install AWS CLI${RESET_TEXT}"
if ! command -v aws &> /dev/null; then
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    echo "${GREEN_TEXT}AWS CLI installed successfully.${RESET_TEXT}"
else
    echo "${GREEN_TEXT}AWS CLI already installed.${RESET_TEXT}"
fi

echo "${YELLOW_TEXT}Step 3: Configure AWS CLI${RESET_TEXT}"
if [ -f ~/.aws/credentials ]; then
    echo "AWS CLI already configured. Skipping this step."
else
    echo "Enter your AWS Access Key ID:"
    read AWS_ACCESS_KEY
    echo "Enter your AWS Secret Access Key:"
    read AWS_SECRET_KEY
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
    aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
    aws configure set default.region us-east-1
    aws configure set output json
    echo "${GREEN_TEXT}AWS CLI configured successfully.${RESET_TEXT}"
fi

echo "${YELLOW_TEXT}Step 4: Resolve Amazon RDS instance IP address${RESET_TEXT}"
echo "Enter your RDS hostname (for example: qmflvsilronjc8.cyla72gcy8zl.us-east-1.rds.amazonaws.com):"
read HOSTNAME

if [ -z "$HOSTNAME" ]; then
    echo "${RED_TEXT}Error: Hostname cannot be empty.${RESET_TEXT}"
    exit 1
fi

IP_ADDRESS=$(dig +short "$HOSTNAME" | tail -n1)
if [ -z "$IP_ADDRESS" ]; then
    echo "${RED_TEXT}Error: Unable to resolve IP address for $HOSTNAME${RESET_TEXT}"
    exit 1
fi

echo "Resolved RDS IP address: $IP_ADDRESS"

echo "${YELLOW_TEXT}Step 5: Enable Database Migration API${RESET_TEXT}"
gcloud services enable datamigration.googleapis.com

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "${RED_TEXT}Error: Unable to fetch Project ID.${RESET_TEXT}"
    exit 1
fi
echo "Using Project ID: $PROJECT_ID"

# Attempt to determine region automatically
DEFAULT_REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$DEFAULT_REGION" ]; then
    echo "Enter region for Database Migration Service (e.g., us-central1):"
    read REGION
else
    REGION=$DEFAULT_REGION
fi
echo "Using region: $REGION"

echo "${YELLOW_TEXT}Step 6: Create Database Migration connection profile${RESET_TEXT}"
gcloud database-migration connection-profiles create mysql-rds \
  --region=$REGION \
  --display-name="mysql-rds" \
  --type=mysql \
  --provider=rds \
  --host=$IP_ADDRESS \
  --port=3306 \
  --username=admin \
  --password=changeme \
  --no-ssl

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}Connection profile 'mysql-rds' created successfully.${RESET_TEXT}"
else
    echo "${RED_TEXT}Failed to create connection profile.${RESET_TEXT}"
    exit 1
fi

echo "${YELLOW_TEXT}Step 7: Verify the created connection profile${RESET_TEXT}"
gcloud database-migration connection-profiles list --region=$REGION

echo "${GREEN_TEXT}Setup and connection profile creation completed successfully.${RESET_TEXT}"

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
