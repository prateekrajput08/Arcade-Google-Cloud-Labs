# 🌐 Reconciling Account Data with Cloud Spanner Change Streams || GSP1097 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.cloudskillsboost.google/games/6466/labs/40652)

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
curl -LO raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Reconciling%20Account%20Data%20with%20Cloud%20Spanner%20Change%20Streams/TechCode.sh
sudo chmod +x TechCode.sh 
./TechCode.sh
```
## Paste in spanner studio
```bash
INSERT INTO
 Account (AccountId,
   CreationTimestamp,
   AccountStatus,
   Balance)
VALUES
 (FROM_BASE64('ACCOUNTID11123'),
   PENDING_COMMIT_TIMESTAMP(),
   1,
   22);

 UPDATE
 Account
SET
 CreationTimestamp=PENDING_COMMIT_TIMESTAMP(),
 AccountStatus=4,
 Balance=255
WHERE
 AccountId=FROM_BASE64('ACCOUNTID11123');

 UPDATE
 Account
SET
 CreationTimestamp=PENDING_COMMIT_TIMESTAMP(),
 AccountStatus=4,
 Balance=300
WHERE
 AccountId=FROM_BASE64('ACCOUNTID11123');

 UPDATE
 Account
SET
 CreationTimestamp=PENDING_COMMIT_TIMESTAMP(),
 AccountStatus=4,
 Balance=500
WHERE
 AccountId=FROM_BASE64('ACCOUNTID11123');

 UPDATE
 Account
SET
 CreationTimestamp=PENDING_COMMIT_TIMESTAMP(),
 AccountStatus=4,
 Balance=600
WHERE
 AccountId=FROM_BASE64('ACCOUNTID11123');
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
