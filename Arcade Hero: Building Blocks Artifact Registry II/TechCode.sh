
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

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️  First, we'll identify the default Google Cloud region associated with your project.${RESET_FORMAT}"
 export REGION=$(gcloud compute project-info describe \
 --format="value(commonInstanceMetadata.items[google-compute-default-region])")
 
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️  Next up, we're enabling the Artifact Registry API. This is a necessary step to allow your project to use Artifact Registry for storing and managing packages.${RESET_FORMAT}"
 gcloud services enable artifactregistry.googleapis.com
 
echo "${YELLOW_TEXT}${BOLD_TEXT}📦  Now, let's create a new Docker repository named 'container-registry' within the '$REGION' region. This repository will serve as a secure place to store your Docker container images.${RESET_FORMAT}"
 gcloud artifacts repositories create container-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository in $REGION"
 
echo "${MAGENTA_TEXT}${BOLD_TEXT}🧩  Finally, we'll set up a Go module repository. This repository, named 'go-registry' and located in '$REGION', will be used to host your Go language packages.${RESET_FORMAT}"
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
