#!/bin/bash

# =========================================================
#          GOOGLE CLOUD KMS LAB AUTOMATION SCRIPT
# =========================================================

# ------------------ COLOR VARIABLES ------------------ #

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

# ------------------ TEXT FORMATTING ------------------ #

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear
set -e

# =========================================================
#                     WELCOME SCREEN
# =========================================================

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        SUBSCRIBE TECH & CODE - STARTING EXECUTION...             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================================================
#                   VARIABLES
# =========================================================

PROJECT_ID=$(gcloud config get-value project)

export BUCKET_NAME="${PROJECT_ID}-kms_lab"

KEYRING_NAME="labkey"
CRYPTOKEY_NAME="qwiklab"

# =========================================================
#                  ENABLE KMS API
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[1/8] Enabling Cloud KMS API...${RESET_FORMAT}"

gcloud services enable cloudkms.googleapis.com

echo "${GREEN_TEXT}✔ Cloud KMS API Enabled${RESET_FORMAT}"
echo

# =========================================================
#               CREATE STORAGE BUCKET
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[2/8] Creating Cloud Storage Bucket...${RESET_FORMAT}"

gsutil mb gs://${BUCKET_NAME}

echo "${GREEN_TEXT}✔ Bucket Created:${RESET_FORMAT} ${YELLOW_TEXT}${BUCKET_NAME}${RESET_FORMAT}"
echo

# =========================================================
#               DOWNLOAD SAMPLE FILE
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[3/8] Downloading Sample Financial File...${RESET_FORMAT}"

gsutil cp gs://${PROJECT_ID}-kms-lab-data/finance-dept/inbox/1.txt .

echo "${GREEN_TEXT}✔ File Downloaded Successfully${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Sample File Preview:${RESET_FORMAT}"
tail 1.txt
echo

# =========================================================
#             CREATE KEYRING & CRYPTOKEY
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[4/8] Creating KeyRing and CryptoKey...${RESET_FORMAT}"

gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME \
    --location global \
    --keyring $KEYRING_NAME \
    --purpose encryption

echo "${GREEN_TEXT}✔ KeyRing and CryptoKey Created${RESET_FORMAT}"
echo

# =========================================================
#               ENCRYPT SINGLE FILE
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[5/8] Encrypting Sample File...${RESET_FORMAT}"

PLAINTEXT=$(cat 1.txt | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo "${GREEN_TEXT}✔ File Encrypted Successfully${RESET_FORMAT}"
echo

# =========================================================
#               VERIFY DECRYPTION
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Verifying Encrypted File...${RESET_FORMAT}"

curl -s "https://cloudkms.googleapis.com/v1/projects/$PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
    -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

echo
echo "${GREEN_TEXT}✔ Decryption Verified Successfully${RESET_FORMAT}"
echo

# =========================================================
#              UPLOAD ENCRYPTED FILE
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Uploading Encrypted File to Bucket...${RESET_FORMAT}"

gsutil cp 1.encrypted gs://${BUCKET_NAME}

echo "${GREEN_TEXT}✔ File Uploaded Successfully${RESET_FORMAT}"
echo

# =========================================================
#              CONFIGURE IAM PERMISSIONS
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[6/8] Configuring IAM Permissions...${RESET_FORMAT}"

USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.cryptoKeyEncrypterDecrypter

echo "${GREEN_TEXT}✔ IAM Permissions Added${RESET_FORMAT}"
echo

# =========================================================
#             DOWNLOAD COMPLETE DATASET
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[7/8] Downloading Finance Dataset...${RESET_FORMAT}"

gsutil -m cp -r gs://${PROJECT_ID}-kms-lab-data/finance-dept .

echo "${GREEN_TEXT}✔ Dataset Downloaded${RESET_FORMAT}"
echo

# =========================================================
#            ENCRYPT MULTIPLE FILES
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Encrypting Multiple Files...${RESET_FORMAT}"

MYDIR=finance-dept

FILES=$(find $MYDIR -type f -not -name "*.encrypted")

for file in $FILES; do

    echo "${TEAL_TEXT}Encrypting:${RESET_FORMAT} ${WHITE_TEXT}$file${RESET_FORMAT}"

    PLAINTEXT=$(cat "$file" | base64 -w0)

    curl -s "https://cloudkms.googleapis.com/v1/projects/$PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
        -d "{\"plaintext\":\"$PLAINTEXT\"}" \
        -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
        -H "Content-Type:application/json" \
    | jq .ciphertext -r > "$file.encrypted"

done

echo
echo "${GREEN_TEXT}✔ All Files Encrypted Successfully${RESET_FORMAT}"
echo

# =========================================================
#          UPLOAD MULTIPLE ENCRYPTED FILES
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[*] Uploading Encrypted Files to Bucket...${RESET_FORMAT}"

gsutil -m cp finance-dept/inbox/*.encrypted gs://${BUCKET_NAME}/finance-dept/inbox

echo "${GREEN_TEXT}✔ Multiple Files Uploaded Successfully${RESET_FORMAT}"
echo

# =========================================================
#                  AUDIT LOG INSTRUCTIONS
# =========================================================

echo "${BLUE_TEXT}${BOLD_TEXT}[8/8] Cloud Audit Logs Section${RESET_FORMAT}"

echo "${YELLOW_TEXT}"
echo "Go to:"
echo "Navigation Menu > Cloud Overview > Activity"
echo
echo "Then click:"
echo "View Log Explorer"
echo
echo "Select Resource Type:"
echo "Cloud KMS Key Ring"
echo "${RESET_FORMAT}"

# =========================================================
#                   COMPLETION MESSAGE
# =========================================================

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           LAB COMPLETED SUCCESSFULLY ✔               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe ${RESET_FORMAT}"
