#!/bin/bash

# ================= COLOR VARIABLES ==================
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
RESET_FORMAT=$'\033[0m'
# ====================================================

clear
echo "${CYAN_TEXT}${BOLD_TEXT}============================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        TECH & CODE — Cloud KMS Lab Auto Script             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================================${RESET_FORMAT}"
echo

set -e

# =================== TASK 1 ==========================
echo -e "${TEAL}${BOLD}TASK 1 → Creating Cloud Storage Bucket...${RESET}"

BUCKET_NAME="${DEVSHELL_PROJECT_ID}-enron_corpus"

echo -e "${CYAN}Bucket Name: ${YELLOW}$BUCKET_NAME${RESET}"
gsutil mb gs://${BUCKET_NAME} || true

echo -e "${GREEN}✔ Bucket created!${RESET}\n"

# =================== TASK 2 (Simplified) ==========================
echo -e "${TEAL}${BOLD}TASK 2 → Downloading sample email file...${RESET}"

# Download ANY file from inbox (safe even without list permission)
gsutil cp gs://enron_emails/allen-p/inbox/* .

# Pick 1st file automatically (no tail, no preview)
SAMPLE_FILE=$(ls | head -n 1)

echo -e "${GREEN}✔ Sample file downloaded: ${YELLOW}$SAMPLE_FILE${RESET}\n"

# =================== TASK 3 ==========================
echo -e "${TEAL}${BOLD}TASK 3 → Enabling Cloud KMS API...${RESET}"
gcloud services enable cloudkms.googleapis.com
echo -e "${GREEN}✔ KMS API Enabled!${RESET}\n"

# =================== TASK 4 ==========================
echo -e "${TEAL}${BOLD}TASK 4 → Creating KeyRing & CryptoKey...${RESET}"

KEYRING_NAME="test"
CRYPTOKEY_NAME="qwiklab"

gcloud kms keyrings create $KEYRING_NAME --location global || true
gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption || true

echo -e "${GREEN}✔ KeyRing & CryptoKey created!${RESET}\n"

# =================== TASK 5 ==========================
echo -e "${TEAL}${BOLD}TASK 5 → Encrypting & verifying sample file...${RESET}"

PLAINTEXT=$(cat "$SAMPLE_FILE" | base64 -w0)

# Encrypt
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > sample.encrypted

# Upload encrypted sample
gsutil cp sample.encrypted gs://${BUCKET_NAME}

echo -e "${GREEN}✔ Sample file encrypted + uploaded!${RESET}\n"

# =================== TASK 6 ==========================
echo -e "${TEAL}${BOLD}TASK 6 → Adding IAM permissions...${RESET}"

USER_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter

echo -e "${GREEN}✔ IAM permissions added!${RESET}\n"

# =================== TASK 7 ==========================
echo -e "${TEAL}${BOLD}TASK 7 → Bulk encryption of allen-p emails...${RESET}"

gsutil -m cp -r gs://enron_emails/allen-p .

MYDIR="allen-p"
FILES=$(find $MYDIR -type f -not -name "*.encrypted")

for file in $FILES; do
  PLAINTEXT=$(cat "$file" | base64 -w0)
  curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > "$file.encrypted"
done

gsutil -m cp allen-p/inbox/*.encrypted gs://${BUCKET_NAME}/allen-p/inbox/

echo -e "${GREEN}${BOLD}✔ Bulk encryption complete & uploaded!${RESET}\n"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
