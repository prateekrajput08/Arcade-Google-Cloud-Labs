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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Determining the default Google Cloud region...${RESET_FORMAT}"
REGION=$(gcloud compute project-info describe --project=$DEVSHELL_PROJECT_ID --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}Could not automatically determine the default region.${RESET_FORMAT}"
  read -p "${BLUE_TEXT}${BOLD_TEXT}Please enter the REGION: ${RESET_FORMAT}" REGION
  while [ -z "$REGION" ]; do
    read -p "${RED_TEXT}${BOLD_TEXT}Region cannot be empty. Please enter a valid Google Cloud region: ${RESET_FORMAT}" REGION
  done
  echo "${GREEN_TEXT}Region set to: ${BOLD_TEXT}${REGION}${RESET_FORMAT} (user provided)"
else
  echo "${GREEN_TEXT}Region automatically set to: ${BOLD_TEXT}${REGION}${RESET_FORMAT}"
fi
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling required Google Cloud services. This may take a few moments...${RESET_FORMAT}"
echo "${YELLOW_TEXT}   - Enabling Spanner API (spanner.googleapis.com)${RESET_FORMAT}"
gcloud services enable spanner.googleapis.com
echo "${YELLOW_TEXT}   - Enabling Artifact Registry API (artifactregistry.googleapis.com)${RESET_FORMAT}"
gcloud services enable artifactregistry.googleapis.com
echo "${YELLOW_TEXT}   - Enabling Container Registry API (containerregistry.googleapis.com)${RESET_FORMAT}"
gcloud services enable containerregistry.googleapis.com
echo "${YELLOW_TEXT}   - Enabling Cloud Run API (run.googleapis.com)${RESET_FORMAT}"
gcloud services enable run.googleapis.com
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Giving the services a moment to initialize fully...${RESET_FORMAT}"
for i in $(seq 10 -1 1); do
  echo -ne "${YELLOW_TEXT}   Waiting ${BOLD_TEXT}${i}${RESET_FORMAT}${YELLOW_TEXT} seconds more...\r${RESET_FORMAT}"
  sleep 1
done
echo -ne "\n${GREEN_TEXT}${BOLD_TEXT}Services should now be ready! 👍${RESET_FORMAT}\n"
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Cloning the application repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Navigating into the backend project directory...${RESET_FORMAT}"
cd training-data-analyst/courses/cloud-spanner/omegatrade/backend
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating the .env configuration file with your project details...${RESET_FORMAT}"
cat > .env <<EOF_END
PROJECTID = $DEVSHELL_PROJECT_ID
INSTANCE = omegatrade-instance
DATABASE = omegatrade-db
JWT_KEY = w54p3Y?4dj%8Xqa2jjVC84narhe5Pk
EXPIRE_IN = 30d
EOF_END
echo "${GREEN_TEXT}${BOLD_TEXT}.env file created successfully! ${RESET_FORMAT}"
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Updating npm (Node Package Manager) to the latest version globally...${RESET_FORMAT}"
npm install npm -g
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Installing project dependencies using npm. This might take a while...${RESET_FORMAT}"
echo "${YELLOW_TEXT}(Error logs will be minimized for a cleaner output)${RESET_FORMAT}"
npm install --loglevel=error
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Ensuring npm is at the very latest version...${RESET_FORMAT}"
npm install npm latest
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}再度 Installing project dependencies, just to be sure! 😅${RESET_FORMAT}"
echo "${YELLOW_TEXT}(Minimizing error logs again)${RESET_FORMAT}"
npm install --loglevel=error
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Building the Docker image for the backend application...${RESET_FORMAT}"
echo "${YELLOW_TEXT}This will be tagged as gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1${RESET_FORMAT}"
docker build -t gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1 -f dockerfile.prod .
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Docker to authenticate with Google Cloud Artifact Registry...${RESET_FORMAT}"
gcloud auth configure-docker --quiet
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Pushing the built Docker image to Google Cloud Artifact Registry...${RESET_FORMAT}"
docker push gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying the backend application to Google Cloud Run...${RESET_FORMAT}"
echo "${YELLOW_TEXT}Service name: omegatrade-backend, Region: ${REGION}, Memory: 512Mi, Allow unauthenticated access.${RESET_FORMAT}"
gcloud run deploy omegatrade-backend --platform managed --region $REGION --image gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1 --memory 512Mi --allow-unauthenticated
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Ensuring we use the live Cloud Spanner instance (not an emulator)...${RESET_FORMAT}"
unset SPANNER_EMULATOR_HOST
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Seeding the Cloud Spanner database with initial data...${RESET_FORMAT}"
node seed-data.js
echo



echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
