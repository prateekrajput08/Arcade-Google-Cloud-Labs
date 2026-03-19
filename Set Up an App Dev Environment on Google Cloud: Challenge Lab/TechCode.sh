#!/bin/bash

echo "Enter required values:"

read -p "Bucket Name: " BUCKET
read -p "Topic Name: " TOPIC
read -p "Function Name: " FUNCTION
read -p "User Email to Remove: " USER_2
read -p "Zone (e.g. us-central1-c): " ZONE

REGION="${ZONE%-*}"
PROJECT_ID=$(gcloud config get-value project)

echo "Project: $PROJECT_ID"
echo "Region: $REGION"

# Enable APIs
gcloud services enable \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  eventarc.googleapis.com \
  pubsub.googleapis.com

sleep 60

# Create bucket (CORRECT NAME)
gsutil mb -l $REGION gs://$BUCKET

# Create Pub/Sub topic
gcloud pubsub topics create $TOPIC

# Create function source
mkdir function && cd function

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
  const pubsub = new PubSub();

  if (!fileName.includes("64x64_thumbnail")) {

    const ext = fileName.split('.').pop().toLowerCase();
    const name = fileName.substring(0, fileName.length - ext.length - 1);

    if (['png','jpg','jpeg'].includes(ext)) {

      const file = bucket.file(fileName);
      const newFile = bucket.file(\`\${name}_64x64_thumbnail.\${ext}\`);

      const [buffer] = await file.download();

      const resized = await sharp(buffer)
        .resize(64,64,{fit:'inside',withoutEnlargement:true})
        .toBuffer();

      await newFile.save(resized);

      await pubsub.topic("$TOPIC")
        .publishMessage({data:Buffer.from(newFile.name)});
    }
  }
});
EOF

cat > package.json <<EOF
{
  "name": "thumbnails",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/pubsub": "^2.0.0",
    "@google-cloud/storage": "^6.11.0",
    "sharp": "^0.32.1"
  }
}
EOF

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Eventarc service agent
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com" \
  --role="roles/eventarc.serviceAgent"

# Pub/Sub service agent
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# Storage service agent → Pub/Sub publisher
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"

gcloud functions deploy $FUNCTION \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --entry-point=$FUNCTION \
  --source=. \
  --trigger-bucket=$BUCKET \
  --trigger-location=$REGION

sleep 120

curl -O https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://$BUCKET

# Remove user
gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USER_2" \
  --role="roles/viewer"

echo "✅ LAB COMPLETED"
