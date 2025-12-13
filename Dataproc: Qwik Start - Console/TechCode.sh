#!/bin/bash

# ================= COLORS =================
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

# ================= WELCOME =================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - DATAPROC EXECUTION STARTED          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ================= ASK FOR ZONE =================
read -p "$(echo -e ${CYAN_TEXT}Enter Compute Zone \(example: us-central1-a\): ${RESET_FORMAT})" ZONE

if [[ -z "$ZONE" ]]; then
  echo "${RED_TEXT}❌ Zone cannot be empty${RESET_FORMAT}"
  exit 1
fi

# Set zone & region
gcloud config set compute/zone "$ZONE" --quiet
REGION="${ZONE%-*}"
gcloud config set compute/region "$REGION" --quiet

PROJECT_ID=$(gcloud config get-value project)
CLUSTER="example-cluster"

# ================= DISPLAY INFO =================
echo ""
echo "${GREEN_TEXT}----------------------------------------"
echo "Project ID : $PROJECT_ID"
echo "Region     : $REGION"
echo "Zone       : $ZONE"
echo "Cluster    : $CLUSTER"
echo "----------------------------------------${RESET_FORMAT}"
echo ""

# ================= ENABLE API =================
echo "${CYAN_TEXT}Enabling Dataproc API...${RESET_FORMAT}"
gcloud services enable dataproc.googleapis.com --quiet

# ================= CHECK CLUSTER =================
echo ""
echo "${CYAN_TEXT}Checking existing Dataproc cluster...${RESET_FORMAT}"

gcloud dataproc clusters describe "$CLUSTER" \
  --region="$REGION" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
  echo "${RED_TEXT}❌ Cluster '$CLUSTER' not found${RESET_FORMAT}"
  echo "Create the cluster manually and re-run the script."
  exit 1
fi

echo "${GREEN_TEXT}✔ Cluster found. Continuing...${RESET_FORMAT}"
echo ""

# ================= FIRST JOB =================
echo "${MAGENTA_TEXT}Submitting SparkPi job (before scaling)...${RESET_FORMAT}"

gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

echo "${GREEN_TEXT}✔ First job completed${RESET_FORMAT}"
echo ""

# ================= SCALE CLUSTER =================
echo "${YELLOW_TEXT}Scaling cluster to 4 workers...${RESET_FORMAT}"

gcloud dataproc clusters update "$CLUSTER" \
  --region="$REGION" \
  --num-workers=4 \
  --quiet

echo "${GREEN_TEXT}✔ Cluster scaled successfully${RESET_FORMAT}"
echo ""

# ================= SECOND JOB =================
echo "${MAGENTA_TEXT}Submitting SparkPi job (after scaling)...${RESET_FORMAT}"

gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

# ================= COMPLETION =================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe 🚀${RESET_FORMAT}"
