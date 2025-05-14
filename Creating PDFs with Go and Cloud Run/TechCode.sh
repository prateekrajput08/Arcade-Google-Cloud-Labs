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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}════════════════════════════════════════════════════════${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}════════════════════════════════════════════════════════${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read REGION
export REGION=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required Google Cloud services...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable run.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Listing active Google Cloud account...${RESET_FORMAT}"
gcloud auth list --filter=status:ACTIVE --format="value(account)"

echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the repository...${RESET_FORMAT}"
git clone https://github.com/Deleplace/pet-theory.git

echo "${YELLOW_TEXT}${BOLD_TEXT}Navigating to the lab directory...${RESET_FORMAT}"
cd pet-theory/lab03

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading the server.go file...${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Creating%20PDFs%20with%20Go%20and%20Cloud%20Run/server.go

echo "${YELLOW_TEXT}${BOLD_TEXT}Building the Go application...${RESET_FORMAT}"
go build -o server

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Dockerfile...${RESET_FORMAT}"
cat > Dockerfile <<EOF_END
FROM debian:buster
RUN apt-get update -y \
  && apt-get install -y libreoffice \
  && apt-get clean
WORKDIR /usr/src/app
COPY server .
CMD [ "./server" ]
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Submitting the Cloud Build job...${RESET_FORMAT}"
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter

echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the Cloud Run service...${RESET_FORMAT}"
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region $REGION \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Cloud Storage notification...${RESET_FORMAT}"
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Pub/Sub Cloud Run invoker service account...${RESET_FORMAT}"
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy binding for the Cloud Run service...${RESET_FORMAT}"
gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region $REGION \
  --platform managed

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting the project number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy binding for the Pub/Sub service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator

echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving the Cloud Run service URL...${RESET_FORMAT}"
SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region $REGION \
  --format "value(status.url)")

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Pub/Sub subscription...${RESET_FORMAT}"
gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
