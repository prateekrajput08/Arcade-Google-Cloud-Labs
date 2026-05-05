
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

# ================= USER INPUT =================
echo -e "${BOLD_TEXT}Enter Configuration Details:${RESET_FORMAT}"

read -p "ENTER LANGUAGE (e.g., en, fr, es): " LANGUAGE
read -p "ENTER LOCAL (e.g., ja, en_US): " LOCAL
read -p "ENTER BIGQUERY ROLE (e.g., roles/bigquery.admin): " BIGQUERY_ROLE
read -p "ENTER CLOUD STORAGE ROLE (e.g., roles/storage.admin): " CLOUD_STORAGE_ROLE

export LANGUAGE
export LOCAL

# ================= FETCH GCLOUD CONFIG =================
echo ""
echo "${YELLOW_TEXT}Fetching project configuration...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

[ -z "$REGION" ] && REGION="us-central1" && gcloud config set compute/region $REGION
[ -z "$ZONE" ] && ZONE="us-central1-a" && gcloud config set compute/zone $ZONE

SERVICE_ACCOUNT_NAME="ml-api-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
CREDENTIAL_FILE="$HOME/credentials.json"
BUCKET_NAME="${PROJECT_ID}"
DATASET="image_classification_dataset"
TABLE="image_text_detail"

echo "${GREEN_TEXT}✔ Project: ${PROJECT_ID}${RESET_FORMAT}"

# ================= SERVICE ACCOUNT =================
echo "${YELLOW_TEXT}Creating service account...${RESET_FORMAT}"

gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
  --display-name "ML API Service Account" \
  --quiet 2>/dev/null

# ================= IAM ROLES =================
echo "${YELLOW_TEXT}Binding IAM Roles...${RESET_FORMAT}"

ROLES=(
  "$BIGQUERY_ROLE"
  "$CLOUD_STORAGE_ROLE"
  "roles/ml.admin"
  "roles/iam.serviceAccountUser"
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="$ROLE" --quiet
  echo "${GREEN_TEXT}✔ Bound: $ROLE${RESET_FORMAT}"
done

# ================= CREDENTIAL =================
echo "${YELLOW_TEXT}Generating credentials...${RESET_FORMAT}"

gcloud iam service-accounts keys create "$CREDENTIAL_FILE" \
  --iam-account="$SERVICE_ACCOUNT_EMAIL" --quiet

export GOOGLE_APPLICATION_CREDENTIALS="$CREDENTIAL_FILE"

# ================= PYTHON SCRIPT =================
echo "${YELLOW_TEXT}Creating Python script...${RESET_FORMAT}"

cat > "$HOME/analyze-images.py" << PYEOF
import os
from google.cloud import storage, bigquery, vision
from google.cloud import translate_v2 as translate

PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT") or os.popen("gcloud config get-value project").read().strip()
BUCKET_NAME = PROJECT_ID
DATASET_ID = "image_classification_dataset"
TABLE_ID = "image_text_detail"
TARGET_LANG = os.environ.get("LANGUAGE", "en")

storage_client = storage.Client()
bigquery_client = bigquery.Client()
vision_client = vision.ImageAnnotatorClient()
translate_client = translate.Client()

def detect_text(bucket, filename):
    image = vision.Image()
    image.source.image_uri = f"gs://{bucket}/{filename}"
    response = vision_client.text_detection(image=image)

    if response.text_annotations:
        text = response.text_annotations[0]
        return text.locale or "und", text.description.strip()
    return "und", ""

def translate_text(text, src):
    if not text:
        return ""
    return translate_client.translate(text, source_language=src, target_language=TARGET_LANG)["translatedText"]

def process():
    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = bucket.list_blobs()
    rows = []

    for blob in blobs:
        if blob.name.endswith((".jpg", ".png", ".jpeg")):
            print(f"Processing {blob.name}")
            locale, text = detect_text(BUCKET_NAME, blob.name)
            translated = translate_text(text, locale)

            rows.append({
                "file_path": f"gs://{BUCKET_NAME}/{blob.name}",
                "locale": locale,
                "extracted_text": text,
                "translated_text": translated
            })

    return rows

def upload(rows):
    table = bigquery_client.dataset(DATASET_ID).table(TABLE_ID)
    errors = bigquery_client.insert_rows_json(table, rows)
    if errors:
        print("Error:", errors)
    else:
        print("Uploaded to BigQuery")

if __name__ == "__main__":
    data = process()
    upload(data)
PYEOF

# ================= INSTALL PACKAGES =================
echo "${YELLOW_TEXT}Installing dependencies...${RESET_FORMAT}"

pip install -q google-cloud-storage google-cloud-bigquery google-cloud-vision google-cloud-translate

# ================= RUN SCRIPT =================
echo "${YELLOW_TEXT}Running pipeline...${RESET_FORMAT}"

python3 "$HOME/analyze-images.py"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
