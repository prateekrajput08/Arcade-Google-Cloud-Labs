# 🌐 Get Started with Cloud Storage: Challenge Lab || ARC 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.cloudskillsboost.google/course_templates/725/labs/461639)

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
gsutil mb -c nearline gs://$Bucket_1

gcloud alpha storage buckets update gs://$Bucket_2 --no-uniform-bucket-level-access

gsutil acl ch -u $USER_EMAIL:OWNER gs://$Bucket_2

gsutil rm gs://$Bucket_2/sample.txt

echo "Cloud Storage Demo" > sample.txt

gsutil cp sample.txt gs://$Bucket_2

gsutil acl ch -u allUsers:R gs://$Bucket_2/sample.txt

gcloud storage buckets update gs://$Bucket_3 --update-labels=key=value

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
