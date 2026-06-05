
#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          SUBSCRIBE TECH & CODE - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enable the Cloud Dataproc API...${RESET_FORMAT}"
gcloud services enable dataproc.googleapis.com
sleep 20


echo "${YELLOW_TEXT}${BOLD_TEXT}Getting Lab Credentials...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=${ZONE%-*}

echo "Zone: $ZONE"
echo "Region: $REGION"
echo "Project id: $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

echo "${YELLOW_TEXT}${BOLD_TEXT}Open Below Link And Follow Video...${RESET_FORMAT}"
echo "https://console.cloud.google.com/dataproc/clusters?project=$PROJECT_ID"

read -p "Press Enter to continue..."

JOB_ID=$(gcloud dataproc jobs submit spark \
  --cluster=example-cluster \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPi \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  --format="value(reference.jobId)" \
  -- 1000)
echo "Job ID: $JOB_ID"
gcloud dataproc jobs wait "$JOB_ID" --region=$REGION

gcloud dataproc clusters update example-cluster \
  --region=$REGION \
  --num-workers=4

  
# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
