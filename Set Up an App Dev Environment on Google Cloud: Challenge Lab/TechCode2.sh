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

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting project info...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)

BUCKET=$(gsutil ls | head -n1 | sed 's/gs:\/\///' | sed 's/\///')

TOPIC=$(gcloud pubsub topics list --format="value(name)" | head -n1 | awk -F'/' '{print $NF}')

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


echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying Cloud Run Function...${RESET_FORMAT}"

gcloud functions deploy $FUNCTION \
--gen2 \
--runtime=nodejs22 \
--region=$REGION \
--entry-point=$FUNCTION \
--trigger-resource=$BUCKET \
--trigger-event=google.storage.object.finalize \
--source=.


echo "${YELLOW_TEXT}${BOLD_TEXT}Testing function...${RESET_FORMAT}"

curl -O https://storage.googleapis.com/cloud-training/gsp315/map.jpg

gsutil cp map.jpg gs://$BUCKET

echo "${YELLOW_TEXT}${BOLD_TEXT}Task 3 Completed.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Removing previous cloud engineer...${RESET_FORMAT}"

VIEWER_USER=$(gcloud projects get-iam-policy $(gcloud config get-value project) \
--flatten="bindings[].members" \
--filter="bindings.role:roles/viewer" \
--format="value(bindings.members)")

gcloud projects remove-iam-policy-binding $(gcloud config get-value project) \
--member="$VIEWER_USER" \
--role="roles/viewer"

echo "${YELLOW_TEXT}${BOLD_TEXT}Previous engineer removed.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
