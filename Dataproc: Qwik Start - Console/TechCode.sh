
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

echo "${CYAN}Detecting Zone from gcloud config...${RESET}"

# Auto-detect from Qwiklabs settings
ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
REGION="${ZONE%-*}"

PROJECT_ID=$(gcloud config get-value project)
CLUSTER="example-cluster"

# Display Info
echo ""
echo "${GREEN}----------------------------------------"
echo "Project ID : $PROJECT_ID"
echo "Region     : $REGION"
echo "Zone       : $ZONE"
echo "Cluster    : $CLUSTER"
echo "----------------------------------------${RESET}"
echo ""

# Validate Zone
if [[ -z "$ZONE" ]]; then
  echo "${RED}Error: Zone not set in gcloud config.${RESET}"
  echo "Run this and rerun script:"
  echo ""
  echo "  gcloud config set compute/zone us-central1-a"
  echo ""
  exit 1
fi

echo "${CYAN}Enabling Dataproc API...${RESET}"
gcloud services enable dataproc.googleapis.com

echo "${CYAN}Creating Dataproc cluster...${RESET}"
gcloud dataproc clusters create "$CLUSTER" \
  --region="$REGION" \
  --zone="$ZONE" \
  --master-machine-type=e2-standard-2 \
  --master-boot-disk-size=30 \
  --worker-machine-type=e2-standard-2 \
  --worker-boot-disk-size=30 \
  --num-workers=2 \
  --image-version=2.1-debian11 \
  --quiet

if [ $? -ne 0 ]; then
    echo "${RED}Cluster creation FAILED!${RESET}"
    exit 1
fi

echo "${GREEN}Cluster created successfully!${RESET}"
echo ""

echo "${MAGENTA}Submitting SparkPi job (first run)...${RESET}"
gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

echo "${GREEN}First job completed!${RESET}"
echo ""

echo "${YELLOW}Scaling cluster to 4 workers...${RESET}"
gcloud dataproc clusters update "$CLUSTER" \
  --region="$REGION" \
  --num-workers=4 \
  --quiet

echo "${GREEN}Cluster scaled successfully!${RESET}"
echo ""

echo "${MAGENTA}Submitting SparkPi job after scaling...${RESET}"
gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
