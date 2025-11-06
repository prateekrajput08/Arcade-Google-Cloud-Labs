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
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 0: Get the default compute region
echo "${GREEN}${BOLD}Retrieving Default Compute Region${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 1: Enable the Geocoding Backend API
echo -e "${CYAN}${BOLD}Enable the Geocoding Backend API${RESET}"
gcloud services enable geocoding-backend.googleapis.com

# Step 2: Clone the training data analyst repository
echo -e "${YELLOW}${BOLD}Clone the training data analyst repository${RESET}"
git clone --depth 1 https://github.com/GoogleCloudPlatform/training-data-analyst

# Step 3: Create a symbolic link for the Apigee directory
echo -e "${CYAN}${BOLD}Create a symbolic link for the Apigee directory${RESET}"
ln -s ~/training-data-analyst/quests/develop-apis-apigee ~/develop-apis-apigee

# Step 4: Navigate to the rest-backend directory
echo -e "${GREEN}${BOLD}Navigate to the rest-backend directory${RESET}"
cd ~/develop-apis-apigee/rest-backend

# Step 5: Update the configuration file
echo -e "${YELLOW}${BOLD}Update the configuration file to use the ${REGION} region${RESET}"
sed -i "s/us-west1/$REGION/g" config.sh

# Step 6: Display and execute the init-project.sh script
echo -e "${CYAN}${BOLD}Display and execute the init-project.sh script${RESET}"
cat init-project.sh
./init-project.sh

# Step 7: Display and execute the init-service.sh script
echo -e "${GREEN}${BOLD}Display and execute the init-service.sh script${RESET}"
cat init-service.sh
./init-service.sh

# Step 8: Display and execute the deploy.sh script
echo -e "${YELLOW}${BOLD}Display and execute the deploy.sh script${RESET}"
cat deploy.sh
./deploy.sh

# Step 9: Export the REST backend host URL
echo -e "${CYAN}${BOLD}Export the REST backend host URL${RESET}"
export RESTHOST=$(gcloud run services describe simplebank-rest --platform managed --region $REGION --format 'value(status.url)')
echo "export RESTHOST=${RESTHOST}" >> ~/.bashrc

# Step 10: Check the REST service status
echo -e "${GREEN}${BOLD}Check the REST service status${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/_status"

echo

# Step 11: Add a customer record to the REST service
echo -e "${YELLOW}${BOLD}Add a customer record to the REST service${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" -X POST "${RESTHOST}/customers" -d '{"lastName": "Diallo", "firstName": "Temeka", "email": "temeka@example.com"}'

echo

# Step 12: Retrieve customer details
echo -e "${CYAN}${BOLD}Retrieve customer details${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/customers/temeka@example.com"

echo

# Step 13: Import sample data into Firestore
echo -e "${GREEN}${BOLD}Import sample data into Firestore${RESET}"
gcloud firestore import gs://cloud-training/api-dev-quest/firestore/example-data

# Step 14: List all ATMs using the REST service
echo -e "${YELLOW}${BOLD}List all ATMs using the REST service${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/atms"

echo

# Step 15: Retrieve a specific ATM's details
echo -e "${CYAN}${BOLD}Retrieve a specific ATM's details${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/atms/spruce-goose"

echo

# Step 16: Create a service account for Apigee internal access
echo -e "${GREEN}${BOLD}Create a service account for Apigee internal access${RESET}"
gcloud iam service-accounts create apigee-internal-access \
--display-name="Service account for internal access by Apigee proxies" \
--project=${GOOGLE_CLOUD_PROJECT}

# Step 17: Add IAM policy binding to the REST service
echo -e "${YELLOW}${BOLD}Add IAM policy binding to the REST service${RESET}"
gcloud run services add-iam-policy-binding simplebank-rest \
--member="serviceAccount:apigee-internal-access@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
--role=roles/run.invoker --region=$REGION \
--project=${GOOGLE_CLOUD_PROJECT}

# Step 18: Get the REST service URL
echo -e "${CYAN}${BOLD}Get the REST service URL${RESET}"
gcloud run services describe simplebank-rest --platform managed --region $REGION --format 'value(status.url)'

# Step 19: Create an API key for the Geocoding API
echo -e "${GREEN}${BOLD}Create an API key for the Geocoding API${RESET}"
API_KEY=$(gcloud alpha services api-keys create --project=${GOOGLE_CLOUD_PROJECT} --display-name="Geocoding API key for Apigee" --api-target=service=geocoding_backend --format "value(response.keyString)")
echo "export API_KEY=${API_KEY}" >> ~/.bashrc
echo "API_KEY=${API_KEY}"

# Step 20: Monitor runtime instance and attach environment
echo -e "${YELLOW}${BOLD}Monitor runtime instance and attach environment${RESET}"
export INSTANCE_NAME=eval-instance; export ENV_NAME=eval; export PREV_INSTANCE_STATE=; echo "waiting for runtime instance ${INSTANCE_NAME} to be active"; while : ; do export INSTANCE_STATE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}" | jq "select(.state != null) | .state" --raw-output); [[ "${INSTANCE_STATE}" == "${PREV_INSTANCE_STATE}" ]] || (echo; echo "INSTANCE_STATE=${INSTANCE_STATE}"); export PREV_INSTANCE_STATE=${INSTANCE_STATE}; [[ "${INSTANCE_STATE}" != "ACTIVE" ]] || break; echo -n "."; sleep 5; done; echo; echo "instance created, waiting for environment ${ENV_NAME} to be attached to instance"; while : ; do export ATTACHMENT_DONE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}/attachments" | jq "select(.attachments != null) | .attachments[] | select(.environment == \"${ENV_NAME}\") | .environment" --join-output); [[ "${ATTACHMENT_DONE}" != "${ENV_NAME}" ]] || break; echo -n "."; sleep 5; done; echo "***ORG IS READY TO USE***";

echo

# Provide the Apigee proxy creation URL
echo -e "${BLUE}${BOLD}Go to this link to create an Apigee proxy: ${RESET}""https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"

echo

# Display backend URL and service account details
echo -e "${YELLOW}${BOLD}Backend URL: ${RESET}""$(gcloud run services describe simplebank-rest --platform managed --region $REGION --format='value(status.url)')"

echo

echo -e "${CYAN}${BOLD}Copy this service account: ${RESET}""apigee-internal-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

echo

echo -e "${GREEN}${BOLD}Copy this API KEY: ${RESET}""apikey=${API_KEY}"

echo

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
