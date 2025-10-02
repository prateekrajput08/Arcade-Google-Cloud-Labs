#!/bin/bash

# Define color variables
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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Get User Input
read -p "${YELLOW_TEXT}Enter Bucket Name: ${RESET_FORMAT}" BUCKET
read -p "${YELLOW_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
read -p "${YELLOW_TEXT}Enter Topic Name: ${RESET_FORMAT}" TOPIC
read -p "${YELLOW_TEXT}Enter Cloud Function Name: ${RESET_FORMAT}" FUNCTION

# Set Configuration
gcloud config set compute/region $REGION
export PROJECT_ID=$(gcloud config get-value project)

# Enable Required APIs
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Enabling Required APIs...${RESET_FORMAT}"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

# Create Infrastructure
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Storage Bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$BUCKET

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Pub/Sub Topic...${RESET_FORMAT}"
gcloud pubsub topics create $TOPIC

# Configure Permissions
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Configuring Permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

# Create Function Files
mkdir -p ~/thumbnail-function && cd $_
touch index.js package.json

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Generating Function Code...${RESET_FORMAT}"

cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('FUNCTION_PLACEHOLDER', cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${event}`);
  console.log(`Processing bucket: ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "TOPIC_PLACEHOLDER";
  const pubsub = new PubSub();
  
  if ( fileName.search("64x64_thumbnail") == -1 ){
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
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
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
            gcsNewObject.setMetadata(
            {
              contentType: 'image/'+ filename_ext.toLowerCase()
            }, function(err, apiResponse) {});
            
            pubsub
              .topic(topicName)
              .publisher()
              .publish(Buffer.from(newFilename))
              .then(messageId => {
                console.log(`Message ${messageId} published.`);
              })
              .catch(err => {
                console.error('ERROR:', err);
              });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not a supported image format`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
EOF_END

# Customize function files
sed -i "s/FUNCTION_PLACEHOLDER/$FUNCTION/" index.js
sed -i "s/TOPIC_PLACEHOLDER/$TOPIC/" index.js

cat > package.json <<EOF_END
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
    "@google-cloud/storage": "^5.0.0",
    "fast-crc32c": "1.0.4",
    "imagemagick-stream": "4.1.1"
  },
  "devDependencies": {},
  "engines": {
    "node": ">=4.3.2"
  }
}
EOF_END

# Deploy Function
deploy_function() {
  gcloud functions deploy $FUNCTION \
    --gen2 \
    --runtime nodejs22 \
    --entry-point $FUNCTION \
    --source . \
    --region $REGION \
    --trigger-bucket $BUCKET \
    --trigger-location $REGION \
    --max-instances 1 \
    --quiet
}

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Deploying Cloud Function...${RESET_FORMAT}"

# Wait for deployment to complete
while true; do
  deploy_function
  if gcloud functions describe $FUNCTION --region $REGION &> /dev/null; then
    break
  else
    echo "Waiting for function deployment to complete..."
    sleep 10
  fi
done

# Test with sample image
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Uploading Test Image...${RESET_FORMAT}"
wget -q https://storage.googleapis.com/cloud-training/gsp315/map.jpg 
gsutil cp map.jpg gs://$BUCKET

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
