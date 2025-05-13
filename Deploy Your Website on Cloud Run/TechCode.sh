#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
PINK_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
clear

echo
echo "${PINK_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Verifying your authenticated Google Cloud accounts...${RESET_FORMAT}"
gcloud auth list

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Determining and setting the default Google Cloud region for this session...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Default region automatically set to: ${WHITE_TEXT}${REGION}${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📥 Cloning the 'monolith-to-microservices' repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating into the cloned 'monolith-to-microservices' directory...${RESET_FORMAT}"
cd ~/monolith-to-microservices

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️ Running the setup script for the project...${RESET_FORMAT}"
./setup.sh

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'monolith' application folder...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Creating a new Artifact Registry Docker repository named 'monolith-demo'...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}   This will be located in region: ${WHITE_TEXT}${REGION}${RESET_FORMAT}"
gcloud artifacts repositories create monolith-demo --location=$REGION --repository-format=docker --description="Subscribe to techcps" 

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔑 Configuring Docker to authenticate with Artifact Registry in region: ${WHITE_TEXT}${REGION}${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔔 Enabling necessary Google Cloud services: Artifact Registry, Cloud Build, and Cloud Run APIs...${RESET_FORMAT}"
gcloud services enable artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🏗️ Building the first version (1.0.0) of the monolith Docker image using Cloud Build...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}   Image will be tagged as: ${WHITE_TEXT}$REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0${RESET_FORMAT}"
gcloud builds submit --tag $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0

echo
echo "${PINK_TEXT}${BOLD_TEXT}🚀 Deploying the monolith application (version 1.0.0) to Cloud Run...${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}   Service name: monolith, Region: ${WHITE_TEXT}${REGION}${PINK_TEXT}, Allow unauthenticated access.${RESET_FORMAT}"
gcloud run deploy monolith --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 --allow-unauthenticated --region $REGION

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Updating the Cloud Run service 'monolith' to set concurrency to 1...${RESET_FORMAT}"
gcloud run deploy monolith --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 --allow-unauthenticated --region $REGION --concurrency 1

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Updating the Cloud Run service 'monolith' to set concurrency to 80...${RESET_FORMAT}"
gcloud run deploy monolith --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 --allow-unauthenticated --region $REGION --concurrency 80

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating to the React app's 'Home' page source directory...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔄 Replacing 'index.js' with 'index.js.new' to update the React app's Home page...${RESET_FORMAT}"
mv index.js.new index.js

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Displaying the content of the updated 'index.js' file...${RESET_FORMAT}"
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating to the main 'react-app' directory...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🛠️ Building the React application for the monolith setup...${RESET_FORMAT}"
npm run build:monolith

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Returning to the 'monolith' application directory...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🏗️ Building the second version (2.0.0) of the monolith Docker image with updated frontend...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}   Image will be tagged as: ${WHITE_TEXT}$REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0${RESET_FORMAT}"
gcloud builds submit --tag $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0

echo
echo "${PINK_TEXT}${BOLD_TEXT}🚀 Deploying the updated monolith application (version 2.0.0) to Cloud Run...${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}   Service name: monolith, Region: ${WHITE_TEXT}${REGION}${PINK_TEXT}, Allow unauthenticated access.${RESET_FORMAT}"
gcloud run deploy monolith --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0 --allow-unauthenticated --region $REGION

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Subscribe to Tech & Code for more! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
