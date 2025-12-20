# 🌐 Use Machine Learning APIs on Google Cloud: Challenge Lab || GSP329 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.cloudskillsboost.google/course_templates/630/labs/580206)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## ☁️ Run in Cloud Shell:

```bash
curl -LO raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Use%20Machine%20Learning%20APIs%20on%20Google%20Cloud%3A%20Challenge%20Lab/TechCode.sh
sudo chmod +x TechCode.sh 
./TechCode.sh
```
```bash
nano analyze-images-v2.py
```
```bash
import sys
from google.cloud import vision
from google.cloud import translate_v2 as translate
from google.cloud import storage
from google.cloud import bigquery

if len(sys.argv) != 3:
    print("You must provide parameters for the Google Cloud project ID and Storage bucket")
    print("follow techcode python3 analyze-images-v2.py [PROJECT_NAME] [BUCKET_NAME]")
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

print("Processing image files from GCS. This will take a few minutes so subscribe tech code..")

rows = []

for blob in bucket.list_blobs():
    if not blob.name.lower().endswith((".jpg", ".jpeg", ".png")):
        continue

    print(f"Processing {blob.name}")

    image_bytes = blob.download_as_bytes()
    image = vision.Image(content=image_bytes)

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

    # Save extracted text to GCS
    bucket.blob(blob.name + ".txt").upload_from_string(
        extracted_text, content_type="text/plain"
    )

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

# Insert into BigQuery
table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
errors = bq_client.insert_rows_json(table_id, rows)

if errors:
    print("BigQuery insert errors:", errors)
else:
    print("SUCCESS: Tasks 3, 4, 5 completed")
```
```bash
export GOOGLE_APPLICATION_CREDENTIALS=$PWD/sample-sa-key.json
python3 analyze-images-v2.py
```
```bash
SELECT locale, COUNT(locale) AS lcount
FROM image_classification_dataset.image_text_detail
GROUP BY locale
ORDER BY lcount DESC;
```

</div>

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

<div align="center" style="padding: 5px;">
  <h3>📱 Join the Tech & Code Community</h3>
  
  <a href="https://www.youtube.com/@TechCode9?sub_confirmation=1">
    <img src="https://img.shields.io/badge/Subscribe-Tech%20&%20Code-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  &nbsp;
  <a href="https://www.linkedin.com/in/prateekrajput08/">
    <img src="https://img.shields.io/badge/LINKEDIN-Prateek%20Rajput-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
</a>


</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: May 2025</em>
  </p>
</div>
