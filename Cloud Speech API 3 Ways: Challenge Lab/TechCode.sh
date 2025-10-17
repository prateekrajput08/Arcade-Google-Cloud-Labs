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
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# User input for required variables with validation
while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter API Key: ${RESET_FORMAT}" API_KEY
    if [ -n "$API_KEY" ]; then
        break
    else
        echo "${RED_TEXT}API Key cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 2 Call the Text-to-Speech API Storage file name (e.g., synthesize-text.txt): ${RESET_FORMAT}" task_2_file_name
    if [ -n "$task_2_file_name" ]; then
        break
    else
        echo "${RED_TEXT}File name cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 3 request file name (e.g., speech_request.json): ${RESET_FORMAT}" task_3_request_file
    if [ -n "$task_3_request_file" ]; then
        break
    else
        echo "${RED_TEXT}File name cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 3 response file name (e.g., speech_response.json): ${RESET_FORMAT}" task_3_response_file
    if [ -n "$task_3_response_file" ]; then
        break
    else
        echo "${RED_TEXT}File name cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 4 sentence to translate: ${RESET_FORMAT}" task_4_sentence
    if [ -n "$task_4_sentence" ]; then
        break
    else
        echo "${RED_TEXT}Sentence cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 4 output file name (e.g., translation.json): ${RESET_FORMAT}" task_4_file
    if [ -n "$task_4_file" ]; then
        break
    else
        echo "${RED_TEXT}File name cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 5 sentence for language detection: ${RESET_FORMAT}" task_5_sentence
    if [ -n "$task_5_sentence" ]; then
        break
    else
        echo "${RED_TEXT}Sentence cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

while true; do
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 5 output file name (e.g., detection.json): ${RESET_FORMAT}" task_5_file
    if [ -n "$task_5_file" ]; then
        break
    else
        echo "${RED_TEXT}File name cannot be empty. Please try again.${RESET_FORMAT}"
    fi
done

# Export the variables
export API_KEY
export task_2_file_name
export task_3_request_file
export task_3_response_file
export task_4_sentence
export task_4_file
export task_5_sentence
export task_5_file

audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"
export PROJECT_ID=$(gcloud config get-value project)

# Task execution begins
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}Starting task execution...${RESET_FORMAT}"
echo ""

# Task 1: Activate virtual environment
echo "${CYAN_TEXT}Activating virtual environment...${RESET_FORMAT}"
source venv/bin/activate

# Task 2: Text-to-Speech
echo "${CYAN_TEXT}Executing Text-to-Speech conversion...${RESET_FORMAT}"
cat > synthesize-text.json <<EOF
{
'input':{
   'text':'Cloud Text-to-Speech API allows developers to include
      natural-sounding, synthetic human speech as playable audio in
      their applications. The Text-to-Speech API converts text or
      Speech Synthesis Markup Language (SSML) input into audio data
      like MP3 or LINEAR16 (the encoding used in WAV files).'
},
'voice':{
   'languageCode':'en-gb',
   'name':'en-GB-Standard-A',
   'ssmlGender':'FEMALE'
},
'audioConfig':{
   'audioEncoding':'MP3'
}
}
EOF

curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
> "$task_2_file_name"

# Task 3: Speech Recognition
echo "${CYAN_TEXT}Executing Speech Recognition...${RESET_FORMAT}"
cat > "$task_3_request_file" <<EOF
{
"config": {
"encoding": "FLAC",
"sampleRateHertz": 44100,
"languageCode": "fr-FR"
},
"audio": {
"uri": "$audio_uri"
}
}
EOF

curl -s -X POST -H "Content-Type: application/json" \
--data-binary @"$task_3_request_file" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
-o "$task_3_response_file"

# Task 4: Translation
echo "${CYAN_TEXT}Executing Translation...${RESET_FORMAT}"
response=$(curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$task_4_sentence\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en")
echo "$response" > "$task_4_file"

# Task 5: Language Detection
echo "${CYAN_TEXT}Executing Language Detection...${RESET_FORMAT}"
curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": [\"$task_5_sentence\"]}" \
"https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
-o "$task_5_file"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
