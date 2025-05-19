
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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}🗺️  Fetching your project's default Google Cloud region. This will be stored and used for resource creation.${RESET_FORMAT}"
 export REGION=$(gcloud compute project-info describe \
 --format="value(commonInstanceMetadata.items[google-compute-default-region])")
 
 echo -e "${GREEN_TEXT}${BOLD_TEXT}⚙️  Activating the Artifact Registry API. This is a one-time setup to enable repository management.${RESET_FORMAT}"
 gcloud services enable artifactregistry.googleapis.com
 
 echo -e "${YELLOW_TEXT}${BOLD_TEXT}🐳  Preparing to create a new Docker repository named 'container-registry' in the '$REGION' region. Your container images will be stored here.${RESET_FORMAT}"
 gcloud artifacts repositories create container-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository in $REGION"
 
 echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🐹  Next, a Go module repository called 'go-registry' will be established in the '$REGION' region for your Go packages.${RESET_FORMAT}"
 gcloud artifacts repositories create go-registry \
  --repository-format=go \
  --location=$REGION \
  --description="Go module repository"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
