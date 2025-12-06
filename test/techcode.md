# This challenge lab tests your skills and knowledge from the labs in the course, Build a Smart Cloud Application with Vibe Coding.
## Task 1. Enable the necessary APIs
*In this task, you create the project-specific foundation in Google Cloud to support an AI deployment at scale. You ensure your Google Cloud project is configured to allow the required services to function and communicate effectively.
 
For this task, perform the steps that follow.
 
In Cloud Shell, click Open Editor to open the Cloud Shell Editor to your home directory.
In the Cloud Shell Editor action bar, click View > Terminal.
Run the following command for the project setup. (Also in the lab instructions.)
gcloud config set project <filled in at lab start>
 
In the terminal, run the following commands to download and extract the boilerplate code files (copy the command from the lab instructions):
gcloud storage cp gs://<filled in at lab start>-labconfig-bucket/labs_code.zip .
unzip labs_code.zip   
 
## Run the following command to create environment variables (copy the command from the lab instructions): 
```bash
cd ~/zoo_guide_agent
cat <<EOF > .env
MODEL="gemini-2.5-flash"
SERVICE_ACCOUNT="<filled in at lab start>-compute@developer.gserviceaccount.com"
MCP_SERVER_URL="https://zoo-mcp-server-<filled in at lab start>.<filled in at lab start>.run.app/mcp/"
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=<filled in at lab start>
PROJECT_NUMBER=<filled in at lab start>
GOOGLE_CLOUD_LOCATION=<filled in at lab start>
EOF
```
Your final directory structure for mcp-on-cloudrun should look similar to the following:
 
Output:
.
├── mcp-on-cloudrun <br>
│   ├── Dockerfile <br>
│   ├── local_mcp_call.py <br>
│   ├── pyproject.toml <br>
│   ├── server.py <br>
│   └── uv.lock <br>
└── zoo_guide_agent <br>
    ├── agent.py <br>
    ├── __init__.py <br>
    ├── .env <br>
    └── requirements.txt <br>        
 
In the terminal, run the following command to enable the APIs:
```bash
gcloud services enable \
run.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
aiplatform.googleapis.com \
compute.googleapis.com     
```
## Task 2. Perform the necessary policy bindings (IAM setup)
The automated services (Cloud Build and Cloud Run) need specific permissions to interact with each other and the AI Platform.
 
In this task, you must perform the necessary policy bindings to give the user/service account permissions to invoke Cloud Run and use the AI Platform.
 
For this task, perform the following steps.

In the Google Cloud console, go to the IAM page.
Locate the row that contains the principal to whom you want to grant another role, and click Edit principal in that row.
In the Edit permissions pane, click Add another role.
From the Select a role drop-down menu, search for the role(s) instructed in the lab i.e. Cloud Run Admin, then click on the respective role to add it. Click Save. 
Repeat the above steps to add the second role, Vertex AI User.
Task 3. Fix and deploy the MCP Server to Cloud Run
In this task, you must use the Gemini CLI to troubleshoot and revitalize the MCP server, which acts as the application's backbone and orchestrates AI tool use. Once you've fixed the problem(s) in the code, ensure you use the relevant Cloud Build integration command in the Gemini CLI to deploy the preexisting, remote MCP server to the Gemini CLI repository for testing.
Deploy and test locally
For this task, perform the following steps.
 
In the terminal, run the following commands:
cd ~/mcp-on-cloudrun
uv run server.py
 
You will get an error; fix that error using Gemini in Cloud Shell.
In the ~/mcp-on-cloudrun/server.py file, change the following line:
# mcp = FastMCP("Zoo Animal Data MCP Server 🦁🐧🐻")
as follows:
mcp = FastMCP("Zoo Animal Data MCP Server 🦁🐧🐻")
If Gemini CLI attempts to run the fixed code, press ESC to cancel, proceed with the lab.
 
Once you fixed the error, re-run the following; it should start the MCP server locally:
cd ~/mcp-on-cloudrun
uv run server.py
  
Your output should look similar to the following:
Output:
INFO:     Started server process [192759]
INFO:     Waiting for application startup.
[INFO]: StreamableHTTP session manager started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)  
 
Open another terminal and run ~/mcp-on-cloudrun/local_mcp_call.py to test the locally deployed agent:
cd ~/mcp-on-cloudrun   
uv run local_mcp_call.py
 
Note: If you get a google.logging.v2.WriteLogEntriesPartialErrors error, set your project using the gcloud config set <project filled in at lab start> command.
   
Your output should look similar to the following:
Output:

CallToolResult(content=[TextContent(type='text', text='[{"species":"walrus","name":"Wally","age":10,"enclosure":"The Walrus Cove","trail":"Polar Path"},{"species":"walrus","name":"Tusker","age":12,"enclosure":"The Walrus Cove","trail":"Polar Path"},{"species":"walrus","name":"Moby","age":8,"enclosure":"The Walrus Cove","trail":"Polar Path"},{"species":"walrus","name":"Flippers","age":9,"enclosure":"The Walrus Cove","trail":"Polar Path"}]', annotations=None, meta=None)], structured_content={'result': [{'species': 'walrus', 'name': 'Wally', 'age': 10, 'enclosure': 'The Walrus Cove', 'trail': 'Polar Path'}, {'species': 'walrus', 'name': 'Tusker', 'age': 12, 'enclosure': 'The Walrus Cove', 'trail': 'Polar Path'}, {'species': 'walrus', 'name': 'Moby', 'age': 8, 'enclosure': 'The Walrus Cove', 'trail': 'Polar Path'}, {'species': 'walrus', 'name': 'Flippers', 'age': 9, 'enclosure': 'The Walrus Cove', 'trail': 'Polar Path'}]}, data=[Root(), Root(), Root(), Root()], is_error=False)                               
 
