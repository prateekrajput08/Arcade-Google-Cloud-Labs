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

# ---------------------------------------------------------
# INSERTED YOUR PUBSUB → GCS SAMPLE CODE
# ---------------------------------------------------------
cat << 'EOF' > stream_pipeline.py
import argparse
from datetime import datetime
import logging
import random

import apache_beam as beam
from apache_beam import DoFn, ParDo, Pipeline, WindowInto, GroupByKey, WithKeys
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows
from apache_beam import io

class GroupMessagesByFixedWindows(beam.PTransform):
    def __init__(self, window_size, num_shards=5):
        self.window_size = int(window_size * 60)
        self.num_shards = num_shards

    def expand(self, pcoll):
        return (
            pcoll
            | "Window into fixed intervals" >> WindowInto(FixedWindows(self.window_size))
            | "Add timestamp" >> ParDo(AddTimestamp())
            | "Add key" >> WithKeys(lambda _: random.randint(0, self.num_shards - 1))
            | "Group by key" >> GroupByKey()
        )

class AddTimestamp(DoFn):
    def process(self, element, publish_time=DoFn.TimestampParam):
        yield (
            element.decode("utf-8"),
            datetime.utcfromtimestamp(float(publish_time)).strftime("%Y-%m-%d %H:%M:%S.%f"),
        )

class WriteToGCS(DoFn):
    def __init__(self, output_path):
        self.output_path = output_path

    def process(self, key_value, window=DoFn.WindowParam):
        window_start = window.start.to_utc_datetime().strftime("%H:%M")
        window_end = window.end.to_utc_datetime().strftime("%H:%M")
        shard_id, batch = key_value
        filename = "-".join([self.output_path, window_start, window_end, str(shard_id)])
        with io.gcsio.GcsIO().open(filename, "w") as f:
            for message_body, publish_time in batch:
                f.write(f"{message_body},{publish_time}\n".encode())

def run(input_topic, output_path, window_size, num_shards, pipeline_args):
    options = PipelineOptions(pipeline_args, streaming=True, save_main_session=True)
    with Pipeline(options=options) as p:
        (
            p
            | "Read" >> io.ReadFromPubSub(topic=input_topic)
            | "Windowing" >> GroupMessagesByFixedWindows(window_size, num_shards)
            | "Write" >> ParDo(WriteToGCS(output_path))
        )

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_topic")
    parser.add_argument("--output_path")
    parser.add_argument("--window_size", type=float, default=2.0)
    parser.add_argument("--num_shards", type=int, default=5)
    known_args, pipeline_args = parser.parse_known_args()
    run(known_args.input_topic, known_args.output_path, known_args.window_size, known_args.num_shards, pipeline_args)
EOF

# ---------------------------------------------------------
# RUN THE DATAFLOW JOB
# ---------------------------------------------------------
echo "${GREEN_TEXT}Running Dataflow streaming job...${RESET_FORMAT}"

python3 stream_pipeline.py \
  --input_topic=projects/$(gcloud config get-value project)/topics/$TOPIC \
  --output_path=gs://$BUCKET/output/out \
  --window_size=2 \
  --region=$REGION \
  --runner=DataflowRunner \
  --project=$(gcloud config get-value project) \
  --temp_location=gs://$BUCKET/temp \
  --staging_location=gs://$BUCKET/staging \
  --job_name=streaming-pipeline-$(date +%s)

echo "${GREEN_TEXT}Checking output files in bucket...${RESET_FORMAT}"
gsutil ls gs://$BUCKET/output/


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
