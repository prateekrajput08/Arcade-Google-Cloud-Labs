#!/bin/bash

# Color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

echo "${CYAN_TEXT}${BOLD_TEXT}=== SETTING ENV VARIABLES ===${RESET_FORMAT}"

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

PROJECT_ID=$(gcloud config get-value project)

echo "${YELLOW_TEXT}ZONE: ${ZONE}${RESET_FORMAT}"
echo "${YELLOW_TEXT}REGION: ${REGION}${RESET_FORMAT}"
echo "${YELLOW_TEXT}PROJECT: ${PROJECT_ID}${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}=== NAVIGATING TO SAMPLE APP ===${RESET_FORMAT}"

cd continuous-deployment-on-kubernetes/sample-app

echo "${BLUE_TEXT}Creating new feature branch...${RESET_FORMAT}"

git checkout -b new-feature

echo "${RED_TEXT}Removing old files...${RESET_FORMAT}"

rm Jenkinsfile html.go main.go

echo "${BLUE_TEXT}Downloading updated files...${RESET_FORMAT}"

wget https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Continuous%20Delivery%20with%20Jenkins%20in%20Kubernetes%20Engine/Jenkinsfile
wget https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Continuous%20Delivery%20with%20Jenkins%20in%20Kubernetes%20Engine/html.go
wget https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Continuous%20Delivery%20with%20Jenkins%20in%20Kubernetes%20Engine/main.go

echo "${TEAL}Updating project ID in Jenkinsfile...${RESET_FORMAT}"

sed -i "s/qwiklabs-gcp-01-2848c53eb4b6/$PROJECT_ID/g" Jenkinsfile

echo "${TEAL}Updating zone in Jenkinsfile...${RESET_FORMAT}"

sed -i "s/us-central1-c/$ZONE/g" Jenkinsfile

echo "${BLUE_TEXT}Committing changes...${RESET_FORMAT}"

git add Jenkinsfile html.go main.go
git commit -m "Version 2.0.0"

echo "${GREEN_TEXT}Pushing new-feature branch...${RESET_FORMAT}"

git push origin new-feature

echo "${BLUE_TEXT}Creating canary branch...${RESET_FORMAT}"

git checkout -b canary
git push origin canary

echo "${BLUE_TEXT}Merging canary → master...${RESET_FORMAT}"

git checkout master
git merge canary

echo "${GREEN_TEXT}Pushing master branch...${RESET_FORMAT}"

git push origin master

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
