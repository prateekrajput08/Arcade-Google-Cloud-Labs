#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

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

# Instructions for API Key
echo "${GOLD_TEXT}${BOLD_TEXT}STEP 1: Enter your Google Cloud API Key:${RESET_FORMAT}"
read -p "${NAVY_TEXT}${BOLD_TEXT}API Key: ${RESET_FORMAT}" USER_API_KEY

# Input Validation
while [[ -z "$USER_API_KEY" ]]; do
    echo "${MAROON_TEXT}${BOLD_TEXT}ERROR: API Key cannot be empty. Please enter a valid API Key.${RESET_FORMAT}"
    read -p "${NAVY_TEXT}${BOLD_TEXT}API Key: ${RESET_FORMAT}" USER_API_KEY
done

export API_KEY="$USER_API_KEY"

echo "${LIME_TEXT}${BOLD_TEXT}API Key Set Successfully!${RESET_FORMAT}"
echo ""

# Taking user input for file names
read -p "${GOLD_TEXT}${BOLD_TEXT}Enter request file name for English: ${RESET_FORMAT}" REQUEST_FILE_A
read -p "${GOLD_TEXT}${BOLD_TEXT}Enter response file name for English: ${RESET_FORMAT}" RESPONSE_FILE_A
read -p "${GOLD_TEXT}${BOLD_TEXT}Enter request file name for Spanish: ${RESET_FORMAT}" REQUEST_FILE_B
read -p "${GOLD_TEXT}${BOLD_TEXT}Enter response file name for Spanish: ${RESET_FORMAT}" RESPONSE_FILE_B

# Display selected file names
echo -e "${LIME_TEXT}${BOLD_TEXT}REQUEST FILE FOR ENGLISH: $REQUEST_FILE_A${RESET_FORMAT}"
echo -e "${LIME_TEXT}${BOLD_TEXT}RESPONSE FILE FOR ENGLISH: $RESPONSE_FILE_A${RESET_FORMAT}"
echo -e "${LIME_TEXT}${BOLD_TEXT}REQUEST FILE FOR SPANISH: $REQUEST_FILE_B${RESET_FORMAT}"
echo -e "${LIME_TEXT}${BOLD_TEXT}RESPONSE FILE FOR SPANISH: $RESPONSE_FILE_B${RESET_FORMAT}"

# Exporting variables
export REQUEST_CP2=$REQUEST_FILE_A
export RESPONSE_CP2=$RESPONSE_FILE_A
export REQUEST_SP_CP3=$REQUEST_FILE_B
export RESPONSE_SP_CP3=$RESPONSE_FILE_B

echo "${GOLD_TEXT}${BOLD_TEXT}STEP 2: Creating Request payload for English Speech Recognition:${RESET_FORMAT}"

cat > "$REQUEST_CP2" <<EOF
{
  "config": {
    "encoding": "LINEAR16",
    "languageCode": "en-US",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://spls/arc131/question_en.wav"
  }
}
EOF

echo "${LIME_TEXT}${BOLD_TEXT}REQUEST FILE CREATED SUCCESSFULLY!${RESET_FORMAT}"

echo "${GOLD_TEXT}${BOLD_TEXT}STEP 3: Sending Request for English Speech Recognition:${RESET_FORMAT}"

curl -s -X POST -H "Content-Type: application/json" --data-binary @"$REQUEST_CP2" \
"https://speech.googleapis.com/v1/speech:recognize?key=$API_KEY" > $RESPONSE_CP2

echo "${LIME_TEXT}${BOLD_TEXT}RESPONSE FILE CREATED SUCCESSFULLY!${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}STEP 4: Creating Request payload for Spanish Speech Recognition:${RESET_FORMAT}"

cat > "$REQUEST_SP_CP3" <<EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "es-ES"
  },
  "audio": {
    "uri": "gs://spls/arc131/multi_es.flac"
  }
}
EOF

echo "${LIME_TEXT}${BOLD_TEXT}REQUEST FILE CREATED SUCCESSFULLY!${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}STEP 5: Sending Request for Spanish Speech Recognition:${RESET_FORMAT}"

curl -s -X POST -H "Content-Type: application/json" --data-binary @"$REQUEST_SP_CP3" \
"https://speech.googleapis.com/v1/speech:recognize?key=$API_KEY" > $RESPONSE_SP_CP3


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
