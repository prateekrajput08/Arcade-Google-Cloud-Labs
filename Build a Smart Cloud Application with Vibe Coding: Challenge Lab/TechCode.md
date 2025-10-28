# 🌐 Build a Smart Cloud Application with Vibe Coding: Challenge Lab || GSP532 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/course_templates/1459/labs/597230)

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
gcloud services enable \
aiplatform.googleapis.com \
artifactregistry.googleapis.com \
compute.googleapis.com \
cloudbuild.googleapis.com \
run.googleapis.com
```

```bash
# Ask for student email once
read -p "Enter your student email address (the one used to start the lab): " STUDENT_EMAIL

# Fetch current project ID from gcloud config
PROJECT_ID=$(gcloud config get-value project)

echo "🔍 Using Project ID: $PROJECT_ID"
echo "👤 Using Student Email: $STUDENT_EMAIL"

# Grant Cloud Run Admin role
echo "Granting Cloud Run Admin role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/run.admin" \
  --quiet

# Grant Vertex AI User role
echo "Granting Vertex AI User role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/aiplatform.user" \
  --quiet

# Confirm applied roles
echo "✅ IAM roles applied successfully for $STUDENT_EMAIL on project $PROJECT_ID"
```
```bash
Fix the error in server.py
```
### If you get permission error in `Task 3`
```bash
python3 ~/mcp-on-cloudrun/local_mcp_call.py
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
    <em>Last updated: October 2025</em>
  </p>
</div>
