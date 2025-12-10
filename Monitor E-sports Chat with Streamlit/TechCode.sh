#!/bin/bash

###############################################################################
# GSP1343 - Monitor E-sports Chat with Streamlit
# One-time setup script for Qwiklabs / Google Cloud Skills Boost lab
#
# This script automates:
# - Task 1: Env vars
# - Task 2: BigQuery dataset & tables, Bigtable instance & table
# - Task 3: Pub/Sub topic + BigQuery subscription + BQ permissions
# - Task 4: Pub/Sub Publisher IAM on compute service account
# - Task 5: Download Python files + copy message_generator.py to GCS bucket
# - Task 7 (part): Create BigQuery↔Vertex AI connection + grant Vertex AI User
# - Task 7 (part): Create BigQuery remote model pointing to Gemini
# - Task 8 (part): Prep Bigtable app profile priority to LOW for EXPORT DATA
#
# Manual steps still needed after this script:
# - Start message_generator.py (synthetic data generator)
# - Run the continuous queries in BigQuery (ML.GENERATE_TEXT + EXPORT DATA)
# - Query tables to verify results
# - Create venv + run Streamlit app (app.py)
###############################################################################

set -euo pipefail

# ----- Colors for nicer output -----
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET=$'\033[0m'

log() {
  echo "${CYAN_TEXT}[*]${RESET} $*"
}

ok() {
  echo "${GREEN_TEXT}[✓]${RESET} $*"
}

warn() {
  echo "${YELLOW_TEXT}[!]${RESET} $*"
}

err() {
  echo "${RED_TEXT}[✗]${RESET} $*" >&2
}

###############################################################################
# Task 1. Configure environment variables
###############################################################################

log "Task 1: Configuring environment variables..."

# Try to detect project from gcloud config; if not set, prompt.
GCP_PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
if [[ -z "${GCP_PROJECT_ID}" || "${GCP_PROJECT_ID}" == "(unset)" ]]; then
  read -rp "Enter your Qwiklabs PROJECT_ID (value shown as 'Project ID' at lab start): " GCP_PROJECT_ID
  gcloud config set project "${GCP_PROJECT_ID}"
else
  log "Using existing gcloud project: ${GCP_PROJECT_ID}"
fi

# Ask for Region (exactly as shown in lab, e.g. us-central1, europe-west1)
if [[ -z "${GCP_REGION:-}" ]]; then
  read -rp "Enter the lab REGION (e.g. us-central1, europe-west1): " GCP_REGION
fi

# BUCKET_NAME uses the convention from the lab: ProjectID-bucket
BUCKET_NAME="${GCP_PROJECT_ID}-bucket"

# Ask for Gemini model id to use in BigQuery remote model
# Example: projects/PROJECT_ID/locations/REGION/publishers/google/models/gemini-1.5-flash-002
if [[ -z "${GEMINI_MODEL_ID:-}" ]]; then
  echo
  echo "Enter GEMINI model endpoint name to use in BigQuery remote model."
  echo "Example:"
  echo "  projects/${GCP_PROJECT_ID}/locations/${GCP_REGION}/publishers/google/models/gemini-1.5-flash-002"
  read -rp "GEMINI_MODEL_ID: " GEMINI_MODEL_ID
fi

export GCP_PROJECT_ID GCP_REGION BUCKET_NAME GEMINI_MODEL_ID

ok "Env vars set:
  GCP_PROJECT_ID=${GCP_PROJECT_ID}
  GCP_REGION=${GCP_REGION}
  BUCKET_NAME=${BUCKET_NAME}
  GEMINI_MODEL_ID=${GEMINI_MODEL_ID}
"

gcloud config set project "${GCP_PROJECT_ID}" >/dev/null

###############################################################################
# Enable required APIs
###############################################################################
log "Enabling required APIs (BigQuery, Bigtable, Pub/Sub, Vertex AI, Connections)..."

