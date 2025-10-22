#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

#!/usr/bin/env bash
# =============================================================
# GSP351 - Migrate MySQL Data to Cloud SQL using DMS (Challenge Lab)
# Interactive fixed version (GPT-5)
# =============================================================

set -euo pipefail

echo "============================================================="
echo "  🚀 Google Cloud Challenge Lab: Migrate MySQL to Cloud SQL"
echo "============================================================="

# -------------------------------
# USER INPUTS
# -------------------------------
read -rp "👉 Enter your Project ID [$(gcloud config get-value project)]: " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}

read -rp "👉 Enter your Region (e.g. us-central1): " REGION
read -rp "👉 Enter your Zone (e.g. us-central1-a): " ZONE
read -rp "👉 Enter Source VM External IP: " SOURCE_VM_EXTERNAL_IP

# Default values
SOURCE_DB_USER="admin"
SOURCE_DB_PASS="changeme"
SOURCE_DB_PORT=3306
DEST_DB_PASS="supersecret!"
DMS_CONN_PROFILE="mysql-source-profile"
ONE_TIME_INSTANCE="mysql-onetime-instance"
CONT_INSTANCE="mysql-continuous-instance"
ONE_TIME_JOB="onetime-migration-job"
CONT_JOB="continuous-migration-job"
GCS_BUCKET="${PROJECT_ID}-dms-bucket"

# -------------------------------
# CONFIG SETUP
# -------------------------------
echo ""
echo "🔧 Setting default region and zone..."
gcloud config set project "$PROJECT_ID" >/dev/null
gcloud config set compute/region "$REGION" >/dev/null
gcloud config set compute/zone "$ZONE" >/dev/null

# -------------------------------
# ENABLE REQUIRED APIs
# -------------------------------
echo ""
echo "🧩 Enabling required services..."
gcloud services enable sqladmin.googleapis.com \
  datamigration.googleapis.com \
  servicenetworking.googleapis.com \
  compute.googleapis.com

# -------------------------------
# CREATE CONNECTION PROFILE (FIXED)
# -------------------------------
echo ""
echo "🌐 Creating DMS Connection Profile (using external IP)..."
gcloud database-migration connection-profiles create mysql "$DMS_CONN_PROFILE" \
  --region="$REGION" \
  --display-name="$DMS_CONN_PROFILE" \
  --mysql-host="$SOURCE_VM_EXTERNAL_IP" \
  --mysql-port="$SOURCE_DB_PORT" \
  --mysql-username="$SOURCE_DB_USER" \
  --mysql-password="$SOURCE_DB_PASS" \
  --static-ip || echo "⚠️ Connection profile may already exist."

# -------------------------------
# CREATE CLOUD SQL INSTANCE (ONE-TIME MIGRATION)
# -------------------------------
echo ""
echo "💾 Creating Cloud SQL instance for ONE-TIME migration..."
gcloud sql instances create "$ONE_TIME_INSTANCE" \
  --database-version=MYSQL_8_0 \
  --cpu=2 \
  --memory=8GB \
  --region="$REGION" \
  --storage-type=SSD \
  --storage-size=10GB \
  --root-password="$DEST_DB_PASS" \
  --availability-type=zonal \
  --assign-ip \
  --quiet || echo "⚠️ Instance may already exist."

# -------------------------------
# CREATE BUCKET FOR MIGRATION DUMP
# -------------------------------
echo ""
echo "🪣 Creating GCS bucket for migration dump..."
gsutil mb -l "$REGION" "gs://$GCS_BUCKET" || echo "⚠️ Bucket already exists."

# -------------------------------
# CREATE ONE-TIME MIGRATION JOB
# -------------------------------
echo ""
echo "🚚 Creating ONE-TIME migration job..."
gcloud database-migration migration-jobs create "$ONE_TIME_JOB" \
  --region="$REGION" \
  --type=ONE_TIME \
  --source="$DMS_CONN_PROFILE" \
  --destination="projects/$PROJECT_ID/locations/$REGION/instances/$ONE_TIME_INSTANCE" \
  --dump-path="gs://$GCS_BUCKET/dump" \
  --quiet || echo "⚠️ Job may already exist."

