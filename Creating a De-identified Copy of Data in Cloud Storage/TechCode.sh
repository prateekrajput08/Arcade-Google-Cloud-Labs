#!/bin/bash

RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          SUBSCRIBE TECH & CODE - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting Lab Credentials...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)

INPUT_BUCKET=$(gsutil ls | grep input | head -1 | sed 's#gs://##;s#/##')
OUTPUT_BUCKET=$(gsutil ls | grep output | head -1 | sed 's#gs://##;s#/##')

echo "Input Bucket  : $INPUT_BUCKET"
echo "Output Bucket : $OUTPUT_BUCKET"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a template for unstructured data...${RESET_FORMAT}"
cat > deid_unstruct1.json <<'EOF'
{
  "deidentifyTemplate": {
    "displayName": "deid_unstruct1 template",
    "description": "",
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "primitiveTransformation": {
              "replaceWithInfoTypeConfig": {}
            }
          }
        ]
      }
    }
  },
  "templateId": "deid_unstruct1"
}
EOF

curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
-d @deid_unstruct1.json \
"https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/deidentifyTemplates"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a template for structured data...${RESET_FORMAT}"
cat > deid_struct1.json <<EOF
{
  "deidentifyTemplate": {
    "displayName": "deid_struct1 template",
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              {"name":"ssn"},
              {"name":"ccn"},
              {"name":"email"},
              {"name":"vin"},
              {"name":"id"},
              {"name":"agent_id"},
              {"name":"user_id"}
            ],
            "primitiveTransformation": {
              "replaceConfig": {}
            }
          },
          {
            "fields": [
              {"name":"message"}
            ],
            "infoTypeTransformations": {
              "transformations": [
                {
                  "primitiveTransformation": {
                    "replaceWithInfoTypeConfig": {}
                  }
                }
              ]
            }
          }
        ]
      }
    }
  },
  "templateId": "deid_struct1"
}
EOF

curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
-d @deid_struct1.json \
"https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/deidentifyTemplates"

echo "${YELLOW_TEXT}${BOLD_TEXT}Open Below Link and Follow Video...${RESET_FORMAT}"
echo "https://console.cloud.google.com/security/dlp/"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
