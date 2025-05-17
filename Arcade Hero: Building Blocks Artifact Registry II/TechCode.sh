
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

echo ""
echo ""

# STEP 1: Set region
read -p "Export REGION :- " REGION


# Step 1.2: Set variables
REPO_NAME="container-registry"
FORMAT="DOCKER"
POLICY_NAME="Grandfather"
KEEP_COUNT=3

# Step 2: Create the Artifact Registry repository
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=$FORMAT \
  --location=$REGION \
  --description="Docker repo for container images"

# Step 3: Create cleanup policy named 'Grandfather' to keep only the latest 3 versions
# gcloud artifacts policies create $POLICY_NAME \
#   --repository=$REPO_NAME \
#   --location=$REGION \
#   --package-type=$FORMAT \
#   --keep-count=$KEEP_COUNT \
#   --action=DELETE

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
