# 🌐 Kickstarting Application Development with Gemini Code Assist: Challenge Lab || GSP527 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/focuses/132354?catalog_rank=%7B%22rank%22%3A1%2C%22num_filters%22%3A0%2C%22has_search%22%3Atrue%7D&parent=catalog&search_id=59224619)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Task-2 `backend/index.test.ts`:

```bash
// Gemini: Write a test for the /outofstock endpoint to verify it returns a status 200 and a list of 2 items.
```
```bash
cd cymbal-superstore/backend
npm install
npm run test
```
## Task-3 `backend/index.ts`:
```bash
// This endpoint should return all out-of-stock products.
```
```bash
npm run test
```
## Task-4 `functions/index.js`:
```bash
// This endpoint should return all products that are out of stock.
```
```bash
cd cymbal-superstore/functions
```
```bash
gcloud functions deploy outofstock --runtime=nodejs20 --trigger-http --entry-point=outofstock --region=us-central1 --allow-unauthenticated
```
```bash
curl http://localhost:PORT/outofstock
```
## Task-5 Create an API Gateway to expose the outofstock Cloud Function
Step 1: Set Environment Variables
```bash
export CONFIG_ID=outofstock-api-config
export API_ID=outofstock-api
export GATEWAY_ID=store
export OPENAPI_SPEC=outofstock.yaml
```
Step 2: Create the gateway Directory and OpenAPI Spec
```bash
mkdir gateway
cd gateway
touch outofstock.yaml
```
Step 3: Generate OpenAPI Specification
```bash
Generate an OpenAPI 2.0 YAML specification for an API Gateway that calls a Cloud Function at https://REGION-PROJECT_ID.cloudfunctions.net/outofstock. The endpoint should be /outofstock and return JSON.
```
Step 4:
```bash
gcloud services enable apigateway.googleapis.com
gcloud api-gateway apis create $API_ID --display-name="Out of Stock API"
gcloud api-gateway api-configs create $CONFIG_ID --api=$API_ID --openapi-spec=outofstock.yaml --display-name="Out of Stock API Config"
gcloud api-gateway gateways create $GATEWAY_ID --api=$API_ID --api-config=$CONFIG_ID --location=us-central1
gcloud api-gateway gateways describe $GATEWAY_ID --location=us-central1

```
**Replace `REGION-PROJECT_ID` with your actual project ID**
Test the gateway by visiting:
```bash
https://defaultHostname/outofstock
```
**Replace `defaultHotname`**
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
    <em>Last updated: November 2025</em>
  </p>
</div>