Deploy to Cloud Run
Run the following gcloud command to deploy the application to Cloud Run (copy the command from lab instructions):
```bash
cd ~/mcp-on-cloudrun
gcloud run deploy zoo-mcp-server \
    --no-allow-unauthenticated \
    --region=<filled in at lab start> \
    --source=. \
    --min=1 \
    --project=<filled in at lab start> \
    --labels=lab-dev=mcp-zoo-cloud-run-service   
 ```
Task 4. Update the agent to use MCP
In this task, you deploy your Python Agent code and link it to the newly deployed MCP server.
 
Using the ADK commands within the Gemini CLI, deploy the local (updated) agent.py file. Configure this deployment to use the MCP Server deployed in Task 3, making the “zoo tour guide” agent operational within your local CLI environment.
 
Token generation

```bash
Save your Google Cloud credentials and project number in environment variables for use in the Gemini settings file (copy the command from the lab instructions):
export PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)")
export ID_TOKEN=$(gcloud auth print-identity-token)
```
 
Note: If you see an authentication error in Gemini CLI, your ID_TOKEN may have expired. Exit with /quit, set your project using gcloud config set project filled in at lab start command.
   
In Cloud Shell, create and/or update ~/.gemini/settings.json. Replace your Gemini CLI settings file to add the Cloud Run MCP server (copy the command from the lab instructions):
```bash
{
"mcpServers": {
    "zoo-remote": {
    "httpUrl": "https://zoo-mcp-server-filled in at lab start.filled in at lab start.run.app/mcp/",
    "headers": {
        "Authorization": "Bearer $ID_TOKEN"
    }
    }
},
"selectedAuthType": "cloud-shell",
"hasSeenIdeIntegrationNudge": true
}
```
Open the Gemini CLI
Perform the steps that follow.
 
In the terminal, enter the following command:
 
gemini
You may need to press ENTER again to accept some default settings.
 
Issue the following prompt to have Gemini list the MCP tools available to it within its context:
 
/mcp
 
Issue Gemini CLI the following prompt to find something in the zoo:
 
Where can I find penguins?
 
The Gemini CLI should know to use the zoo-remote MCP Server and it should ask if you allow execution of the MCP tool.
 
Use the down arrow, then press ENTER to select: always allow all tools from server "zoo-remote".
 
The output should show the correct answer to the query and a display box showing that the MCP server was used with the fetch_animals_by_species tool.
 
Prompt the CLI to use the new custom command that you created:
 
/find --animal="lion"
 
In the output, Gemini CLI calls the fetch_animals_by_species tool and formats the response as instructed by the MCP prompt.
 
When you are ready to end your session, type /quit and then press ENTER to exit Gemini CLI. Or press CTRL+D or CTRL+C twice to exit.
Verify the server logs
In the terminal, run the following command to verify the server logs:
 
gcloud run services logs read <filled in at lab start> --region <filled in at lab start> --limit=5
 
You should see an output log that confirms a tool call was made. 🛠️
Task 5. Dockerize and deploy the ADK Agent to Cloud Run
For the final task, you must move the entire system from your local testing environment to a scalable, production-ready serverless environment.
 
You need to containerize the complete ADK application, including the MCP server and the Zoo Tour Guide agent, and deploy the resulting container image(s) to Google Cloud Run. You must ensure the service is configured for public invocation and confirm the agent is responsive at its public URL.
Deploy and test locally
Open ~/zoo_guide_agent/agent.py, review the TODO comments, and update the code as follows to complete the agent setup.

In the ~/zoo_guide_agent/agent.py file, change the following:
 
tools=TODO
as follows:
 
tools=[google_search]
 
 
Run the following commands to install the package zoo_guide_agent (copy the command from the lab instructions):
```bash
gcloud config set project qwiklabs-gcp-04-a6266fef991d 
cd ~/zoo_guide_agent 
python -m venv .venv 
source .venv/bin/activate 
pip install --no-cache-dir -r requirements.txt
``` 
Run the following to deploy the Zoo Guide agent to Cloud Run 
```bash
cd ~      
adk web
```
In Cloud Shell, click or CTRL+click the http://localhost:8000 or http://127.0.0.1:8000 link to open the ADK dev UI in a new browser tab.
In the ADK dev UI, select the zoo_guide_agent and ask it a query such as the following:
Where can I find bears?
 
Expected output: You should see events for all function calls, and finally a resolution to your query that combines information from all sources.
Deploy to Cloud Run
In a new terminal, run the following commands to deploy your agent (copy the command from the lab instructions):
```bash
cd ~/zoo_guide_agent     
uvx --from google-adk \
adk deploy cloud_run \
--project=<filled in at lab start>  \
--region=<filled in at lab start> \
--service_name=zoo-tour-guide \
--with_ui \
. \
-- \
--labels=lab-dev=cloud-zoo-run-adk-service
```
Verify the deployed ADK Agent
With your agent now live on Cloud Run, perform a test to confirm a successful deployment and to verify that the agent is working as expected. Use the public Service URL to access the ADK's web interface and interact with the agent.
 
Once you deploy the agent to Cloud Run, CTRL+click the Service URL from the output to open it in a new browser tab.
 
The URL should have this format:
https://zoo-tour-guide-<filled in at lab start>.<filled in at lab start>.run.app/
Because you used the --with_ui flag while deploying to Cloud Run, you should see the ADK developer UI.
 
Toggle Token Streaming to On in the upper right.
 
Interact with the zoo agent. Enter the query that follows to start a new conversation:
Where can I find elephants?
 
Expected output: You should see events for all function calls and information about elephants.
