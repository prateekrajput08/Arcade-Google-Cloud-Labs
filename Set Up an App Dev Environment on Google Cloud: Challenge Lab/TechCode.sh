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

read -p "Enter User Email to Remove: " USER_2
read -p "Enter Zone (example europe-west4-a): " ZONE
read -p "Enter Pub/Sub Topic Name: " TOPIC
read -p "Enter Cloud Function Name: " FUNCTION

export REGION="${ZONE%-*}"

# ===============================
# ENABLE SERVICES
# ===============================

gcloud services enable \
artifactregistry.googleapis.com \
cloudfunctions.googleapis.com \
cloudbuild.googleapis.com \
eventarc.googleapis.com \
run.googleapis.com \
logging.googleapis.com \
pubsub.googleapis.com

sleep 60

PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--role=roles/eventarc.eventReceiver

sleep 10

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $DEVSHELL_PROJECT_ID)"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="serviceAccount:${SERVICE_ACCOUNT}" \
--role='roles/pubsub.publisher'

sleep 10

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
--role=roles/iam.serviceAccountTokenCreator

sleep 10

# Eventarc bucket permission fix
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com" \
--role="roles/storage.admin"

sleep 10

# ===============================
# CREATE BUCKET & TOPIC
# ===============================

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket

gcloud pubsub topics create $TOPIC || true

mkdir function
cd function

# ===============================
# CREATE FUNCTION CODE
# ===============================

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('${FUNCTION}', cloudEvent => {
  const event = cloudEvent.data;

  console.log(\`Hello \${event.bucket}\`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "${TOPIC}";
  const pubsub = new PubSub();

  if ( fileName.search("64x64_thumbnail") == -1 ){

    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );

    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){

      console.log(\`Processing Original: gs://\${bucketName}/\${fileName}\`);

      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);

      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();

      let resize = imagemagick().resize(size).quality(90);

      srcStream.pipe(resize).pipe(dstStream);

      return new Promise((resolve, reject) => {

        dstStream
          .on("error", (err) => {
            console.log(\`Error: \${err}\`);
            reject(err);
          })
          .on("finish", () => {

            console.log(\`Success: \${fileName} → \${newFilename}\`);

            pubsub
              .topic(topicName)
              .publishMessage({data: Buffer.from(newFilename)});

          });
      });
    }
  }
});
EOF

# ===============================
# PACKAGE.JSON
# ===============================

cat > package.json <<EOF
{
 "name": "thumbnails",
 "version": "1.0.0",
 "description": "Create Thumbnail of uploaded image",
 "scripts": {
   "start": "node index.js"
 },
 "dependencies": {
   "@google-cloud/functions-framework": "^3.0.0",
   "@google-cloud/pubsub": "^2.0.0",
   "@google-cloud/storage": "^6.11.0",
   "sharp": "^0.32.1"
 },
 "devDependencies": {},
 "engines": {
   "node": ">=4.3.2"
 }
}
EOF

PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com \
--role=roles/pubsub.publisher

# ===============================
# DEPLOY FUNCTION
# ===============================

deploy_function() {

gcloud functions deploy $FUNCTION \
--gen2 \
--runtime=nodejs22 \
--region=$REGION \
--entry-point=$FUNCTION \
--trigger-resource=$DEVSHELL_PROJECT_ID-bucket \
--trigger-event=google.storage.object.finalize \
--source=. \
--quiet

}

SERVICE_NAME="$FUNCTION"

while true
do
deploy_function

if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null
then
echo "Cloud Run service created"
break
else
sleep 20
fi
done

# ===============================
# TEST FUNCTION
# ===============================

curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg

gsutil cp map.jpg gs://$DEVSHELL_PROJECT_ID-bucket/map.jpg

# ===============================
# REMOVE USER
# ===============================

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:$USER_2 \
--role=roles/viewer

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
