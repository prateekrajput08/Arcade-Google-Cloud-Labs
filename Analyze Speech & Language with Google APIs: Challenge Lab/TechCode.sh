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


# Get API Key
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter your Google Cloud API Key: ${RESET_FORMAT}" API_KEY_INPUT
export API_KEY="$API_KEY_INPUT"
echo "${GREEN_TEXT}✓ API Key set successfully${RESET_FORMAT}"
echo

# Natural Language API Request
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Natural Language API Request...${RESET_FORMAT}"
cat > nl_request.json <<EOF
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": "With approximately 8.2 million people residing in Boston, the capital city of Massachusetts is one of the largest in the United States."
  },
  "encodingType": "UTF8"
}
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}Sending request to Natural Language API...${RESET_FORMAT}"
curl "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @nl_request.json > nl_response.json
echo "${GREEN_TEXT}✓ Response saved to nl_response.json${RESET_FORMAT}"

# Speech-to-Text API Request
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Speech-to-Text API Request...${RESET_FORMAT}"
cat > speech_request.json <<EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "en-US"
  },
  "audio": {
    "uri": "gs://cloud-samples-tests/speech/brooklyn.flac"
  }
}
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}Sending request to Speech-to-Text API...${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @speech_request.json \
  "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > speech_response.json
echo "${GREEN_TEXT}✓ Response saved to speech_response.json${RESET_FORMAT}"

# Sentiment Analysis
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up Sentiment Analysis...${RESET_FORMAT}"
cat > sentiment_analysis.py <<EOF
import argparse
from google.cloud import language_v1

def print_result(annotations):
    score = annotations.document_sentiment.score
    magnitude = annotations.document_sentiment.magnitude

    for index, sentence in enumerate(annotations.sentences):
        sentence_sentiment = sentence.sentiment.score
        print(f"Sentence {index} sentiment score: {sentence_sentiment:.2f}")

    print(f"\nOverall Sentiment: Score {score:.2f}, Magnitude {magnitude:.2f}")
    return 0

def analyze(movie_review_filename):
    """Run sentiment analysis on text from a file."""
    client = language_v1.LanguageServiceClient()

    with open(movie_review_filename) as review_file:
        content = review_file.read()

    document = language_v1.Document(
        content=content, 
        type_=language_v1.Document.Type.PLAIN_TEXT
    )
    annotations = client.analyze_sentiment(request={"document": document})
    print_result(annotations)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Perform sentiment analysis on movie reviews",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "movie_review_filename",
        help="Path to the movie review text file"
    )
    args = parser.parse_args()
    analyze(args.movie_review_filename)
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading sample data for analysis...${RESET_FORMAT}"
gsutil cp gs://cloud-samples-tests/natural-language/sentiment-samples.tgz .
gunzip sentiment-samples.tgz
tar -xvf sentiment-samples.tar

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Running Sentiment Analysis on sample review...${RESET_FORMAT}"
python3 sentiment_analysis.py reviews/bladerunner-pos.txt


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
