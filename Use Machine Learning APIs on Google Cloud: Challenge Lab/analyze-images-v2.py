import io
import os
from google.cloud import vision
from google.cloud import translate_v2 as translate
from google.cloud import storage
from google.cloud import bigquery

PROJECT_ID = os.environ["DEVSHELL_PROJECT_ID"]
BUCKET_NAME = PROJECT_ID
DATASET_ID = "image_classification_dataset"
TABLE_ID = "image_text_detail"

vision_client = vision.ImageAnnotatorClient()
translate_client = translate.Client()
storage_client = storage.Client()
bq_client = bigquery.Client()

bucket = storage_client.bucket(BUCKET_NAME)

results = []

# List image files in bucket
blobs = bucket.list_blobs()
image_files = [b.name for b in blobs if b.name.lower().endswith((".jpg", ".png", ".jpeg"))]

for image_name in image_files:
    print(f"Processing: {image_name}")

    blob = bucket.blob(image_name)
    image_bytes = blob.download_as_bytes()

    # =========================
    # Vision API – TEXT DETECT
    # =========================
    image = vision.Image(content=image_bytes)
    response = vision_client.text_detection(image=image)

    if not response.text_annotations:
        continue

    text_annotation = response.text_annotations[0]
    extracted_text = text_annotation.description
    locale = text_annotation.locale if text_annotation.locale else "und"

    # Save extracted text back to Cloud Storage
    text_blob = bucket.blob(f"{image_name}.txt")
    text_blob.upload_from_string(extracted_text, content_type="text/plain")

    translated_text = extracted_text

    # =========================
    # Translation API
    # =========================
    if locale != "ja":
        translation = translate_client.translate(
            extracted_text,
            target_language="ja"
        )
        translated_text = translation["translatedText"]

    results.append({
        "image_name": image_name,
        "locale": locale,
        "extracted_text": extracted_text,
        "translated_text": translated_text
    })

# =========================
# Load results into BigQuery
# =========================
table_ref = bq_client.dataset(DATASET_ID).table(TABLE_ID)
errors = bq_client.insert_rows_json(table_ref, results)

if errors:
    print("BigQuery insert errors:", errors)
else:
    print("SUCCESS: Data loaded into BigQuery")
