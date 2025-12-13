# -------------------------------
# Variables
# -------------------------------
KEYRING_NAME=test
CRYPTOKEY_NAME=qwiklab
export BUCKET_NAME="$DEVSHELL_PROJECT_ID-enron_corpus"

# -------------------------------
# Enable KMS API
# -------------------------------
gcloud services enable cloudkms.googleapis.com

# -------------------------------
# Create Cloud Storage bucket
# -------------------------------
gsutil mb gs://${BUCKET_NAME}

# -------------------------------
# Create sample Enron-like email (replacement for blocked enron_emails)
# -------------------------------
echo "Attached is the Delta position for 1/18, 1/31, 6/20, 7/16, 9/24

<< File: west_delta_pos.xls >>

Let me know if you have any questions." > 1.

# Verify plaintext
tail 1.

# -------------------------------
# Create KMS keyring and key
# -------------------------------
gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption

# -------------------------------
# Encrypt single file
# -------------------------------
PLAINTEXT=$(cat 1. | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

# -------------------------------
# Decrypt and verify
# -------------------------------
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

# -------------------------------
# Upload encrypted file
# -------------------------------
gsutil cp 1.encrypted gs://${BUCKET_NAME}

# -------------------------------
# Create allen-p inbox (replacement for blocked gs://enron_emails)
# -------------------------------
mkdir -p allen-p/inbox

echo "Email one content" > allen-p/inbox/1.
echo "Email two content" > allen-p/inbox/2.
echo "Email three content" > allen-p/inbox/3.

# -------------------------------
# Encrypt ALL files in allen-p directory
# -------------------------------
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

# -------------------------------
# Upload encrypted inbox files
# -------------------------------
gsutil -m cp allen-p/inbox/*.encrypted gs://${BUCKET_NAME}/allen-p/inbox
