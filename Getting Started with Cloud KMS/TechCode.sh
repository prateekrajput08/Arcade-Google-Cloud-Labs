#!/bin/bash
set -e

############################
# Config variables
############################
# These are usually pre-set in Qwiklabs, but define them explicitly for safety
PROJECT_ID=$(gcloud config get-value project)
export DEVSHELL_PROJECT_ID="$PROJECT_ID"

# Bucket name from lab text (change if lab shows a different one)
BUCKET_NAME="${PROJECT_ID}-enron_corpus"

# KMS vars
KEYRING_NAME="test"
CRYPTOKEY_NAME="qwiklab"

echo "Using project: $PROJECT_ID"
echo "Bucket name:  $BUCKET_NAME"
echo "KeyRing:      $KEYRING_NAME"
echo "CryptoKey:    $CRYPTOKEY_NAME"
echo

############################
# Task 1: Create bucket
############################
echo "=== Task 1: Create Cloud Storage bucket ==="
gsutil mb "gs://${BUCKET_NAME}"

############################
# Task 2: Review data
############################
echo "=== Task 2: Download and view one email ==="
gsutil cp gs://enron_emails/allen-p/inbox/1. .
echo
echo "Tail of file 1.:"
tail 1.

############################
# Task 3: Enable Cloud KMS
############################
echo
echo "=== Task 3: Enable Cloud KMS API ==="
gcloud services enable cloudkms.googleapis.com

############################
# Task 4: Create KeyRing and CryptoKey
############################
echo
echo "=== Task 4: Create KeyRing and CryptoKey ==="
gcloud kms keyrings create "$KEYRING_NAME" --location=global || echo "KeyRing may already exist; continuing."
gcloud kms keys create "$CRYPTOKEY_NAME" \
  --location=global \
  --keyring="$KEYRING_NAME" \
  --purpose=encryption || echo "CryptoKey may already exist; continuing."

############################
# Task 5: Encrypt one file and upload
############################
echo
echo "=== Task 5: Encrypt single email and upload ==="

# Base64 encode plaintext
PLAINTEXT=$(cat 1. | base64 -w0)

# Encrypt and store ciphertext in 1.encrypted
curl -s "https://cloudkms.googleapis.com/v1/projects/${DEVSHELL_PROJECT_ID}/locations/global/keyRings/${KEYRING_NAME}/cryptoKeys/${CRYPTOKEY_NAME}:encrypt" \
  -d "{\"plaintext\":\"${PLAINTEXT}\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo "Encrypted file saved as 1.encrypted"

# Optional: verify decryption prints original email
echo
echo "Verifying decryption matches original email:"
curl -s "https://cloudkms.googleapis.com/v1/projects/${DEVSHELL_PROJECT_ID}/locations/global/keyRings/${KEYRING_NAME}/cryptoKeys/${CRYPTOKEY_NAME}:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

# Upload the encrypted file to the bucket
echo
echo "Uploading 1.encrypted to Cloud Storage bucket..."
gsutil cp 1.encrypted "gs://${BUCKET_NAME}"

############################
# Task 6: Configure IAM for KMS
############################
echo
echo "=== Task 6: Configure IAM permissions on KeyRing ==="

# Get current user email
USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')
echo "Current user: $USER_EMAIL"

# Grant admin
gcloud kms keyrings add-iam-policy-binding "$KEYRING_NAME" \
  --location=global \
  --member="user:${USER_EMAIL}" \
  --role="roles/cloudkms.admin"

# Grant encrypter/decrypter
gcloud kms keyrings add-iam-policy-binding "$KEYRING_NAME" \
  --location=global \
  --member="user:${USER_EMAIL}" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

############################
# Task 7: Encrypt multiple files and upload
############################
echo
echo "=== Task 7: Encrypt multiple files and upload ==="

# Copy all allen-p emails locally
gsutil -m cp -r gs://enron_emails/allen-p .

MYDIR="allen-p"
FILES=$(find "$MYDIR" -type f -not -name "*.encrypted")

for file in $FILES; do
  echo "Encrypting: $file"
  PLAINTEXT=$(cat "$file" | base64 -w0)
  curl -s "https://cloudkms.googleapis.com/v1/projects/${DEVSHELL_PROJECT_ID}/locations/global/keyRings/${KEYRING_NAME}/cryptoKeys/${CRYPTOKEY_NAME}:encrypt" \
    -d "{\"plaintext\":\"${PLAINTEXT}\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > "${file}.encrypted"
done

echo "Uploading encrypted inbox files to Cloud Storage..."
gsutil -m cp allen-p/inbox/*.encrypted "gs://${BUCKET_NAME}/allen-p/inbox"

echo
echo "All main lab tasks scripted. Now go to Cloud Console:"
echo "- Check Cloud Storage bucket ${BUCKET_NAME} for encrypted files."
echo "- Open Security > Key Management to see keyring and key."
echo "- Use Cloud Overview > Activity or Logs Explorer to view KMS audit logs."
