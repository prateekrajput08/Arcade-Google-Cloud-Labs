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
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud auth list

# ── Project & fixed region ──────────────────────────
gcloud config set project $(gcloud projects list \
  --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export DATASET_SERVICE=netflix-dataset-service
export FRONTEND_STAGING_SERVICE=frontend-staging-service
export FRONTEND_PRODUCTION_SERVICE=frontend-production-service
export AR_REPO=rest-api-repo   # Artifact Registry repo name from lab spec

echo "${YELLOW_TEXT}${BOLD_TEXT}Project : $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Region  : $REGION${RESET_FORMAT}"
echo

# ── Enable required APIs ─────────────────────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com

# ── Task 1 : Create Firestore database ───────────────────────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 1] Creating Firestore database in ${REGION}...${RESET_FORMAT}"
gcloud firestore databases create \
  --location=$REGION \
  --project=$DEVSHELL_PROJECT_ID
sleep 10

# ── Task 2 : Import CSV into Firestore ───────────────────────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 2] Importing Netflix CSV into Firestore...${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory.git

cd ~/pet-theory/lab06/firebase-import-csv/solution
npm install
node index.js ../netflix_titles_original.csv

# ── Create Artifact Registry repository ──────────────────────────────────────
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Artifact Registry repository: $AR_REPO...${RESET_FORMAT}"
gcloud artifacts repositories create $AR_REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="REST API repo" || true   # ignore if already exists

gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# ── Task 3 : Deploy REST API v0.1 ────────────────────────────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 3] Building & deploying REST API v0.1...${RESET_FORMAT}"
cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.1 .

gcloud run deploy $DATASET_SERVICE \
  --image ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.1 \
  --allow-unauthenticated \
  --max-instances=1 \
  --region=$REGION

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE \
  --region=$REGION --format='value(status.url)')
echo "${GREEN_TEXT}Service URL: $SERVICE_URL${RESET_FORMAT}"

echo "${YELLOW_TEXT}Testing v0.1 endpoint...${RESET_FORMAT}"
curl -X GET $SERVICE_URL
echo

# ── Task 4 : Deploy REST API v0.2 (Firestore-connected) ──────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 4] Building & deploying REST API v0.2 (Firestore access)...${RESET_FORMAT}"
cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.2 .

gcloud run deploy $DATASET_SERVICE \
  --image ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.2 \
  --allow-unauthenticated \
  --max-instances=1 \
  --region=$REGION

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE \
  --region=$REGION --format='value(status.url)')
echo "${GREEN_TEXT}Service URL: $SERVICE_URL${RESET_FORMAT}"

echo "${YELLOW_TEXT}Testing v0.2 /2019 endpoint...${RESET_FORMAT}"
curl -X GET $SERVICE_URL/2019
echo

# ── Task 5 : Deploy staging frontend ─────────────────────────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 5] Building & deploying staging frontend...${RESET_FORMAT}"

gcloud artifacts repositories create frontend-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Repository for Frontend images" || true

cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/frontend-repo/frontend-staging:0.1 .

gcloud run deploy frontend-staging-service \
    --image=${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/frontend-repo/frontend-staging:0.1 \
    --platform=managed \
    --region=$REGION \
    --allow-unauthenticated \
    --max-instances=1
    
# ── Task 6 : Deploy production frontend ──────────────────────────────────────
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 6] Updating app.js and deploying production frontend...${RESET_FORMAT}"

cd ~/pet-theory/lab06/firebase-frontend/public

sed -i "s|https://netflix-dataset-service-abcdef-uc.a.run.app|$SERVICE_URL|g" app.js

cd ..

# Build the final production image
gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/frontend-repo/frontend-production:0.1 .

# Deploy the live production application
gcloud run deploy frontend-production-service \
    --image=${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/frontend-repo/frontend-production:0.1 \
    --platform=managed \
    --region=$REGION \
    --allow-unauthenticated \
    --max-instances=1

PROD_URL=$(gcloud run services describe frontend-production-service \
  --region=$REGION \
  --format='value(status.url)')
  
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}REST API      : $SERVICE_URL${RESET_FORMAT}"
echo "${GREEN_TEXT}Staging UI    : $STAGING_URL${RESET_FORMAT}"
echo "${GREEN_TEXT}Production UI : $PROD_URL${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
