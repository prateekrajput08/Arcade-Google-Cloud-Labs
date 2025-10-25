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


# Step 1: API Key Creation
echo "${PURPLE}${BOLD}STEP 1: API KEY SETUP ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Creating API Key..."
(gcloud alpha services api-keys create --display-name="cloud-ml-key" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}API Key created successfully!${RESET}"

echo -n "${TEAL}${BOLD}Fetching API Key Name..."
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=cloud-ml-key" 2>/dev/null)
echo -e "\r${LIME}${BOLD}API Key Name: ${DARK_BLUE}$KEY_NAME${RESET}"

echo -n "${TEAL}${BOLD}Fetching API Key String..."
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)" 2>/dev/null)
echo -e "\r${LIME}${BOLD}API Key String retrieved!          ${RESET}"
echo

# Step 2: Project Configuration
echo "${PURPLE}${BOLD}STEP 2: PROJECT CONFIGURATION ${DARK_BLUE}${BOLD}${RESET}"
echo
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="value(projectNumber)")

echo "${LIME}${BOLD}Project ID: ${DARK_BLUE}$PROJECT_ID${RESET}"
echo "${LIME}${BOLD}Project Number: ${DARK_BLUE}$PROJECT_NUMBER${RESET}"
echo

# Step 3: Cloud Storage Setup
echo "${PURPLE}${BOLD}STEP 3: CLOUD STORAGE SETUP ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Creating GCS Bucket..."
(gcloud storage buckets create gs://$DEVSHELL_PROJECT_ID-bucket --project=$DEVSHELL_PROJECT_ID > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}GCS Bucket created: ${DARK_BLUE}gs://$DEVSHELL_PROJECT_ID-bucket${RESET}"

echo -n "${TEAL}${BOLD}Setting IAM permissions..."
(gsutil iam ch projectEditor:serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com:objectCreator gs://$DEVSHELL_PROJECT_ID-bucket > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}IAM permissions configured!${RESET}"
echo

# Step 4: Image Processing
echo "${PURPLE}${BOLD}STEP 4: IMAGE PROCESSING ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Downloading sample image..."
(curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/main/Extract%2C%20Analyze%2C%20and%20Translate%20Text%20from%20Images%20with%20the%20Cloud%20ML%20APIs/sign.jpg > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}Sample image downloaded!${RESET}"

echo -n "${TEAL}${BOLD}Uploading to GCS Bucket..."
(gsutil cp sign.jpg gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}Image uploaded to GCS!${RESET}"

echo -n "${TEAL}${BOLD}Setting public access..."
(gsutil acl ch -u AllUsers:R gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}Public access configured!${RESET}"
echo

# Step 5: Vision API Processing
echo "${PURPLE}${BOLD}STEP 5: VISION API PROCESSING ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Creating OCR request..."
cat > ocr-request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg"
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
echo -e "\r${LIME}${BOLD}OCR request file created!          ${RESET}"

echo -n "${TEAL}${BOLD}Sending to Vision API..."
(curl -s -X POST -H "Content-Type: application/json" --data-binary @ocr-request.json https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o ocr-response.json > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}Vision API response received!          ${RESET}"
echo

# Step 6: Translation API Processing
echo "${PURPLE}${BOLD}STEP 6: TRANSLATION API PROCESSING ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Preparing translation request..."
STR=$(jq -r .responses[0].textAnnotations[0].description ocr-response.json)
cat > translation-request.json <<EOF
{
  "q": "$STR",
  "target": "en"
}
EOF
echo -e "\r${LIME}${BOLD}Translation request prepared!          ${RESET}"

echo -n "${TEAL}${BOLD}Sending to Translation API..."
(curl -s -X POST -H "Content-Type: application/json" --data-binary @translation-request.json https://translation.googleapis.com/language/translate/v2?key=${API_KEY} -o translation-response.json > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}Translation received!          ${RESET}"
echo

# Step 7: Natural Language API Processing
echo "${PURPLE}${BOLD}STEP 7: NATURAL LANGUAGE PROCESSING ${DARK_BLUE}${BOLD}${RESET}"
echo
echo -n "${TEAL}${BOLD}Preparing NL API request..."
TRANSLATED_TEXT=$(jq -r .data.translations[0].translatedText translation-response.json)
cat > nl-request.json <<EOF
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"$TRANSLATED_TEXT"
  },
  "encodingType":"UTF8"
}
EOF
echo -e "\r${LIME}${BOLD}NL API request prepared!          ${RESET}"

echo -n "${TEAL}${BOLD}Sending to Natural Language API..."
(curl -s -X POST -H "Content-Type: application/json" --data-binary @nl-request.json https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY} -o nl-response.json > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}NL API analysis complete!          ${RESET}"
echo

# Display Results
echo "${PURPLE}${BOLD}RESULTS ${DARK_BLUE}${BOLD}${RESET}"
echo
echo "${TEAL}${BOLD}Extracted Text:${RESET}"
jq -r .responses[0].textAnnotations[0].description ocr-response.json
echo

echo "${TEAL}${BOLD}Translation:${RESET}"
jq -r .data.translations[0].translatedText translation-response.json
echo

echo "${TEAL}${BOLD}Entity Analysis:${RESET}"
jq -r .entities[].name nl-response.json 2>/dev/null | uniq
echo


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
