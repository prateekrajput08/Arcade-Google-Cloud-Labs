
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

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cluster...${RESET_FORMAT}"

MAX_RETRIES=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    echo "Cluster creation attempt $ATTEMPT of $MAX_RETRIES..."

    gcloud dataproc clusters create example-cluster \
        --project="$PROJECT_ID" \
        --region="$REGION" \
        --master-machine-type=e2-standard-2 \
        --master-boot-disk-type=pd-standard \
        --master-boot-disk-size=30GB \
        --worker-machine-type=e2-standard-2 \
        --worker-boot-disk-type=pd-standard \
        --worker-boot-disk-size=30GB \
        --num-workers=2

    if [ $? -eq 0 ]; then
        echo "${GREEN_TEXT}${BOLD_TEXT}Cluster created successfully!${RESET_FORMAT}"
        break
    fi

    echo "${RED_TEXT}${BOLD_TEXT}Cluster creation failed.${RESET_FORMAT}"
    echo "${YELLOW_TEXT}${BOLD_TEXT}Deleting any existing/partial cluster...${RESET_FORMAT}"

    gcloud dataproc clusters delete example-cluster \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null || true

    ATTEMPT=$((ATTEMPT + 1))
    sleep 10
done

if [ $ATTEMPT -gt $MAX_RETRIES ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create cluster after $MAX_RETRIES attempts.${RESET_FORMAT}"
    exit 1
fi

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
