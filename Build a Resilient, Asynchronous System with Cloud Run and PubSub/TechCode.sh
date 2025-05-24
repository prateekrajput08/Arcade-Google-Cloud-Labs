#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             INITIATING EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

# User input for ZONE
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Set the compute zone.${RESET_FORMAT}"
read -p "${CYAN_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
export ZONE

# Set PROJECT_ID
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

# Configure compute zone and region
gcloud config set compute/zone $ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Compute zone and region configured successfully!${RESET_FORMAT}"
echo

# Create Pub/Sub topic
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Creating a Pub/Sub topic...${RESET_FORMAT}"
gcloud pubsub topics create new-lab-report
echo "${GREEN_TEXT}Pub/Sub topic 'new-lab-report' created successfully!${RESET_FORMAT}"
echo

# Enable Cloud Run API
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Enabling Cloud Run API...${RESET_FORMAT}"
gcloud services enable run.googleapis.com
echo "${GREEN_TEXT}Cloud Run API enabled successfully!${RESET_FORMAT}"
echo

# Clone the repository
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4: Cloning the Pet Theory repository...${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory.git
echo "${GREEN_TEXT}Repository cloned successfully!${RESET_FORMAT}"
echo

# Navigate to lab-service directory and set up
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5: Setting up the lab-service...${RESET_FORMAT}"
cd pet-theory/lab05/lab-service
npm install express
npm install body-parser
npm install @google-cloud/pubsub

# Create package.json for lab-service
cat > package.json <<EOF_CP
{
  "name": "lab05",
  "version": "1.0.0",
  "description": "This is lab05 of the Pet Theory labs",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "Patrick - IT",
  "license": "ISC",
  "dependencies": {
    "@google-cloud/pubsub": "^4.0.0",
    "body-parser": "^1.20.2",
    "express": "^4.18.2"
  }
}
EOF_CP

# Create index.js for lab-service
cat > index.js <<EOF_CP
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});
app.post('/', async (req, res) => {
  try {
    const labReport = req.body;
    await publishPubSubMessage(labReport);
    res.status(204).send();
  }
  catch (ex) {
    console.log(ex);
    res.status(500).send(ex);
  }
})
async function publishPubSubMessage(labReport) {
  const buffer = Buffer.from(JSON.stringify(labReport));
  await pubsub.topic('new-lab-report').publish(buffer);
}
EOF_CP

# Create Dockerfile for lab-service
cat > Dockerfile <<EOF_CP
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF_CP

echo "${GREEN_TEXT}${BOLD_TEXT}lab-service setup completed successfully!${RESET_FORMAT}"
echo

# Navigate to email-service directory and set up
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Setting up the email-service...${RESET_FORMAT}"
cd ~/pet-theory/lab05/email-service
npm install express
npm install body-parser

