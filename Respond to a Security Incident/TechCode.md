# 🌐 Respond to a Security Incident 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)]()

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career.Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learningexperience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

<img src="https://github.com/user-attachments/assets/aa0c8199-7091-46fb-8536-7c1280929b21" alt="nana-patekar-clap" width="314">

<img src="https://github.com/user-attachments/assets/32c75344-3ac9-422f-b10d-49b385db7c37" alt="im-not-sure-gifkaro" width="400">


## ☁️ Run in Cloud Shell:

```bash
gcloud compute firewall-rules delete critical-fw-rule --quiet 2>/dev/null; gcloud compute firewall-rules create critical-fw-rule --network=client-vpc --direction=INGRESS --priority=1000 --action=DENY --rules=tcp:80,tcp:22 --target-tags=compromised-vm --enable-logging
gcloud compute firewall-rules delete allow-ssh-from-bastion --quiet 2>/dev/null; gcloud compute firewall-rules create allow-ssh-from-bastion --network=client-vpc --action allow --direction=ingress --rules tcp:22 --source-ranges=$(gcloud compute instances describe bastion-host --zone=$(gcloud compute instances list --filter="name=bastion-host" --format="get(zone)") --format="get(networkInterfaces[0].accessConfigs[0].natIP)") --target-tags=compromised-vm
gcloud compute networks subnets update my-subnet --region=$(gcloud compute networks subnets list --filter="name=my-subnet" --format="get(region)") --enable-flow-logs
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
