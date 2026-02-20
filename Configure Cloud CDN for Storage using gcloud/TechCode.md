
# 🌐 Configure Cloud CDN for Storage using gcloud 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)]()

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career.Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learningexperience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

<img src="https://media1.tenor.com/m/AbX9FLBPBb4AAAAd/gyani-baba-aap-kahan-the-gyani-baba.gif">
  
## ☁️ Run in Cloud Shell:

```bash
export PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME=${PROJECT_ID}-bucket
BACKEND_BUCKET=static-backend-bucket
URL_MAP=cdn-map
PROXY=cdn-http-proxy
FORWARDING_RULE=cdn-http-rule
gcloud compute backend-buckets create $BACKEND_BUCKET --gcs-bucket-name=$BUCKET_NAME --enable-cdn
gcloud compute url-maps create $URL_MAP --default-backend-bucket=$BACKEND_BUCKET
gcloud compute target-http-proxies create $PROXY --url-map=$URL_MAP
gcloud compute forwarding-rules create $FORWARDING_RULE --global --target-http-proxy=$PROXY --ports=80
gcloud compute forwarding-rules describe $FORWARDING_RULE --global --format="value(IPAddress)"
gsutil ls gs://$BUCKET_NAME/images/
```
```bash
export IP_ADDRESS=
```
```bash
curl -o nature.png http://$IP_ADDRESS/images/nature.png
```

</div>

---
## 🎉 **Congratulations! Lab Completed Successfully!** 🏆

<div style="text-align:center; padding: 10px 0; max-width: 640px; margin: 0 auto;">
  <h3 style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin-bottom: 14px;">📱 Join the Tech & Code Community</h3>
  <a href="https://www.youtube.com/@TechCode9?sub_confirmation=1" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Subscribe-Tech%20&%20Code-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  <a href="https://www.linkedin.com/in/prateekrajput08/" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/LinkedIn-Prateek%20Rajput-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn Profile">
  </a>
  <a href="https://t.me/techcode9" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Telegram-Tech%20Code-0088cc?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Channel">
  </a>
  <a href="https://www.instagram.com/techcodefacilitator" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Instagram-Tech%20Code-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram Profile">
  </a>
</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: January 2026</em>
  </p>
</div>
