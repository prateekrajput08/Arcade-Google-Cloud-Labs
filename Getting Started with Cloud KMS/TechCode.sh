
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

set -e

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 1 → Creating Cloud Storage Bucket...${RESET_FORMAT}"

if [ -z "$BUCKET_PREFIX" ]; then
  BUCKET_PREFIX=$(echo $DEVSHELL_PROJECT_ID)
fi

BUCKET_NAME="${BUCKET_PREFIX}-enron_corpus"
echo -e "${CYAN_TEXT}Bucket Name: ${YELLOW_TEXT}$BUCKET_NAME${RESET_FORMAT}"

gsutil mb gs://${BUCKET_NAME}

echo -e "${GREEN_TEXT}✔ Bucket created successfully!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 2 → Downloading and previewing sample email file...${RESET_FORMAT}"

gsutil cp gs://enron_emails/allen-p/inbox/1. .

echo -e "${GOLD_TEXT}📄 Preview of file content:${RESET_FORMAT}"
tail 1.
echo -e "${GREEN_TEXT}✔ File preview completed!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 3 → Enabling Cloud KMS API...${RESET_FORMAT}"

gcloud services enable cloudkms.googleapis.com

echo -e "${GREEN_TEXT}✔ Cloud KMS API Enabled!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 4 → Creating KeyRing & CryptoKey...${RESET_FORMAT}"

KEYRING_NAME=test
CRYPTOKEY_NAME=qwiklab

gcloud kms keyrings create $KEYRING_NAME --location global
gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption

echo -e "${GREEN_TEXT}✔ KeyRing & CryptoKey created successfully!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 5 → Encrypting sample file & verifying...${RESET_FORMAT}"

PLAINTEXT=$(cat 1. | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo -e "${CYAN_TEXT}🔐 Decryption verification:${RESET_FORMAT}"
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

gsutil cp 1.encrypted gs://${BUCKET_NAME}

echo -e "${GREEN_TEXT}✔ Sample file encrypted and uploaded to bucket!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 6 → Adding IAM permissions for current user...${RESET_FORMAT}"

USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')

# Admin permission
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.admin

# Encrypt/Decrypt permission
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
  --location global \
  --member user:$USER_EMAIL \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter

echo -e "${GREEN_TEXT}✔ IAM Permissions Added Successfully!${RESET_FORMAT}\n"

echo -e "${TEAL_TEXT}${BOLD_TEXT}TASK 7 → Encrypting all files in allen-p dataset...${RESET_FORMAT}"

gsutil -m cp -r gs://enron_emails/allen-p .

MYDIR=allen-p
FILES=$(find $MYDIR -type f -not -name "*.encrypted")

for file in $FILES; do
  PLAINTEXT=$(cat $file | base64 -w0)
  curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > $file.encrypted
done

gsutil -m cp allen-p/inbox/*.encrypted gs://${BUCKET_NAME}/allen-p/inbox

echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Bulk encryption completed & uploaded to Cloud Storage!${RESET_FORMAT}\n"

echo -e " Check Storage → $BUCKET_NAME → allen-p/inbox"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
