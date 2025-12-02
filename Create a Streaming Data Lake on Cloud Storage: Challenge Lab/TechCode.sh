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

echo "${YELLOW_TEXT}Enter Pub/Sub Topic name:${RESET_FORMAT}"
read TOPIC

echo "${YELLOW_TEXT}Enter Scheduler Message to publish:${RESET_FORMAT}"
read MESSAGE

echo "${YELLOW_TEXT}Enter Cloud Storage Bucket name (must be globally unique):${RESET_FORMAT}"
read BUCKET

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "${YELLOW_TEXT}Using REGION: $REGION ${RESET_FORMAT}"

echo "${GREEN_TEXT}Creating Pub/Sub topic...${RESET_FORMAT}"
gcloud pubsub topics create $TOPIC --quiet

echo "${GREEN_TEXT}Creating App Engine app (required by Scheduler)...${RESET_FORMAT}"
gcloud app create --region=$REGION

echo "${GREEN_TEXT}Creating Cloud Scheduler job...${RESET_FORMAT}"
gcloud scheduler jobs create pubsub send-msg-job \
  --schedule="* * * * *" \
  --topic=$TOPIC \
  --message-body="$MESSAGE" \
  --location=$REGION

echo "${GREEN_TEXT}Starting Scheduler job...${RESET_FORMAT}"
gcloud scheduler jobs run send-msg-job --location=$REGION

echo "${GREEN_TEXT}Creating Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$BUCKET/

echo "${GREEN_TEXT}Disabling Dataflow API (required)...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com --quiet

echo "${GREEN_TEXT}Enabling Dataflow API...${RESET_FORMAT}"
gcloud services enable dataflow.googleapis.com --quiet

echo "${GREEN_TEXT}Installing Apache Beam (Python)...${RESET_FORMAT}"
pip install apache-beam[gcp] -q

cat << 'EOF' > stream_pipeline.py
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--input_topic')
parser.add_argument('--output_path')
args, beam_args = parser.parse_known_args()

beam_options = PipelineOptions(
    beam_args,
    streaming=True,
    save_main_session=True,
)

p = beam.Pipeline(options=beam_options)

(
    p
    | "Read From PubSub" >> beam.io.ReadFromPubSub(topic=args.input_topic)
    | "Window 2 Minutes" >> beam.WindowInto(beam.window.FixedWindows(120))
    | "Decode" >> beam.Map(lambda x: x.decode('utf-8'))
    | "Write to GCS" >> beam.io.WriteToText(args.output_path)
)

p.run().wait_until_finish()
EOF

echo "${GREEN_TEXT}Running Dataflow streaming job...${RESET_FORMAT}"

python3 stream_pipeline.py \
  --input_topic=projects/$(gcloud config get-value project)/topics/$TOPIC \
  --output_path=gs://$BUCKET/output \
  --region=$REGION \
  --runner=DataflowRunner \
  --job_name=streaming-pipeline-$(date +%s)

echo "${GREEN_TEXT}Checking output files in bucket...${RESET_FORMAT}"
gsutil ls gs://$BUCKET/


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
