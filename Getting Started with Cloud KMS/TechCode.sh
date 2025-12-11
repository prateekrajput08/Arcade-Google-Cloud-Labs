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
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 1 → Creating Cloud Storage Bucket...${RESET_FORMAT}"

BUCKET_PREFIX=${DEVSHELL_PROJECT_ID}
BUCKET_NAME="${BUCKET_PREFIX}-enron_corpus"

echo -e "${CYAN_TEXT}Bucket Name: ${YELLOW_TEXT}$BUCKET_NAME${RESET_FORMAT}"
gsutil mb gs://${BUCKET_NAME} || true

echo -e "${GREEN_TEXT}✔ Bucket created successfully!${RESET_FORMAT}\n"

# =================== TASK 2 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 2 → Downloading sample email file...${RESET_FORMAT}"

# Fix: wildcard download (no list permission needed)
gsutil cp gs://enron_emails/allen-p/inbox/* .

# Select first downloaded file
SAMPLE_FILE=$(ls | head -n 1)

echo -e "${GOLD_TEXT}📄 Preview of file content:${RESET_FORMAT}"
tail "$SAMPLE_FILE"

echo -e "${GREEN_TEXT}✔ File preview completed!${RESET_FORMAT}\n"

# =================== TASK 3 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 3 → Enabling Cloud KMS API...${RESET_FORMAT}"
gcloud services enable cloudkms.googleapis.com
echo -e "${GREEN_TEXT}✔ Cloud KMS API Enabled!${RESET_FORMAT}\n"

# =================== TASK 4 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 4 → Creating KeyRing & CryptoKey...${RESET_FORMAT}"

KEYRING_NAME="test"
CRYPTOKEY_NAME="qwiklab"

gcloud kms keyrings create $KEYRING_NAME --location global || true
gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption || true

echo -e "${GREEN_TEXT}✔ KeyRing & CryptoKey ready!${RESET_FORMAT}\n"

# =================== TASK 5 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 5 → Encrypting & Verifying Sample File...${RESET_FORMAT}"

PLAINTEXT=$(cat "$SAMPLE_FILE" | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > sample.encrypted

echo -e "${CYAN_TEXT}🔐 Verification: Decrypting encrypted file...${RESET_FORMAT}"
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat sample.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

gsutil cp sample.encrypted gs://${BUCKET_NAME}

echo -e "${GREEN_TEXT}✔ Sample encrypted & uploaded!${RESET_FORMAT}\n"

# =================== TASK 6 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 6 → Adding IAM Permissions...${RESET_FORMAT}"

USER_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter

echo -e "${GREEN_TEXT}✔ IAM roles assigned!${RESET_FORMAT}\n"

# =================== TASK 7 ==========================
echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 7 → Bulk Encryption of allen-p Emails...${RESET_FORMAT}"

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

echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Bulk encryption COMPLETE & uploaded!${RESET_FORMAT}\n"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
