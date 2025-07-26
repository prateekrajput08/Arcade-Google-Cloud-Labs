
#!/bin/bash

# Define text colors and formatting
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
clear # Clear the terminal screen


# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


# Instruction for entering the Processor ID
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Please enter your Processor ID:${RESET_FORMAT}"
read -r PROCESSOR_ID
export PROCESSOR_ID

# Instruction before updating and installing dependencies
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${GREEN_TEXT}Updating the system and installing required dependencies.${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install jq -y
sudo apt-get install python3-pip -y

# Instruction before creating a service account
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${GREEN_TEXT}Creating a service account for Document AI and setting up permissions.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
export SA_NAME="document-ai-service-account"
gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:$SA_NAME@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/documentai.apiUser"

gcloud iam service-accounts keys create key.json \
--iam-account  $SA_NAME@${PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="$PWD/key.json"

# Instruction before downloading the sample PDF
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Downloading the sample PDF file for processing.${RESET_FORMAT}"
gsutil cp gs://cloud-training/gsp924/health-intake-form.pdf .

# Instruction before creating the JSON request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${GREEN_TEXT}Preparing the JSON request for Document AI API.${RESET_FORMAT}"
echo '{"inlineDocument": {"mimeType": "application/pdf","content": "' > temp.json
base64 health-intake-form.pdf >> temp.json
echo '"}}' >> temp.json
cat temp.json | tr -d \\n > request.json

# Instruction before sending the API request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${GREEN_TEXT}Sending the request to the Document AI API. This might take some time.${RESET_FORMAT}"
sleep 60
export LOCATION="us"
export PROJECT_ID=$(gcloud config get-value core/project)
curl -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @request.json \
https://${LOCATION}-documentai.googleapis.com/v1beta3/projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}:process > output.json

# Instruction before displaying the output
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${GREEN_TEXT}Displaying the processed document text.${RESET_FORMAT}"
sleep 60
cat output.json | jq -r ".document.text"

# Instruction before downloading the Python script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${GREEN_TEXT}Downloading the Python script for synchronous processing.${RESET_FORMAT}"
gsutil cp gs://cloud-training/gsp924/synchronous_doc_ai.py .

# Instruction before installing Python dependencies
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${GREEN_TEXT}Installing Python dependencies for the script.${RESET_FORMAT}"
python3 -m pip install --upgrade google-cloud-documentai google-cloud-storage prettytable

# Instruction before running the Python script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${GREEN_TEXT}Running the Python script for synchronous processing.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/key.json"

python3 synchronous_doc_ai.py \
--project_id=$PROJECT_ID \
--processor_id=$PROCESSOR_ID \
--location=us \
--file_name=health-intake-form.pdf | tee results.txt

# Instruction before sending another API request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${GREEN_TEXT}Sending another request to the Document AI API for verification.${RESET_FORMAT}"
export LOCATION="us"
export PROJECT_ID=$(gcloud config get-value core/project)
curl -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @request.json \
https://${LOCATION}-documentai.googleapis.com/v1beta3/projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}:process > output.json

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