gcloud services enable \
  bigquery.googleapis.com \
  bigqueryconnection.googleapis.com \
  bigtableadmin.googleapis.com \
  pubsub.googleapis.com \
  aiplatform.googleapis.com \
  storage.googleapis.com >/dev/null

ok "Required APIs enabled (or already enabled)."

###############################################################################
# Create GCS bucket for the lab (used in Task 5 verification)
###############################################################################
log "Checking/creating GCS bucket gs://${BUCKET_NAME} ..."

if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  warn "Bucket gs://${BUCKET_NAME} already exists, skipping creation."
else
  gsutil mb -l "${GCP_REGION}" "gs://${BUCKET_NAME}"
  ok "Created bucket gs://${BUCKET_NAME}"
fi

###############################################################################
# Task 2. Create BigQuery dataset & tables + Bigtable instance & table
###############################################################################

log "Task 2: Creating BigQuery dataset esports_analytics..."

if bq --location="${GCP_REGION}" ls -d | grep -q "^ *esports_analytics"; then
  warn "Dataset esports_analytics already exists, skipping."
else
  bq --location="${GCP_REGION}" mk -d esports_analytics
  ok "Dataset esports_analytics created."
fi

log "Creating BigQuery table esports_analytics.raw_chat_messages..."

if bq ls esports_analytics | grep -q "^ *raw_chat_messages"; then
  warn "Table raw_chat_messages already exists, skipping."
else
  bq mk --table esports_analytics.raw_chat_messages \
    message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,game_id:STRING,server_region:STRING
  ok "Table esports_analytics.raw_chat_messages created."
fi

log "Creating BigQuery table esports_analytics.unsportsmanlike_messages..."

if bq ls esports_analytics | grep -q "^ *unsportsmanlike_messages"; then
  warn "Table unsportsmanlike_messages already exists, skipping."
else
  bq mk \
    --table \
    --description "Table to store unsportsmanlike messages from esports analytics." \
    --time_partitioning_field timestamp \
    --time_partitioning_type DAY \
    esports_analytics.unsportsmanlike_messages \
    message_id:STRING,user_id:STRING,timestamp:TIMESTAMP,message_text:STRING,message_type:STRING,game_id:STRING,server_region:STRING
  ok "Table esports_analytics.unsportsmanlike_messages created."
fi

log "Creating Bigtable instance 'instance' with cluster 'my-cluster'..."

if gcloud bigtable instances list --format="value(name)" | grep -q "^instance$"; then
  warn "Bigtable instance 'instance' already exists, skipping."
else
  gcloud bigtable instances create instance \
    --display-name="My Bigtable Instance" \
    --cluster-config=id=my-cluster,zone="${GCP_REGION}-b",nodes=1
  ok "Bigtable instance 'instance' created."
fi

log "Creating Bigtable table 'unsportsmanlike' with column family 'messages'..."

# cbt might already have config; we pass project & instance explicitly for safety
if cbt -project "${GCP_PROJECT_ID}" -instance instance ls | grep -q "^unsportsmanlike$"; then
  warn "Bigtable table 'unsportsmanlike' already exists, skipping."
else
  cbt -project "${GCP_PROJECT_ID}" -instance instance createtable unsportsmanlike families=messages
  ok "Bigtable table 'unsportsmanlike' created."
fi

###############################################################################
# Task 3. Pub/Sub Topic and Subscription -> BigQuery
###############################################################################

log "Task 3: Creating Pub/Sub topic & BigQuery subscription..."

if gcloud pubsub topics list --format="value(name)" | grep -q "topics/esports_messages_topic$"; then
  warn "Pub/Sub topic esports_messages_topic already exists, skipping."
else
  gcloud pubsub topics create esports_messages_topic
  ok "Created topic esports_messages_topic."
fi

PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT_ID}" --format='value(projectNumber)')"

