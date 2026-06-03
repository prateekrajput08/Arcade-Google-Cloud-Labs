# 🌐 GSP539 - Build Global and Regional Load Balancing Solutions || GSP539 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/games/7225/labs/44716)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">
## Task 1: Secure Internal Transaction Processor

### 1. Create Regional MIG

Go to:
Compute Engine → Instance Groups → Create Instance Group

Create:
- Name: mig-proxy-internal
- Template: template-proxy-internal
- Region: Region B

Add Named Port:
- tcp80 → 80

---

### 2. Create Firewall Rules

Go to:
VPC Network → Firewall

Create:

Rule 1:
```
gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```

Rule 2:
```
gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```
---

### 3. Create Proxy-Only Subnet

Go to:
VPC Network → VPC Networks → lb-network

Create Proxy-only Subnet:
- Name: proxy-subnet-internal
- Region: Region B
- Purpose: Regional Managed Proxy
- Role: Active
- CIDR: 10.129.0.0/23

---

### 4. Create Health Check

Go to:
Network Services → Health Checks

Create:
- Name: hc-internal-proxy
- Protocol: TCP
- Port: 80

---

### 5. Reserve Internal Static IP

Go to:
VPC Network → IP Addresses → Reserve Internal

Create:
- Name: ip-internal-proxy
- Region: Region B
- Network: lb-network
- Subnet: lb-backend-subnet-region-b
- Purpose: Shared Load Balancer VIP

---

### 6. Create Regional Internal Proxy Network Load Balancer

Go to:
Network Services → Load Balancing

Create:
- Type: Regional Internal Proxy Network Load Balancer

Backend:
- Instance Group: mig-proxy-internal
- Named Port: tcp80
- Health Check: hc-internal-proxy

Frontend:
- Name: rule-internal-proxy
- IP Address: ip-internal-proxy
- Protocol: TCP
- Port: 110
- Global Access: Disabled

Create the Load Balancer.

---

### 7. Create Client VM
```
read -p "Enter REGION_A: " REGION_A
read -p "Enter REGION_B: " REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc

source ~/.bashrc

gcloud compute instances create vm-client-internal \
   --zone=${REGION_B}-b \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=lb-backend-subnet-region-b \
   --tags=allow-ssh
```
---

### 8. Validate Access

SSH into vm-client-internal

Test:
```
# Get Internal LB IP
LB_IP=$(gcloud compute addresses describe ip-internal-proxy \
    --region=$REGION_B \
    --format="value(address)")

echo $LB_IP

gcloud compute ssh vm-client-internal \
    --zone="${REGION_B}-b" \
    --command="curl http://$LB_IP:110"
```
Then click:
Check my progress → Create a regional internal proxy NLB

## ☁️ Run in Cloud Shell:

```bash
curl -LO https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Import%20Data%20to%20a%20Firestore%20Database/TechCode.sh
sudo chmod +x TechCode.sh 
./TechCode.sh
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
    <em>Last updated: June 2026</em>
  </p>
</div>
