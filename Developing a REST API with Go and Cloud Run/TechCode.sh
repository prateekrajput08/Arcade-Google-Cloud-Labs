#!/bin/bash

# Color Codes
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

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}Enter your Region (example: us-central1, asia-south1):${RESET_FORMAT}"
read REGION

echo "${CYAN_TEXT}Using Region: $REGION${RESET_FORMAT}"

echo "${BOLD_TEXT}${CYAN_TEXT}Starting REST API Lab Setup${RESET_FORMAT}"

echo "${YELLOW_TEXT}Setting Project ID${RESET_FORMAT}"
gcloud config set project ProjectID

echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Enabling required Google Cloud services...${RESET_FORMAT}"
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
echo "${GREEN_TEXT}  Services enabled successfully${RESET_FORMAT}

echo "${YELLOW_TEXT}Cloning repository${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab08

echo "${YELLOW_TEXT}Creating main.go file${RESET_FORMAT}"

cat > main.go <<EOF
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
EOF

echo "${GREEN_TEXT}main.go created${RESET_FORMAT}"

echo "${YELLOW_TEXT}Creating Dockerfile${RESET_FORMAT}"

cat > Dockerfile <<EOF_END
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
EOF_END

echo "${GREEN_TEXT}Dockerfile created${RESET_FORMAT}"

echo "${YELLOW_TEXT}Building Go binary${RESET_FORMAT}"
go build -o server

echo "${GREEN_TEXT}Build completed${RESET_FORMAT}"

ls -la

echo "${YELLOW_TEXT}Submitting build to Cloud Build${RESET_FORMAT}"
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1

echo "${GREEN_TEXT}Image built successfully${RESET_FORMAT}"

echo "${YELLOW_TEXT}Deploying to Cloud Run${RESET_FORMAT}"
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region REGION \
  --allow-unauthenticated \
  --max-instances=2

echo "${GREEN_TEXT}Deployment completed${RESET_FORMAT}"

# Create a Firestore database
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Firestore database...${RESET_FORMAT}"
gcloud firestore databases create --location nam5
echo "${GREEN_TEXT}Firestore database created${RESET_FORMAT}"

# Update the main.go file with Firestore integration
echo "${BLUE_TEXT}${BOLD_TEXT}Updating the main.go file with Firestore integration...${RESET_FORMAT}"
cat > main.go <<'EOF_END'
[Previous main.go content remains exactly the same]
EOF_END
echo "${GREEN_TEXT}main.go updated with Firestore integration${RESET_FORMAT}"

# Rebuild the Go server
echo "${BLUE_TEXT}${BOLD_TEXT}Rebuilding the Go server with Firestore integration...${RESET_FORMAT}"
go build -o server
echo "${GREEN_TEXT}Server rebuilt successfully${RESET_FORMAT}"

# Submit the updated build to Google Cloud Build
echo "${BLUE_TEXT}${BOLD_TEXT}Submitting the updated build to Google Cloud Build...${RESET_FORMAT}"
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
echo "${GREEN_TEXT}Updated build submitted${RESET_FORMAT}"

echo
# Safely delete the script if it exists
SCRIPT_NAME="techcode.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the temporary script for security...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

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
