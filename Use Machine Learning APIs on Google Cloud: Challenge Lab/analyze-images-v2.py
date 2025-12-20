import sys
import os
from google.cloud import vision
from google.cloud import translate_v2 as translate
from google.cloud import storage
from google.cloud import bigquery

# =========================
# ARGUMENT CHECK
# =========================
if len(sys.argv) != 3:
    print("You must provide parameters for the Google Cloud project ID and Storage bucket")
    print("python3 analyze-images-v2.py [PROJECT_NAME] [BUCKET_NAME]")
    sys.exit(1)

PROJECT_ID = sys.argv[1]
BUCKET_NAME = sys.argv[2]

DATASET_ID = "image_classification_dataset"
TABLE_ID = "image_text_detail"

# =========================
# CLIENTS
# =========================
vision_client = vision.ImageAnnotatorClient()
translate_client = translate.Client()
storage_client = storage.Client(project=PROJECT_ID)
bq_client = bigquery.Client(project=PROJECT_ID)

bucket = storage_client.bucket(BUCKET_NAME)

print("Processing image files from GCS. This will take a few minutes..")

rows_to_insert = []

# =========================
# PROCESS IMAGES
# =========================
for blob in bucket.list_blobs():
    file_name = blob.name.lower()

    if not file_name.endswith((".jpg", ".jpeg", ".png")):
        continue

    print(f"Processing: {blob.name}")

    image_content = blob.download_as_bytes()

    # -------------------------
    # VISION API – TEXT DETECT
    # -------------------------
    image = vision.Image(content=image_content)
    response = vision_client.text_detection(image=image)

    if not response.text_annotations:
        print(f"No text found in {blob.name}")
        continue

    text_data = response.text_annotations[0].description
    locale = response.text_annotations[0].locale or "und"

    # -------------------------
    # SAVE EXTRACTED TEXT TO GCS
    # -------------------------
    text_blob = bucket.blob(blob.name + ".txt")
    text_blob.upload_from_string(text_data, content_type="text/plain")

    translated_text = text_data

    # -------------------------
    # TRANSLATION API (TO JA)
    # -------------------------
    if locale != "ja":
        translation = translate_client.translate(
            text_data,
            target_language="ja"
        )
        translated_text = translation["translatedText"]

    rows_to_insert.append({
        "image_name": blob.name,
        "locale": locale,
        "extracted_text": text_data,
        "translated_text": translated_text
    })

# =========================
# LOAD INTO BIGQUERY
# =========================
table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
errors = bq_client.insert_rows_json(table_ref, rows_to_insert)

if errors:
    print("BigQuery insertion errors:")
    print(errors)
else:
    print("SUCCESS: Data loaded into BigQuery")