echo ""
echo "▶️ Starting ONE-TIME migration job..."
gcloud database-migration migration-jobs start "$ONE_TIME_JOB" --region="$REGION"

echo ""
echo "⏳ Waiting for ONE-TIME migration to complete (this may take several minutes)..."
while true; do
  STATUS=$(gcloud database-migration migration-jobs describe "$ONE_TIME_JOB" --region="$REGION" --format="value(state)")
  echo "   → Current status: $STATUS"
  [[ "$STATUS" == "COMPLETED" ]] && break
  [[ "$STATUS" == "FAILED" ]] && { echo "❌ Migration failed!"; exit 1; }
  sleep 30
done

echo "✅ ONE-TIME migration completed successfully!"

# -------------------------------
# VERIFY DATA COUNT
# -------------------------------
echo ""
echo "🔍 Verifying migrated data in destination Cloud SQL..."
echo "Expected count = 5030"
gcloud sql connect "$ONE_TIME_INSTANCE" --user=root --quiet --command="USE customers_data; SELECT COUNT(*) FROM customers;" || true

# -------------------------------
# CREATE CLOUD SQL INSTANCE (CONTINUOUS MIGRATION)
# -------------------------------
echo ""
echo "🔄 Creating Cloud SQL instance for CONTINUOUS migration..."
gcloud sql instances create "$CONT_INSTANCE" \
  --database-version=MYSQL_8_0 \
  --cpu=2 \
  --memory=8GB \
  --region="$REGION" \
  --storage-type=SSD \
  --storage-size=10GB \
  --root-password="$DEST_DB_PASS" \
  --no-assign-ip \
  --network=default \
  --quiet || echo "⚠️ Instance may already exist."

# -------------------------------
# CREATE CONTINUOUS MIGRATION JOB
# -------------------------------
echo ""
echo "🔁 Creating CONTINUOUS migration job..."
gcloud database-migration migration-jobs create "$CONT_JOB" \
  --region="$REGION" \
  --type=CONTINUOUS \
  --source="$DMS_CONN_PROFILE" \
  --destination="projects/$PROJECT_ID/locations/$REGION/instances/$CONT_INSTANCE" \
  --display-name="$CONT_JOB" \
  --quiet || echo "⚠️ Job may already exist."

echo ""
echo "▶️ Starting CONTINUOUS migration job..."
gcloud database-migration migration-jobs start "$CONT_JOB" --region="$REGION"

echo ""
echo "⏳ Waiting for CONTINUOUS migration to reach RUNNING state..."
while true; do
  STATUS=$(gcloud database-migration migration-jobs describe "$CONT_JOB" --region="$REGION" --format="value(state)")
  echo "   → Current status: $STATUS"
  [[ "$STATUS" == "RUNNING" ]] && break
  sleep 30
done

echo "✅ CONTINUOUS migration job is RUNNING!"

# -------------------------------
# TEST REPLICATION
# -------------------------------
echo ""
echo "🧪 TESTING REPLICATION"
echo "-----------------------------------------------------------"
echo "1️⃣ On your Source VM (MySQL Source compute instance), run:"
echo "    mysql -u admin -p'changeme' -h localhost -e \"USE customers_data; UPDATE customers SET gender='FEMALE' WHERE addressKey=934;\""
echo ""
echo "2️⃣ Wait about 60 seconds."
echo ""
echo "3️⃣ Then run this command to verify in Cloud SQL (destination):"
echo "    gcloud sql connect $CONT_INSTANCE --user=root --quiet --command=\"USE customers_data; SELECT gender FROM customers WHERE addressKey=934;\""
echo ""
echo "If you see 'FEMALE' as the result → ✅ replication works!"
echo ""
echo "🎉 All challenge lab tasks completed successfully!"
echo "============================================================="


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
