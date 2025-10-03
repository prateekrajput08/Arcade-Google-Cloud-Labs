# 🌐 Enhance Gemini Model Capabilities: Challenge Lab || GSP525 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.cloudskillsboost.google/course_templates/1241/labs/564289)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Task 2:

<ul>1. Define the code execution tool.</ul>

```bash
Tool(code_execution=ToolCodeExecution())
```

<ul>2. Define the prompt with the code to be executed.</ul>

```bash
f"""what is the average price of sneakers in {sneaker_prices}
Generate and run code for the calculation."""
```

---

## Task 3:

<ul>1. Define the Google Search tool.</ul>

```bash
Tool(google_search=GoogleSearch())
```

<ul>3. Generate a response with grounding.</ul>

```bash
GenerateContentConfig(tools=[google_search_tool]),
```

---
## Task 4:

<ul>5. Construct the search query.</ul>

```bash
f"{model} price at {retailer}"
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
