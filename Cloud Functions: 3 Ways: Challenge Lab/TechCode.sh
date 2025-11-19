#!/bin/bash

# ---------------------------------------------------------
#   Tech & Code - Guaranteed Working Script for Challenge Lab
#   YouTube: https://www.youtube.com/@TechCode93
# ---------------------------------------------------------

REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="$PROJECT_ID"

echo "Using Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"

# ---------------------- TASK 1 ---------------------------
echo "Creating Bucket (ignore error if exists)..."

gsutil mb -l $REGION gs://$BUCKET_NAME/ 2>/dev/null

echo "Bucket ready!"

# ---------------------- TASK 2 ---------------------------
echo "Preparing Cloud Storage Function..."

mkdir -p cs-func
cd cs-func

cat <<EOF > index.js
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('cs-tracker', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat <<EOF > package.json
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "Deploying cs-tracker function..."

gcloud functions deploy cs-tracker \
  --gen2 \
  --region=$REGION \
  --runtime=nodejs20 \
  --source=. \
  --entry-point=cs-tracker \
  --trigger-bucket=$BUCKET_NAME \
  --max-instances=2 \
  --quiet

cd ..

echo "Cloud Storage function deployed."

# ---------------------- TASK 3 ---------------------------
echo "Preparing HTTP Function..."

mkdir -p http-func
cd http-func

cat <<EOF > index.js
const functions = require('@google-cloud/functions-framework');

functions.http('http-messenger', (req, res) => {
  res.status(200).send('HTTP function (2nd gen) has been called!');
});
EOF

cat <<EOF > package.json
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "Deploying http-messenger function..."

gcloud functions deploy http-messenger \
  --gen2 \
  --region=$REGION \
  --runtime=nodejs20 \
  --source=. \
  --entry-point=http-messenger \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances=1 \
  --max-instances=2 \
  --quiet

echo "HTTP Function deployed successfully!"

# ----------------- FINISHED ----------------------------

echo "===================================================="
echo " ALL TASKS COMPLETED SUCCESSFULLY!"
echo " Bucket: $BUCKET_NAME"
echo " Cloud Storage Function: cs-tracker"
echo " HTTP Function: http-messenger"
echo " Subscribe: Tech & Code 🔥"
echo " https://www.youtube.com/@TechCode93"
echo "===================================================="
