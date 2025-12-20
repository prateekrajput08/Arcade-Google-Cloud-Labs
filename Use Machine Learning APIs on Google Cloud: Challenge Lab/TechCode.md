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
export PROJECT_ID=$(gcloud config get-value project)
export SA_EMAIL=$(gcloud iam service-accounts list --filter="NOT email ~ .*@developer.gserviceaccount.com" --format="value(email)" | head -n 1)

echo "Using Service Account: $SA_EMAIL"
```
```bash
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/credentials.json
gsutil cp gs://$PROJECT_ID/analyze-images-v2.py .
```
 > TBD: Create a Vision API image object called image_object
```bash
image_object = vision.Image(content=file_content)
```
 > TBD: Detect text in the image and save the response data into an object called response
```bash
response = vision_client.text_detection(image=image_object)
```
 > TBD: According to the target language pass the description data to the translation API
```bash
translation = translate_client.translate(desc, target_language='en')
```
```bash
export PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/serviceusage.serviceUsageConsumer"
```
```bash
gcloud iam service-accounts keys create credentials.json \
    --iam-account=$SA_EMAIL

export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/credentials.json
```
```bash
bq query --use_legacy_sql=false \
'SELECT locale, COUNT(locale) as lcount 
FROM `image_classification_dataset.image_text_detail` 
GROUP BY locale 
ORDER BY lcount DESC'
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
