# 🌐 Managing Vault Tokens || GSP1006 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/games/6959/labs/43214)

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
curl -LO raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Managing%20Vault%20Tokens/TechCode.sh
sudo chmod +x TechCode.sh 
./TechCode.sh
```
```bash
#!/bin/bash

run() {
  echo -e "\n\033[1;36m▶ $*\033[0m"
  "$@"
  echo -e "\n\033[1;33mPress ENTER to continue...\033[0m"
  read
}

export VAULT_ADDR='http://127.0.0.1:8200'

printf "\033[1;32mEnter Root Token: \033[0m"
read -s ROOT_TOKEN
echo

export VAULT_TOKEN="$ROOT_TOKEN"

run vault status

run unset VAULT_TOKEN
export VAULT_TOKEN="$ROOT_TOKEN"

# Enable approle (ignore error if already enabled)
run bash -c 'vault auth enable approle || echo "✔ AppRole already enabled"'

run vault write auth/approle/role/jenkins \
  policies="jenkins" \
  period="24h"

# Correct pipeline execution
run bash -c 'vault read -format=json auth/approle/role/jenkins/role-id \
  | jq -r ".data.role_id" > role_id.txt'

run bash -c 'vault write -f -format=json auth/approle/role/jenkins/secret-id \
  | jq -r ".data.secret_id" > secret_id.txt'

ROLE_ID=$(cat role_id.txt)
SECRET_ID=$(cat secret_id.txt)

run vault write auth/approle/login \
  role_id="$ROLE_ID" \
  secret_id="$SECRET_ID"

printf "\033[1;32mEnter Your Token: \033[0m"
read -s YOUR_TOKEN
echo

run vault token lookup "$YOUR_TOKEN"

run bash -c 'vault token lookup -format=json "'"$YOUR_TOKEN"'" \
  | jq -r ".data.policies[]" > token_policies.txt'

PROJECT_ID=$(gcloud config get-value project)

run gsutil cp token_policies.txt gs://$PROJECT_ID

echo -e "\n\033[1;32mAll commands completed. Shell will stay open.\033[0m"
exec bash
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
    <em>Last updated: December 2025</em>
  </p>
</div>
