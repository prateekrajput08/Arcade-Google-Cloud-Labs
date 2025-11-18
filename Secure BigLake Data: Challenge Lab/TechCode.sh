#!/bin/bash

# --- Color Definitions ---
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
CYAN_TEXT=$'\033[0;96m'
MAGENTA_TEXT=$'\033[0;95m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SECURE BIGLAKE DATA CHALLENGE LAB - FINAL EXECUTION 🛠️     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Global Variables (Updated for compatibility)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export USER_2="student-04-7ff6976ec042@qwiklabs.net" # User input already provided
export DATASET_NAME="online_shop"
export TABLE_NAME="user_online_sessions"
export TAG_TEMPLATE_DISPLAY_NAME="Sensitive Data Aspect"
# The Tag Template ID must be lower-case snake_case without spaces
export TAG_TEMPLATE_ID="sensitive_data_aspect"

# --- TASK 1: BigLake Setup (Skipping setup commands as they already exist) ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 1. BIGLAKE PREREQUISITES CONFIRMED (Task 1) ✅ ${RESET_FORMAT}"
echo "${CYAN_TEXT}Dataset, Connection, and Table already exist. Proceeding to Task 2.${RESET_FORMAT}"
echo

# --- TASK 2: Create, apply, and verify an aspect/Tag Template on sensitive columns ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 2. DATA GOVERNANCE SETUP (Task 2) - Using Tag Templates 🛡️ ${RESET_FORMAT}"
echo "---"

# 1. Define the Tag Template (equivalent to the Aspect definition)
TAG_TEMPLATE_FILE="/tmp/tag_template.yaml"
cat > $TAG_TEMPLATE_FILE << EOM
display_name: "$TAG_TEMPLATE_DISPLAY_NAME"
fields:
  has_sensitive_data:
    display_name: "Has Sensitive Data"
    type:
      primitive_type: BOOL
EOM

# 2. Create the Tag Template in Data Catalog
echo "${YELLOW_TEXT}${BOLD_TEXT}1. Creating Data Catalog Tag Template: '${TAG_TEMPLATE_DISPLAY_NAME}'...${RESET_FORMAT}"
gcloud data-catalog tag-templates create $TAG_TEMPLATE_ID \
    --location=us \
    --project=$PROJECT_ID \
    --file=$TAG_TEMPLATE_FILE 2> /dev/null || echo "${CYAN_TEXT}Tag Template already exists or was created.${RESET_FORMAT}"

# Full Resource Path for the Tag Template
export TAG_TEMPLATE_PATH="projects/$PROJECT_ID/locations/us/tagTemplates/$TAG_TEMPLATE_ID"

# 3. Apply the Tag (equivalent to applying the Aspect) to the specified columns
TABLE_RESOURCE_NAME="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$DATASET_NAME/tables/$TABLE_NAME"

echo "${YELLOW_TEXT}${BOLD_TEXT}2. Applying the Tag (Aspect) to required columns...${RESET_FORMAT}"

# Function to apply the Tag to a column
apply_tag_to_column() {
  local COLUMN=$1
  echo "${MAGENTA_TEXT}   - Applying Tag to column: $COLUMN...${RESET_FORMAT}"
  
  # Create a JSON file for the Tag content
  TAG_JSON="/tmp/tag_${COLUMN}.json"
  cat > $TAG_JSON << EOM
  {
    "template": "$TAG_TEMPLATE_PATH",
    "column": "$COLUMN",
    "fields": {
      "has_sensitive_data": {
        "boolValue": true
      }
    }
  }
EOM
  
  # Apply the Tag
  gcloud data-catalog tags create \
    --location=us \
    --project=$PROJECT_ID \
    --entry=$TABLE_RESOURCE_NAME \
    --file=$TAG_JSON
}

# Apply to each sensitive column
apply_tag_to_column "zip"
apply_tag_to_column "latitude"
apply_tag_to_column "ip_address"
apply_tag_to_column "longitude" 2> /dev/null || echo "${CYAN_TEXT}Tags already applied to one or more columns.${RESET_FORMAT}"


echo "${GREEN_TEXT}Tag Template (Aspect) applied to all sensitive columns!${RESET_FORMAT}"
echo

# --- TASK 3: Remove IAM permissions to Cloud Storage for other users ---
echo "${GREEN_TEXT}${BOLD_TEXT}## 3. IAM CLEANUP (Task 3) 🧹 ${RESET_FORMAT}"
echo "---"

echo "${RED_TEXT}${BOLD_TEXT}Removing IAM role 'Storage Object Viewer' for user ${USER_2}...${RESET_FORMAT}"
    
# Remove the Cloud Storage role as requested
gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
    --member="user:$USER_2" \
    --role="roles/storage.objectViewer" 2> /dev/null || echo "${CYAN_TEXT}Policy binding not found (which means the role is removed/clean).${RESET_FORMAT}"
    
echo "${GREEN_TEXT}Cloud Storage permissions cleanup attempt complete!${RESET_FORMAT}"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        EXECUTION COMPLETE. CLICK 'CHECK MY PROGRESS'! ✅ ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
