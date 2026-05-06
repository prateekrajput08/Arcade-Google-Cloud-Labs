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

echo "${YELLOW_TEXT}${BOLD_TEXT}[STEP 1] Enter Google Cloud API Key${RESET_FORMAT}"
read -p "$(echo -e ${WHITE_TEXT}API Key: ${NO_COLOR})" API_KEY

if [[ -z "$API_KEY" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}[ERROR] API Key cannot be empty.${RESET_FORMAT}"
    exit 1
fi

export API_KEY

echo "${GREEN_TEXT}[SUCCESS] API Key stored successfully.${RESET_FORMAT}"
sleep 1

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}[STEP 2] Creating request.json file...${RESET_FORMAT}"

cat > request.json <<EOF
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": "Joanne Rowling, who writes under the pen names J. K. Rowling and Robert Galbraith, is a British novelist and screenwriter who wrote the Harry Potter fantasy series."
  },
  "encodingType": "UTF8"
}
EOF

echo "${GREEN_TEXT}[SUCCESS] request.json created successfully.${RESET_FORMAT}"
sleep 1

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}[STEP 3] Sending request to Natural Language API...${RESET_FORMAT}"

curl -s -X POST \
-H "Content-Type: application/json" \
"https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
--data-binary @request.json \
-o result.json

echo "${GREEN_TEXT}[SUCCESS] API response saved to result.json${RESET_FORMAT}"
sleep 1

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}[STEP 4] Checking jq installation...${RESET_FORMAT}"

if ! command -v jq &> /dev/null; then
    echo "${RED_TEXT}[WARNING] jq not found.${RESET_FORMAT}"
    echo "${BLUE_TEXT}Installing jq automatically...${RESET_FORMAT}"

    if command -v apt &> /dev/null; then
        sudo apt update -y
        sudo apt install jq -y
    elif command -v yum &> /dev/null; then
        sudo yum install jq -y
    else
        echo "${RED_TEXT}[ERROR] Package manager not supported.${RESET_FORMAT}"
        exit 1
    fi

    echo "${GREEN_TEXT}[SUCCESS] jq installed successfully.${RESET_FORMAT}"
else
    echo "${GREEN_TEXT}[SUCCESS] jq is already installed.${RESET_FORMAT}"
fi

sleep 1

jq -r '
.entities[] |
"Name: \(.name)\nType: \(.type)\nSalience: \(.salience)\nWikipedia: \(.metadata.wikipedia_url // "N/A")\n--------------------------------------"
' result.json

cat result.json

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
