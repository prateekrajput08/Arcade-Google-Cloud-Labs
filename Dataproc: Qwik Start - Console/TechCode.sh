
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

echo "${CYAN_TEXT}${BOLD_TEXT}Enter your Compute Engine Zone (example: us-central1-a):${NO_COLOR}"
read ZONE

REGION="${ZONE%-*}"
CLUSTER="example-cluster"
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}----------------------------------------"
echo "Project ID : ${WHITE_TEXT}$PROJECT_ID"
echo "Project #  : ${WHITE_TEXT}$PROJECT_NUMBER"
echo "Region     : ${WHITE_TEXT}$REGION"
echo "Zone       : ${WHITE_TEXT}$ZONE"
echo "Cluster    : ${WHITE_TEXT}$CLUSTER"
echo "Service Acc: ${WHITE_TEXT}$SERVICE_ACCOUNT"
echo "----------------------------------------${NO_COLOR}"
echo ""

# ------------------------------------------
# ENABLE DATAPROC API
# ------------------------------------------
echo "${TEAL_TEXT}Enabling Dataproc API...${NO_COLOR}"
gcloud services enable dataproc.googleapis.com

# ------------------------------------------
# IAM ROLE FIX (DYNAMIC SA)
# ------------------------------------------
echo "${TEAL_TEXT}Adding Storage Admin role to service account...${NO_COLOR}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.admin" \
  --quiet

# ------------------------------------------
# CREATE DATAPROC CLUSTER
# ------------------------------------------
echo "${GOLD_TEXT}${BOLD_TEXT}Creating Dataproc Cluster...${NO_COLOR}"
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
    echo "${RED_TEXT}${BOLD_TEXT}Cluster creation FAILED. Exiting.${NO_COLOR}"
    exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Cluster created successfully!${NO_COLOR}"
echo ""

# ------------------------------------------
# RUN SPARK JOB (PI ESTIMATION)
# ------------------------------------------
echo "${PURPLE_TEXT}${BOLD_TEXT}Submitting SparkPi job (first run)...${NO_COLOR}"
gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER" \
  --region="$REGION" \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000

echo "${GREEN_TEXT}${BOLD_TEXT}First Spark job completed!${NO_COLOR}"
echo ""

# ------------------------------------------
# SCALE CLUSTER TO 4 WORKERS
# ------------------------------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Scaling cluster to 4 workers...${NO_COLOR}"
gcloud dataproc clusters update "$CLUSTER" \
  --region="$REGION" \
  --num-workers=4 \
  --quiet

echo "${GREEN_TEXT}${BOLD_TEXT}Cluster scaled successfully!${NO_COLOR}"
echo ""

# ------------------------------------------
# RUN SPARK JOB AGAIN
# ------------------------------------------
echo "${MAGENTA_TEXT}${BOLD_TEXT}Submitting SparkPi job after scaling...${NO_COLOR}"
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