# Grant BigQuery Data Editor to Pub/Sub service agent so it can write to the table
PUBSUB_SA="service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"
log "Granting BigQuery Data Editor to Pub/Sub service account ${PUBSUB_SA}..."

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${PUBSUB_SA}" \
  --role="roles/bigquery.dataEditor" \
  --quiet >/dev/null || warn "Pub/Sub SA IAM binding may already exist."

ok "Pub/Sub service account has BigQuery Data Editor at project-level."

# Create subscription that writes directly to BigQuery raw_chat_messages
if gcloud pubsub subscriptions list --format="value(name)" | grep -q "subscriptions/esports_messages_topic-sub$"; then
  warn "Subscription esports_messages_topic-sub already exists, skipping."
else
  gcloud pubsub subscriptions create esports_messages_topic-sub \
    --topic=esports_messages_topic \
    --bigquery-table="${GCP_PROJECT_ID}:esports_analytics.raw_chat_messages" \
    --use-table-schema
  ok "Subscription esports_messages_topic-sub created and configured to write to BigQuery."
fi

###############################################################################
# Task 4. Grant Pub/Sub IAM permissions to compute service account
###############################################################################

log "Task 4: Grant Pub/Sub Publisher to default compute service account..."

COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/pubsub.publisher" \
  --quiet >/dev/null || warn "Compute SA IAM binding may already exist."

ok "Compute service account ${COMPUTE_SA} now has Pub/Sub Publisher."

###############################################################################
# Task 5. Retrieve Python files and copy message_generator.py to GCS
###############################################################################

log "Task 5: Downloading Python files (message_generator.py, app.py, requirements.txt)..."

mkdir -p "${HOME}/esports"
cd "${HOME}/esports"

# Download if missing
[[ -f message_generator.py ]] || wget -q https://storage.googleapis.com/spls/gsp1343/v2/message_generator.py
[[ -f app.py ]]               || wget -q https://storage.googleapis.com/spls/gsp1343/v2/app.py
[[ -f requirements.txt ]]     || wget -q https://storage.googleapis.com/spls/gsp1343/v2/requirements.txt

ok "Python files downloaded to ${HOME}/esports"

log "Copying message_generator.py to gs://${BUCKET_NAME} for 'Check my progress'..."

gsutil cp "${HOME}/esports/message_generator.py" "gs://${BUCKET_NAME}" >/dev/null

ok "message_generator.py copied to gs://${BUCKET_NAME}"

###############################################################################
# Task 6 (part). Install Pub/Sub Python library (for generator)
###############################################################################

log "Installing google-cloud-pubsub for the message generator (system Python)..."

pip install --user google-cloud-pubsub >/dev/null

ok "google-cloud-pubsub installed (pip --user)."

###############################################################################
# Task 7 (part). Create Vertex AI connection + BigQuery remote model
###############################################################################

log "Task 7: Creating BigQuery Cloud Resource connection for Vertex AI..."

# Create connection esports_qwiklab in the given region
if bq ls --connections --location="${GCP_REGION}" 2>/dev/null | grep -q "esports_qwiklab"; then
  warn "Connection esports_qwiklab already exists, skipping creation."
else
  bq mk --connection \
    --location="${GCP_REGION}" \
    --project_id="${GCP_PROJECT_ID}" \
    --connection_type=CLOUD_RESOURCE \
    esports_qwiklab
  ok "Connection esports_qwiklab created."
fi

log "Retrieving connection service account for esports_qwiklab..."

# We request JSON and try both possible locations for serviceAccountId
CONNECTION_JSON="$(bq show --connection --format=json "${GCP_PROJECT_ID}.${GCP_REGION}.esports_qwiklab")"
CONN_SA="$(python3 - << 'PY'
import json, os, sys
data = json.loads(os.environ["CONNECTION_JSON"])
# Try cloudResource.serviceAccountId then properties.serviceAccountId
sa = ""
if isinstance(data, dict):
    sa = (data.get("cloudResource", {}) or {}).get("serviceAccountId") or \
         (data.get("properties", {}) or {}).get("serviceAccountId") or ""