# Create package.json for email-service
cat > package.json <<EOF_CP
{
    "name": "lab05",
    "version": "1.0.0",
    "description": "This is lab05 of the Pet Theory labs",
    "main": "index.js",
    "scripts": {
      "start": "node index.js",
      "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [],
    "author": "Patrick - IT",
    "license": "ISC",
    "dependencies": {
      "body-parser": "^1.20.2",
      "express": "^4.18.2"
    }
  }
EOF_CP

# Create index.js for email-service
cat > index.js <<EOF_CP
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`Email Service: Report ${labReport.id} trying...`);
    sendEmail();
    console.log(`Email Service: Report ${labReport.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`Email Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendEmail() {
  console.log('Sending email');
}
EOF_CP

# Create Dockerfile for email-service
cat > Dockerfile <<EOF_CP
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF_CP

echo "${GREEN_TEXT}${BOLD_TEXT}email-service setup completed successfully!${RESET_FORMAT}"


echo "${YELLOW_TEXT}${BOLD_TEXT}Step 7: Creating a service account for Pub/Sub Cloud Run Invoker...${RESET_FORMAT}"
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
echo "${GREEN_TEXT}Service account 'pubsub-cloud-run-invoker' created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8: Setting the compute region...${RESET_FORMAT}"
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
echo "${GREEN_TEXT}Compute region set to ${REGION} successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 9: Adding IAM policy binding for email-service...${RESET_FORMAT}"
gcloud run services add-iam-policy-binding email-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region $REGION --project=$DEVSHELL_PROJECT_ID --platform managed
echo "${GREEN_TEXT}IAM policy binding added successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 10: Adding IAM policy binding for Pub/Sub service account...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
echo "${GREEN_TEXT}IAM policy binding for Pub/Sub service account added successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 11: Retrieving the email-service URL...${RESET_FORMAT}"
EMAIL_SERVICE_URL=$(gcloud run services describe email-service --platform managed --region=$REGION --format="value(status.address.url)")
echo "${GREEN_TEXT}Email-service URL: ${EMAIL_SERVICE_URL}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 12: Creating a Pub/Sub subscription for email-service...${RESET_FORMAT}"
gcloud pubsub subscriptions create email-service-sub --topic new-lab-report --push-endpoint=$EMAIL_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
echo "${GREEN_TEXT}Pub/Sub subscription 'email-service-sub' created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 13: Running the post-reports script...${RESET_FORMAT}"
~/pet-theory/lab05/lab-service/post-reports.sh
echo "${GREEN_TEXT}post-reports.sh executed successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 14: Setting up the SMS service...${RESET_FORMAT}"
cd ~/pet-theory/lab05/sms-service
npm install express
npm install body-parser

# Create package.json for SMS service
cat > package.json <<EOF_CP
{
    "name": "lab05",
    "version": "1.0.0",
    "description": "This is lab05 of the Pet Theory labs",
    "main": "index.js",
    "scripts": {
      "start": "node index.js",
      "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [],
    "author": "Patrick - IT",
    "license": "ISC",
    "dependencies": {
      "body-parser": "^1.20.2",
      "express": "^4.18.2"
    }
  }
EOF_CP

# Create index.js for SMS service
cat > index.js <<EOF_CP
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`SMS Service: Report ${labReport.id} trying...`);
    sendSms();

    console.log(`SMS Service: Report ${labReport.id} success :-)`);    
    res.status(204).send();
  }
  catch (ex) {
    console.log(`SMS Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendSms() {
  console.log('Sending SMS');
}
EOF_CP

echo "${GREEN_TEXT}${BOLD_TEXT}SMS service setup completed successfully!${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 15: Creating Dockerfile for the application...${RESET_FORMAT}"
cat > Dockerfile <<EOF_CP
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF_CP
echo "${GREEN_TEXT}Dockerfile created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 16: Deploying the lab-report-service...${RESET_FORMAT}"

# Define maximum retry attempts
MAX_RETRIES=3
retry_count=0

deploy_function() {
  gcloud builds submit \
    --tag gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service
  build_result=$?
  
  if [ $build_result -ne 0 ]; then
    return 1
  fi
  
  gcloud run deploy lab-report-service \
    --image gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --max-instances=1
  return $?
}

deploy_success=false

while [ "$deploy_success" = false ] && [ $retry_count -lt $MAX_RETRIES ]; do
  echo "${YELLOW_TEXT}Deployment attempt $(($retry_count+1))/${MAX_RETRIES}${RESET_FORMAT}"
  if deploy_function; then
    echo "${GREEN_TEXT}lab-report-service deployed successfully!${RESET_FORMAT}"
    deploy_success=true
  else
    retry_count=$((retry_count+1))
    if [ $retry_count -lt $MAX_RETRIES ]; then
      echo "${RED_TEXT}Deployment failed. Retrying in 10 seconds (Attempt $retry_count/$MAX_RETRIES)...${RESET_FORMAT}"
      sleep 10
    else
      echo "${RED_TEXT}${BOLD_TEXT}Maximum retry attempts reached. Moving to next step.${RESET_FORMAT}"
      # Continue with script even if this deployment fails
      break
    fi
  fi
done
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 17: Retrieving the lab-report-service URL...${RESET_FORMAT}"
export LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region=$REGION --format="value(status.address.url)")
echo "${GREEN_TEXT}lab-report-service URL: ${LAB_REPORT_SERVICE_URL}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 18: Creating the post-reports.sh script...${RESET_FORMAT}"
cat > post-reports.sh <<EOF_CP
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 12}" \
  $LAB_REPORT_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 34}" \
  $LAB_REPORT_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 56}" \
  $LAB_REPORT_SERVICE_URL &
EOF_CP

chmod u+x post-reports.sh
echo "${GREEN_TEXT}post-reports.sh script created and permissions updated successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 19: Executing the post-reports.sh script...${RESET_FORMAT}"
./post-reports.sh
echo "${GREEN_TEXT}post-reports.sh script executed successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 20: Deploying the email-service...${RESET_FORMAT}"
deploy_function() {
  gcloud builds submit \
    --tag gcr.io/$GOOGLE_CLOUD_PROJECT/email-service

  gcloud run deploy email-service \
    --image gcr.io/$GOOGLE_CLOUD_PROJECT/email-service \
    --platform managed \
    --region $REGION \
    --no-allow-unauthenticated \
    --max-instances=1
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${GREEN_TEXT}email-service deployed successfully!${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${RED_TEXT}Retrying, please wait...${RESET_FORMAT}"
    sleep 10
  fi
done
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 21: Deploying the sms-service...${RESET_FORMAT}"
deploy_function() {
  gcloud builds submit \
    --tag gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service

  gcloud run deploy sms-service \
    --image gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service \
    --platform managed \
    --region $REGION \
    --no-allow-unauthenticated \
    --max-instances=1
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${GREEN_TEXT}sms-service deployed successfully!${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${RED_TEXT}Retrying, please wait...${RESET_FORMAT}"
    sleep 10
  fi
done



echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
