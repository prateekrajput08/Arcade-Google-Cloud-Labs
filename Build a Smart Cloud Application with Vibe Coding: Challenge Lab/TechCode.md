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
read -p $'\e[1;36mEnter your student email address (the one used to start the lab): \e[0m' STUDENT_EMAIL

PROJECT_ID=$(gcloud config get-value project)

echo -e "\n\e[1;34m Using Project ID:\e[0m \e[1;33m$PROJECT_ID\e[0m"
echo -e "\e[1;34m Using Student Email:\e[0m \e[1;33m$STUDENT_EMAIL\e[0m\n"

echo -e "\e[1;35mGranting Cloud Run Admin role...\e[0m"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/run.admin" \
  --quiet

echo -e "\e[1;35mGranting Vertex AI User role...\e[0m"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/aiplatform.user" \
  --quiet

echo -e "\n\e[1;32m✅ IAM roles applied successfully for\e[0m \e[1;33m$STUDENT_EMAIL\e[0m \e[1;32mon project\e[0m \e[1;33m$PROJECT_ID\e[0m\n"
```
### *Ask `Gemini` to fix the error
```bash
Fix the error in server.py
```
### Task 5. Dockerize and deploy the ADK agent to Cloud Run
```bash
import os
import logging

import google.adk.framework

from dotenv import load_dotenv
import google.cloud.logging

from langchain_community.tools import WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper
from google.adk.tools.langchain_tool import LangchainTool
from google.adk.agents import Agent, SequentialAgent
from google.adk.tools import google_search
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset, StreamableHTTPConnectionParams
from google.adk.tools.tool_context import ToolContext

import google.auth.transport.requests
import google.oauth2.id_token


# --- Logging and environment setup ---
google.cloud.logging.Client().setup_logging()
load_dotenv()

model_name = os.getenv("MODEL")
if not model_name:
    raise ValueError("MODEL environment variable is not set.")

mcp_server_url = os.getenv("MCP_SERVER_URL")
if not mcp_server_url:
    raise ValueError("MCP_SERVER_URL environment variable is not set.")


# --- Helper function to update the prompt state ---
def add_prompt_to_state(tool_context: ToolContext, prompt: str) -> dict[str, str]:
    tool_context.state["PROMPT"] = prompt
    logging.info(f"[State updated] Added to PROMPT: {prompt}")
    return {"status": "success"}


# --- Function to fetch ID token for MCP auth ---
def get_id_token() -> str:
    audience = mcp_server_url.split("/mcp/")[0]
    request = google.auth.transport.requests.Request()
    return google.oauth2.id_token.fetch_id_token(request, audience)


# --- Setup MCP tools connection ---
mcp_tools = MCPToolset(
    connection_params=StreamableHTTPConnectionParams(
        url=mcp_server_url,
        headers={"Authorization": f"Bearer {get_id_token()}"},
    ),
)


# --- Wikipedia integration ---
wikipedia_tool = LangchainTool(
    tool=WikipediaQueryRun(api_wrapper=WikipediaAPIWrapper())
)


# --- Define Agents ---
comprehensive_researcher = Agent(
    name="comprehensive_researcher",
    model=model_name,
    description="Researches using zoo data (MCP), Wikipedia, and Google Search.",
    instruction="""
    Analyze the PROMPT and gather all required information.
    Use zoo data (via MCP), Wikipedia, and Google Search as needed.
    Summarize your findings as research_data.
    PROMPT:
    {{ PROMPT }}
    """,
    tools=[mcp_tools, wikipedia_tool, google_search],
    output_key="research_data"
)

response_formatter = Agent(
    name="response_formatter",
    model=model_name,
    description="Formats research into a conversational answer.",
    instruction="""
    Format RESEARCH_DATA as a response suitable for a zoo visitor.
    Include zoo facts, fun information, and global animal species count.
    RESEARCH_DATA:
    {{ research_data }}
    """,
    tools=[google_search]
)

tour_guide_workflow = SequentialAgent(
    name="tour_guide_workflow",
    sub_agents=[comprehensive_researcher, response_formatter]
)

root_agent = Agent(
    name="greeter",
    model=model_name,
    description="Initial agent that greets and starts the zoo tour guide sequence.",
    instruction="""
    Greet the visitor and ask which animal they want to learn about.
    Save their query by calling 'add_prompt_to_state', then run 'tour_guide_workflow'.
    """,
    tools=[add_prompt_to_state],
    sub_agents=[tour_guide_workflow]
)


# --- Register the root agent as the application entry point ---
from google.adk.framework.agent import register_agent

register_agent(root_agent)
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
