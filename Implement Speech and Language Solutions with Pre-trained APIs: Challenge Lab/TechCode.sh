#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          SUBSCRIBE TECH & CODE - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the Following Details...${RESET_FORMAT}"
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter API_KEY: ${RESET_FORMAT}" API_KEY
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_2_file_name: ${RESET_FORMAT}" FILE_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_3_request_file: ${RESET_FORMAT}" REQUEST_FILE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_3_response_file: ${RESET_FORMAT}" RESPONSE_FILE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_4_sentence: ${RESET_FORMAT}" SENTENCE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_4_file: ${RESET_FORMAT}" FILE_NAME_2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_5_sentence: ${RESET_FORMAT}" SENTENCE_2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter task_5_file: ${RESET_FORMAT}  " FILE_NAME_3

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting Project Details...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

echo "${YELLOW_TEXT}${BOLD_TEXT}Working on Lab...${RESET_FORMAT}"
source venv/bin/activate

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
  > $FILE_NAME

cat > tts_decode.py <<EOF
import argparse
from base64 import decodebytes
import json
"""
Usage:
        python tts_decode.py --input "synthesize-text.txt" \
        --output "synthesize-text-audio.mp3"
"""
def decode_tts_output(input_file, output_file):
    """ Decode output from Cloud Text-to-Speech.
    input_file: the response from Cloud Text-to-Speech
    output_file: the name of the audio file to create
    """
    with open(input_file) as input:
        response = json.load(input)
        audio_data = response['audioContent']
        with open(output_file, "wb") as new_file:
            new_file.write(decodebytes(audio_data.encode('utf-8')))
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Decode output from Cloud Text-to-Speech",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--input',
                       help='The response from the Text-to-Speech API.',
                       required=True)
    parser.add_argument('--output',
                       help='The name of the audio file to create',
                       required=True)
    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF

python tts_decode.py --input "$FILE_NAME" --output "synthesize-text-audio.mp3"

audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"

cat > "$REQUEST_FILE" <<EOF
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
    --data-binary @"$REQUEST_FILE" \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
    -o "$RESPONSE_FILE"

sudo apt-get update
sudo apt-get install -y jq

curl "https://translation.googleapis.com/language/translate/v2?target=en&key=${API_KEY}&q=${SENTENCE}" > $FILE_NAME_2

response=$(curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$SENTENCE\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en")
echo "$response" > "$FILE_NAME_2"

decoded_sentence=$(python -c "import urllib.parse; print(urllib.parse.unquote('$SENTENCE_2'))")

curl -s -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{\"q\": [\"$decoded_sentence\"]}" \
  "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
  -o "$FILE_NAME_3"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
