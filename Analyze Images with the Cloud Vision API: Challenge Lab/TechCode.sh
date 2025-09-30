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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


gcloud alpha services api-keys create --display-name="vision-lab-key" || {
    echo "${RED}Error: Failed to create API key${RESET}"
    exit 1
}

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-lab-key")
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN}${BOLD}✔ Success: API Key created${RESET}"
echo "${WHITE}Key Value: ${YELLOW}$API_KEY${RESET}"
echo ""

gsutil acl ch -u allUsers:R gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg || {
    echo "${RED}Error: Failed to set image permissions${RESET}"
    exit 1
}
echo "${GREEN}Success: Image made publicly readable${RESET}"
echo ""

cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o text-response.json || {
    echo "${RED}Error: Text detection failed${RESET}"
    exit 1
}

gsutil cp text-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}Error: Failed to upload text response${RESET}"
    exit 1
}

echo "${GREEN}Success: Text detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/text-response.json${RESET}"
echo ""

cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LANDMARK_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o landmark-response.json || {
    echo "${RED}Error: Landmark detection failed${RESET}"
    exit 1
}

gsutil cp landmark-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}Error: Failed to upload landmark response${RESET}"
    exit 1
}

echo "${GREEN}Success: Landmark detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/landmark-response.json${RESET}"
echo ""

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}Subscribe to Tech & Code- https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
