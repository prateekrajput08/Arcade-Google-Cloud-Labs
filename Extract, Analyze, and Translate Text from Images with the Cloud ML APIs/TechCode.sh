#!/bin/bash

# ================= COLORS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'

# ================= FORMATTING =================
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

clear

# ================= WELCOME =================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ================= STEP 1 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 1: API KEY SETUP${RESET_FORMAT}"
echo

echo -n "${TEAL_TEXT}${BOLD_TEXT}Creating API Key...${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="cloud-ml-key" >/dev/null 2>&1
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}API Key created successfully${RESET_FORMAT}"

KEY_NAME=$(gcloud alpha services api-keys list \
  --format="value(name)" \
  --filter="displayName=cloud-ml-key")

API_KEY=$(gcloud alpha services api-keys get-key-string "$KEY_NAME" \
  --format="value(keyString)")

echo "${GREEN_TEXT}${BOLD_TEXT}API Key fetched successfully${RESET_FORMAT}"
echo

# ================= STEP 2 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 2: PROJECT CONFIGURATION${RESET_FORMAT}"
echo

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" \
  --format="value(projectNumber)")

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${BLUE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Project Number:${RESET_FORMAT} ${BLUE_TEXT}$PROJECT_NUMBER${RESET_FORMAT}"
echo

# ================= STEP 3 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 3: CLOUD STORAGE SETUP${RESET_FORMAT}"
echo

BUCKET_NAME="${PROJECT_ID}-bucket"

gcloud storage buckets create "gs://${BUCKET_NAME}" >/dev/null 2>&1

gsutil iam ch \
  "serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com:objectCreator" \
  "gs://${BUCKET_NAME}" >/dev/null 2>&1

echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Storage bucket configured${RESET_FORMAT}"
echo

# ================= STEP 4 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 4: IMAGE PROCESSING${RESET_FORMAT}"
echo

curl -LO \
https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/main/Extract%2C%20Analyze%2C%20and%20Translate%20Text%20from%20Images%20with%20the%20Cloud%20ML%20APIs/sign.jpg \
>/dev/null 2>&1

gsutil cp sign.jpg "gs://${BUCKET_NAME}/sign.jpg" >/dev/null 2>&1
gsutil acl ch -u AllUsers:R "gs://${BUCKET_NAME}/sign.jpg" >/dev/null 2>&1

echo "${GREEN_TEXT}${BOLD_TEXT}Image uploaded and made public${RESET_FORMAT}"
echo

# ================= STEP 5 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 5: VISION API PROCESSING${RESET_FORMAT}"
echo

cat > ocr-request.json <<EOF
{
  "requests": [{
    "image": {
      "source": {
        "gcsImageUri": "gs://${BUCKET_NAME}/sign.jpg"
      }
    },
    "features": [{
      "type": "TEXT_DETECTION",
      "maxResults": 10
    }]
  }]
}
EOF

curl -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @ocr-request.json \
  "https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" \
  -o ocr-response.json

echo "${GREEN_TEXT}${BOLD_TEXT}Vision API OCR completed${RESET_FORMAT}"
echo

# ================= STEP 6 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 6: TRANSLATION API PROCESSING${RESET_FORMAT}"
echo

TEXT=$(jq -r '.responses[0].textAnnotations[0].description' ocr-response.json)

cat > translation-request.json <<EOF
{
  "q": "$TEXT",
  "target": "en"
}
EOF

curl -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @translation-request.json \
  "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" \
  -o translation-response.json

echo "${GREEN_TEXT}${BOLD_TEXT}Translation completed${RESET_FORMAT}"
echo

# ================= STEP 7 =================
echo "${MAGENTA_TEXT}${BOLD_TEXT}STEP 7: NATURAL LANGUAGE PROCESSING${RESET_FORMAT}"
echo

TRANSLATED_TEXT=$(jq -r '.data.translations[0].translatedText' translation-response.json)

cat > nl-request.json <<EOF
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": "$TRANSLATED_TEXT"
  },
  "encodingType": "UTF8"
}
EOF

curl -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @nl-request.json \
  "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -o nl-response.json

echo "${GREEN_TEXT}${BOLD_TEXT}Natural Language analysis completed${RESET_FORMAT}"
echo

# ================= RESULTS =================
echo "${CYAN_TEXT}${BOLD_TEXT}============= RESULTS =============${RESET_FORMAT}"
echo

echo "${TEAL_TEXT}${BOLD_TEXT}Extracted Text:${RESET_FORMAT}"
jq -r '.responses[0].textAnnotations[0].description' ocr-response.json
echo

echo "${TEAL_TEXT}${BOLD_TEXT}Translated Text:${RESET_FORMAT}"
jq -r '.data.translations[0].translatedText' translation-response.json
echo

echo "${TEAL_TEXT}${BOLD_TEXT}Detected Entities:${RESET_FORMAT}"
jq -r '.entities[].name' nl-response.json 2>/dev/null | uniq
echo

# ================= FINAL =================
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Like, Share and Subscribe for more labs${RESET_FORMAT}"
echo
