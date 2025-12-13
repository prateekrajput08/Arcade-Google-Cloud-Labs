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

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# ================= WELCOME =================
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      TECH & CODE | DATAPROC MANUAL CLUSTER EXECUTION           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo

# ================= DETECT CONFIG =================
echo "${CYAN_TEXT}Detecting gcloud configuration...${RESET_FORMAT}"

ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
REGION="${ZONE%-*}"
PROJECT_ID=$(gcloud config get-value project)

# 🔹 CHANGE THIS IF YOUR CLUSTER NAME IS DIFFERENT
CLUSTER="example-cluster"

echo
echo "${GREEN_TEXT}----------------------------------------"
echo "Project ID : $PROJECT_ID"
echo "Region     : $REGION"
echo "Zone       : $ZONE"
echo "Cluster    : $CLUSTER"
echo "----------------------------------------${RESET_FORMAT}"
echo

# ================= VALIDATIONS =================
if [[ -z "$ZONE" ]]; then
  echo "${RED_TEXT}❌ Zone not set in gcloud config${RESET_FORMAT}"
  echo "Run:"
  echo "gcloud config set compute/zone us-central1-a"
  exit 1
fi

# ================= ENABLE API =================
echo "${CYAN_TEXT}Enabling Dataproc API...${RESET_FORMAT}"
gcloud services enable dataproc.googleapis.com --quiet

# ================= CHECK CLUSTER =================
echo
echo "${CYAN_TEXT}Checking if Dataproc cluster exists...${RESET_FORMAT}"

gcloud dataproc clusters describe "$CLUSTER" \
  --region="$REGION" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "${RED_TEXT}❌ Cluster '$CLUSTER' does NOT exist${RESET_FORMAT}"
  echo "Please create the cluster manually and rerun the script."
  exit 1
fi

echo "${GREEN_TEXT}✔ Cluster found. Proceeding...${RESET_FORMAT}"
echo

# ================= FIRST JOB =================
echo "${MAGENTA_TEXT}Submitting SparkPi job (before scaling)...${RESET_FORMAT}"

gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

echo "${GREEN_TEXT}✔ First job completed${RESET_FORMAT}"
echo

# ================= SCALE CLUSTER =================
echo "${YELLOW_TEXT}Scaling cluster to 4 workers...${RESET_FORMAT}"

gcloud dataproc clusters update "$CLUSTER" \
  --region="$REGION" \
  --num-workers=4 \
  --quiet

echo "${GREEN_TEXT}✔ Cluster scaled successfully${RESET_FORMAT}"
echo

# ================= SECOND JOB =================
echo "${MAGENTA_TEXT}Submitting SparkPi job (after scaling)...${RESET_FORMAT}"

gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

# ================= DONE =================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY! 🎉                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Like 👍 | Share 🔁 | Subscribe 🔔${RESET_FORMAT}"

