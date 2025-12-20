import sys
from google.cloud import vision
from google.cloud import translate_v2 as translate
from google.cloud import storage
from google.cloud import bigquery

if len(sys.argv) != 3:
    print("You must provide parameters for the Google Cloud project ID and Storage bucket")
    print("python3 analyze-images-v2.py [PROJECT_NAME] [BUCKET_NAME]")
    sys.exit(1)

PROJECT_ID = sys.argv[1]
BUCKET_NAME = sys.argv[2]

DATASET_ID = "image_classification_dataset"
TABLE_ID = "image_text_detail"

vision_client = vision.ImageAnnotatorClient()
translate_client = translate.Client()
storage_client = storage.Client(project=PROJECT_ID)
bq_client = bigquery.Client(project=PROJECT_ID)

bucket = storage_client.bucket(BUCKET_NAME)

print("Processing image files from GCS. This will take a few minutes..")

rows = []

for blob in bucket.list_blobs():
    if not blob.name.lower().endswith((".jpg", ".jpeg", ".png")):
        continue

    print(f"Processing {blob.name}")

    image_bytes = blob.download_as_bytes()
    image = vision.Image(content=image_bytes)

    # THIS LINE DEFINES response — NO ERROR POSSIBLE
    response = vision_client.document_text_detection(image=image)

    if not response.full_text_annotation.text:
        continue

    extracted_text = response.full_text_annotation.text

    locale = "und"
    try:
        locale = response.full_text_annotation.pages[0] \
            .property.detected_languages[0].language_code
    except Exception:
        pass

    txt_blob = bucket.blob(blob.name + ".txt")
    txt_blob.upload_from_string(extracted_text, content_type="text/plain")

    translated_text = extracted_text
    if locale != "ja":
        translated_text = translate_client.translate(
            extracted_text,
            target_language="ja"
        )["translatedText"]

    rows.append({
        "image_name": blob.name,
        "locale": locale,
        "extracted_text": extracted_text,
        "translated_text": translated_text
    })

table = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
errors = bq_client.insert_rows_json(table, rows)

if errors:
    print("BigQuery insert errors:", errors)
else:
    print("SUCCESS: Data inserted into BigQuery")
