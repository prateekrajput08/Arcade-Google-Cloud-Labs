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


read -p "${YELLOW_TEXT}Enter Pub/Sub TOPIC name:${RESET_FORMAT} " TOPIC
read -p "${YELLOW_TEXT}Enter MESSAGE body:${RESET_FORMAT} " MESSAGE

echo "${GREEN_TEXT}Detecting region...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
gcloud config set compute/region $REGION

echo "${PINK_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com
gcloud services enable dataflow.googleapis.com pubsub.googleapis.com cloudscheduler.googleapis.com appengine.googleapis.com storage.googleapis.com cloudresourcemanager.googleapis.com
sleep 80

echo "${TEAL_TEXT}Creating Pub/Sub topic...${RESET_FORMAT}"
gcloud pubsub topics create $TOPIC

PROJECT_ID=$(gcloud config get-value project)
BUCKET="${PROJECT_ID}-bucket"

echo "${PINK_TEXT}Creating bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$BUCKET

if [[ "$REGION" == "us-central1" ]]; then
  AE_REGION="us-central"
elif [[ "$REGION" == "europe-west1" ]]; then
  AE_REGION="europe-west"
elif [[ "$REGION" == "asia-east1" ]]; then
  AE_REGION="asia-east"
else
  AE_REGION="us-central"
fi

echo "${PINK_TEXT}Creating App Engine...${RESET_FORMAT}"
gcloud app create --region=$AE_REGION

echo "${GREEN_TEXT}Creating Scheduler job...${RESET_FORMAT}"
gcloud scheduler jobs create pubsub publisher-job \
    --schedule="* * * * *" \
    --topic=$TOPIC \
    --message-body="$MESSAGE" \
    --location=$AE_REGION

echo "${GREEN_TEXT}Triggering Scheduler...${RESET_FORMAT}"
while true; do
    if gcloud scheduler jobs run publisher-job --location=$AE_REGION; then
        echo "${GREEN_TEXT}Scheduler triggered.${RESET_FORMAT}"
        break
    else
        echo "${RED_TEXT}Retrying...${RESET_FORMAT}"
        sleep 10
    fi
done

echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Dataflow script...${RESET_FORMAT}"
cat > shell.sh <<EOF_CP
#!/bin/bash
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics
pip install -U -r requirements.txt
python PubSubToGCS.py \
--project=$PROJECT_ID \
--region=$REGION \
--input_topic=projects/$PROJECT_ID/topics/$TOPIC \
--output_path=gs://$BUCKET/samples/output \
--runner=DataflowRunner \
--window_size=2 \
--num_shards=2 \
--temp_location=gs://$BUCKET/temp
EOF_CP

chmod +x shell.sh

echo "${YELLOW_TEXT}${BOLD_TEXT}Running Dataflow pipeline...${RESET_COLOR}"
docker run -it \
  -e PROJECT_ID=$PROJECT_ID \
  -e REGION=$REGION \
  -e TOPIC=$TOPIC \
  -e BUCKET=$BUCKET \
  -v $(pwd)/shell.sh:/shell.sh \
  python:3.10 \
  /bin/bash -c "/shell.sh"

echo "${GREEN_TEXT}${BOLD_TEXT}Dataflow job submitted. Check Cloud Storage.${RESET_COLOR}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