print(sa)
PY
)"
unset CONNECTION_JSON

if [[ -z "${CONN_SA}" ]]; then
  warn "Could not automatically detect connection service account. You may need to grant Vertex AI User manually in IAM."
else
  log "Granting Vertex AI User (roles/aiplatform.user) to ${CONN_SA}..."
  gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member="serviceAccount:${CONN_SA}" \
    --role="roles/aiplatform.user" \
    --quiet >/dev/null || warn "Vertex AI User role may already be bound."
  ok "Connection service account now has Vertex AI User."
fi

log "Creating BigQuery ML remote model esports_analytics.gemini_model..."

# We use modern syntax with remote_service_type for LLM remote models
bq query --use_legacy_sql=false <<EOF
CREATE OR REPLACE MODEL \`${GCP_PROJECT_ID}.esports_analytics.gemini_model\`
REMOTE WITH CONNECTION \`${GCP_PROJECT_ID}.${GCP_REGION}.esports_qwiklab\`
OPTIONS (
  remote_service_type = 'CLOUD_AI_LARGE_LANGUAGE_MODEL_V1',
  endpoint = '${GEMINI_MODEL_ID}'
);
EOF

ok "Remote model esports_analytics.gemini_model created."

###############################################################################
# Task 8 (part). Set Bigtable default app profile priority to LOW
# to avoid EXPORT DATA error about PRIORITY_HIGH.
###############################################################################

log "Setting Bigtable default application profile priority to PRIORITY_LOW..."

# default app profile id is 'default'
# Note: we use --route-any just to satisfy required routing flag; instance has only one cluster.
gcloud bigtable app-profiles update default \
  --instance=instance \
  --route-any \
  --priority=PRIORITY_LOW >/dev/null || warn "Could not update app profile; please verify manually in Bigtable UI."

ok "Bigtable default app profile now uses LOW priority (or was already configured)."

###############################################################################
# All automated steps done
###############################################################################

echo
echo "====================================================================="
echo "${GREEN_TEXT}Automated setup complete for GSP1343.${RESET}"
echo "Now follow these MANUAL steps to finish the lab:"
echo "====================================================================="
echo

cat <<'MANUAL_STEPS'
1) Task 6: Run the synthetic data generator (Cloud Shell)
--------------------------------------------------------
In Cloud Shell:

  cd ~/esports
  python3 message_generator.py

Leave this terminal TAB running; it will continuously publish chat events
into the Pub/Sub topic.

2) Task 8: BigQuery queries (via BigQuery Console or bq CLI)
------------------------------------------------------------

a. Confirm raw_chat_messages is receiving data:

  SELECT * FROM `YOUR_PROJECT_ID.esports_analytics.raw_chat_messages`
  LIMIT 1000;

(Replace YOUR_PROJECT_ID with the project ID shown at lab start.)

b. Create the continuous query inserting into unsportsmanlike_messages:

Use BigQuery Console (recommended):

  - Click "+ New Query" and paste the lab's INSERT+ML.GENERATE_TEXT query,
    replacing:
      set at lab start   -> YOUR_PROJECT_ID
      Region             -> your region (e.g. us-central1)
  - In "More" / "More settings", choose:
      Query mode: Continuous query
  - Run the query and leave it running.

The query text from the lab (update the project placeholder):

  INSERT INTO `esports_analytics.unsportsmanlike_messages`
    (message_id, user_id, timestamp, message_text, message_type, game_id, server_region)
  SELECT
    message_id,
    user_id,
    timestamp,
    message_text,
    ml_generate_text_llm_result AS category,
    game_id,
    server_region
  FROM
    ML.GENERATE_TEXT(
      MODEL `esports_analytics.gemini_model`,
      (
        SELECT
          *,
          CONCAT(
            "You are an expert content moderator for an online competitive game. Your task is to classify the following chat message as either 'sportsmanlike' or 'unsportsmanlike'.",
            "\n\n",
            "An 'unsportsmanlike' message falls into one of these categories:",
            "\n- personal_harassment: Insults, threats, or attacks directed at another player.",
            "\n- spamming: Repetitive, irrelevant, or unsolicited messages.",
            "\n- promoting_cheating: Advertising or encouraging the use of cheats, hacks, or exploits.",
            "\n- impersonation: Falsely pretending to be another player, admin, or staff member.",
            "\n\n",
            "Here are some examples:",
            "\nMessage: 'EZ clap, you guys are trash uninstall the game.' -> unsportsmanlike",
            "\nMessage: 'get my aimbot for free at supercheats dot com!' -> unsportsmanlike",
            "\nMessage: 'ggwp, that was a really close match!' -> sportsmanlike",
            "\n\n",
            "Based on these definitions and examples, classify the following message. Respond with *only* the single word: 'sportsmanlike' or 'unsportsmanlike'.",
            "\n\nMessage: ",
            message_text
          ) AS prompt
        FROM
          APPENDS(TABLE `esports_analytics.raw_chat_messages`)
      ),
      STRUCT(
        2048 AS max_output_tokens,
        0.2 AS temperature,
        1 AS candidate_count,
        TRUE AS flatten_json_output
      )
    )
  WHERE
    ml_generate_text_llm_result = 'unsportsmanlike';

Wait 1–2 minutes, then in a new query tab:

  SELECT * FROM `YOUR_PROJECT_ID.esports_analytics.unsportsmanlike_messages`
  LIMIT 1000;

You should see only unsportsmanlike messages.

c. Create the EXPORT DATA -> Bigtable continuous query:

New query tab in BigQuery:

  EXPORT DATA
  OPTIONS (
     format = 'CLOUD_BIGTABLE',
     auto_create_column_families = TRUE,
     uri = 'https://bigtable.googleapis.com/projects/YOUR_PROJECT_ID/instances/instance/tables/unsportsmanlike'
  )
  AS
    SELECT
      user_id AS rowkey,
      message_text,
      timestamp
    FROM
      APPENDS(TABLE `esports_analytics.unsportsmanlike_messages`);

Again, set "Query mode" to "Continuous query" and run it. Leave it running.

d. Optional Bigtable check from Cloud Shell:

  cbt -project YOUR_PROJECT_ID -instance instance read unsportsmanlike count=10

You should see some rows of unsportsmanlike chat messages.

3) Task 9: Run the Streamlit Moderation Dashboard
-------------------------------------------------

Back in Cloud Shell (new tab, so your generator keeps running):

  cd ~/esports

Create & activate Python virtualenv and install requirements:

  python3 -m venv gemini-streamlit
  source gemini-streamlit/bin/activate
  pip install -r requirements.txt

Run the Streamlit app:

  streamlit run app.py \
    --browser.serverAddress=localhost \
    --server.enableCORS=false \
    --server.enableXsrfProtection=false \
    --server.port 8080

In the terminal output you'll see a URL like:

  http://localhost:8080

Click that link (or preview in Cloud Shell) to open the moderation UI.

Use the UI to:
  - Review unsportsmanlike messages
  - Try "Suspend User", "Ban User", and "Dismiss as False Positive" buttons
    (they are just simulated actions for the lab).

4) Final verification
---------------------

In the lab page, use "Check my progress" for:

  - Create the cloud resources
  - Create the Pub/Sub topic and subscription
  - Grant Pub/Sub IAM permissions
  - Retrieve the Python files and review them
  - Generate synthetic data
  - Create the BigQuery ML Remote Model
  - Verify the results in BigQuery
  - Monitor messages with your Streamlit application

If any check fails, compare against the exact lab text; this script followed
the same resource names and patterns, so usually it's just a missing
continuous query or generator not running.
MANUAL_STEPS

echo
ok "You’re ready to finish the lab using the manual steps above."
