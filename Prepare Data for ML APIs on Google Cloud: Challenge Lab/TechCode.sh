#!/bin/bash

# Color Definitions
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

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -e "${CYAN_TEXT}${BOLD_TEXT}--- GCP LAB CONFIGURATION ---${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)

read -p "$(echo -e ${YELLOW_TEXT}"Enter REGION Name: "${RESET_FORMAT})" REGION
read -p "$(echo -e ${YELLOW_TEXT}"Enter BigQuery DATASET Name: "${RESET_FORMAT})" DATASET
read -p "$(echo -e ${YELLOW_TEXT}"Enter BigQuery TABLE Name: "${RESET_FORMAT})" TABLE
read -p "$(echo -e ${MAGENTA_TEXT}"Enter Task 3 Output URI: "${RESET_FORMAT})" TASK3_OUTPUT
read -p "$(echo -e ${MAGENTA_TEXT}"Enter Task 4 Output URI: "${RESET_FORMAT})" TASK4_OUTPUT
export BUCKET="${PROJECT_ID}-marking"
export TEMP_LOCATION="gs://${BUCKET}/temp"
export BQ_TEMP="gs://${BUCKET}/bigquery_temp"

echo -e "\n${GREEN_TEXT}${BOLD_TEXT}Configuration complete. Starting tasks...${RESET_FORMAT}\n"

# --- TASK 1: Dataflow ---
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}Starting Task 1: Dataflow...${RESET_FORMAT}"

# Create resources
bq mk $DATASET 2>/dev/null || echo "Dataset exists"
gsutil mb -l $REGION gs://$BUCKET 2>/dev/null || echo "Bucket exists"

# Run Dataflow job (FINAL FIX)
gcloud dataflow jobs run batch-job-task1 \
  --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery \
  --region $REGION \
  --worker-machine-type e2-standard-2 \
  --staging-location $TEMP_LOCATION \
  --parameters \
javascriptTextTransformFunctionName=transform,\
JSONPath=gs://spls/gsp323/lab.schema,\
javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,\
inputFilePattern=gs://spls/gsp323/lab.csv,\
outputTable=$PROJECT_ID:$DATASET.$TABLE,\
bigQueryLoadingTemporaryDirectory=$BQ_TEMP

# --- TASK 2: Dataproc ---
echo -e "\n${MAGENTA_TEXT}${BOLD_TEXT}Starting Task 2: Dataproc Cluster Creation...${RESET_FORMAT}"
sleep 10

gcloud dataproc clusters create cluster-task2 \
    --region=$REGION \
    --num-workers 2 \
    --master-machine-type e2-standard-2 \
    --master-boot-disk-type pd-balanced \
    --master-boot-disk-size 100 \
    --worker-machine-type e2-standard-2 \
    --worker-boot-disk-type pd-balanced \
    --worker-boot-disk-size 100 \
    --image-version 2.0-debian10 \
    --project $PROJECT_ID

sleep 10

# Automatically find the VM Name and the Zone
export MASTER_NODE=$(gcloud compute instances list --filter="name ~ cluster-task2-m" --format="value(name)")
export MASTER_ZONE=$(gcloud compute instances list --filter="name ~ cluster-task2-m" --format="value(zone)")

echo -e "${BLUE_TEXT}Targeting VM: $MASTER_NODE in Zone: $MASTER_ZONE${RESET_FORMAT}"

# SSH and move data
gcloud compute ssh $MASTER_NODE --zone=$MASTER_ZONE --quiet --command="gsutil cp gs://spls/gsp323/data.txt . && hdfs dfs -put data.txt /data.txt"

# Submit Spark Job
echo -e "${BLUE_TEXT}Submitting Spark Job...${RESET_FORMAT}"
gcloud dataproc jobs submit spark \
    --cluster=cluster-task2 \
    --region=$REGION \
    --class=org.apache.spark.examples.SparkPageRank \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --max-failures-per-hour=1 \
    -- /data.txt

# --- TASK 3: Speech-to-Text API ---
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}Starting Task 3: Speech-to-Text...${RESET_FORMAT}"

# Enable required APIs
gcloud services enable apikeys.googleapis.com
gcloud services enable speech.googleapis.com

# Create API key
gcloud alpha services api-keys create --display-name="ml-api-key"

echo -e "${CYAN_TEXT}Waiting for API Key propagation...${RESET_FORMAT}"
sleep 30

# Get only ONE API key (fix for multiple keys issue)
KEY_NAME=$(gcloud alpha services api-keys list \
--format="value(name)" \
--filter="displayName=ml-api-key" \
--limit=1)

API_KEY=$(gcloud alpha services api-keys get-key-string "$KEY_NAME" \
--format="value(keyString)")

# Create request
cat > request.json <<EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "en-US"
  },
  "audio": {
    "uri": "gs://spls/gsp323/task3.flac"
  }
}
EOF

# Call Speech-to-Text API
curl -s -X POST -H "Content-Type: application/json" \
--data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
> result_task3.json

# Upload result with correct content-type
gsutil -h "Content-Type: application/json" cp result_task3.json $TASK3_OUTPUT

# --- TASK 4: Natural Language API ---
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}Starting Task 4: Natural Language...${RESET_FORMAT}"

gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result_task4.json

gsutil -h "Content-Type: application/json" cp result_task4.json $TASK4_OUTPUT

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
