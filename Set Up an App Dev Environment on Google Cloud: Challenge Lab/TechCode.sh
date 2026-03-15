
#!/bin/bash

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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter required values:${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}Enter User Email to Remove (USER_2): ${WHITE_TEXT}${BOLD_TEXT}" USER_2
echo -e "${RESET_FORMAT}"

read -p "${YELLOW_TEXT}Enter Zone (e.g. europe-west4-a): ${WHITE_TEXT}${BOLD_TEXT}" ZONE
echo -e "${RESET_FORMAT}"

read -p "${YELLOW_TEXT}Enter Pub/Sub Topic Name (TOPIC): ${WHITE_TEXT}${BOLD_TEXT}" TOPIC
echo -e "${RESET_FORMAT}"

read -p "${YELLOW_TEXT}Enter Cloud Function Name (FUNCTION): ${WHITE_TEXT}${BOLD_TEXT}" FUNCTION
echo -e "${RESET_FORMAT}"

export USER_2 
export ZONE 
export TOPIC 
export FUNCTION 

# Compute region from zone 
export REGION="${ZONE%-*}" 

# =============================== # SERVICES ENABLE # =============================== 
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com
  
sleep 90
  
PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)') 
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/eventarc.eventReceiver 
  
sleep 20 

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $DEVSHELL_PROJECT_ID)" 
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role='roles/pubsub.publisher' 

sleep 20 

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator 
  
sleep 20 

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket 
gcloud pubsub topics create $TOPIC

PROJECT_ID=$(gcloud config get-value project)

echo "Getting project info..."

BUCKET="$DEVSHELL_PROJECT_ID-bucket"

echo "Project: $PROJECT_ID"
echo "Bucket: $BUCKET"
echo "Topic: $TOPIC"

mkdir task3
cd task3

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('$FUNCTION', async cloudEvent => {

  const event = cloudEvent.data;

  const fileName = event.name;
  const bucketName = event.bucket;

  const bucket = new Storage().bucket(bucketName);

  const topicName = "$TOPIC";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {

    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1);

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {

      const gcsObject = bucket.file(fileName);
      const newFilename = \`\${filename_without_ext}_64x64_thumbnail.\${filename_ext}\`;
      const gcsNewObject = bucket.file(newFilename);

      try {

        const [buffer] = await gcsObject.download();

        const resizedBuffer = await sharp(buffer)
          .resize(64,64,{fit:'inside',withoutEnlargement:true})
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer);

        await pubsub.topic(topicName)
          .publishMessage({data:Buffer.from(newFilename)});

      } catch(err){
        console.error(err);
      }

    }
  }
});
EOF


cat > package.json <<EOF
{
"name":"thumbnails",
"version":"1.0.0",
"description":"Create Thumbnail",
"scripts":{"start":"node index.js"},
"dependencies":{
"@google-cloud/functions-framework":"^3.0.0",
"@google-cloud/pubsub":"^2.0.0",
"@google-cloud/storage":"^6.11.0",
"sharp":"^0.32.1"
}
}
EOF


echo "Deploying Cloud Run Function..."

gcloud functions deploy $FUNCTION \
--gen2 \
--runtime=nodejs22 \
--region=$REGION \
--entry-point=$FUNCTION \
--trigger-resource=$BUCKET \
--trigger-event=google.storage.object.finalize \
--source=.


echo "Testing function..."

curl -O https://storage.googleapis.com/cloud-training/gsp315/map.jpg

gsutil cp map.jpg gs://$BUCKET

echo "Task 3 Completed."

sleep 20

curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg

gsutil cp map.jpg gs://$DEVSHELL_PROJECT_ID-bucket/map.jpg

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:$USER_2 \
--role=roles/viewer

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                   RUN SECOND COMMAND                  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
