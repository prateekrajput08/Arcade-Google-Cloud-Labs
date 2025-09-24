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

#  Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# ---------------------------------------
#  Colorized Dataplex Setup Script
#  - Creates lake
#  - Creates curated zone
#  - Attaches BigQuery dataset
#  - Generates aspect type JSON
#  - Creates the aspect type via correct CLI flag
# ---------------------------------------



function echo_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
function echo_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
function echo_warn()  { echo -e "${YELLOW}[WAITING]${NC} $1"; }
function echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Input: Region
read -p "Enter the region (e.g., us-east4): " REGION

# Fetch Project ID
PROJECT_ID=$(gcloud config get-value project)
if [[ -z "$PROJECT_ID" ]]; then
  echo_error "Unable to retrieve GCP project ID; ensure you're authenticated."
  exit 1
fi

# Variables
LAKE_NAME="orders-lake"
LAKE_DISPLAY_NAME="Orders Lake"
ZONE_NAME="customer-curated-zone"
ZONE_DISPLAY_NAME="Customer Curated Zone"
ASSET_NAME="customer-details-dataset"
ASSET_DISPLAY_NAME="Customer Details Dataset"
ASPECT_TYPE_ID="protected-data-aspect"
ASPECT_TYPE_DISPLAY_NAME="Protected Data Aspect"
ASPECT_JSON_FILE="aspect_type.json"

echo_info "Project: $PROJECT_ID"
echo_info "Region: $REGION"

# 1. Create Lake
echo_info "Creating Dataplex lake..."
gcloud dataplex lakes create $LAKE_NAME \
  --project=$PROJECT_ID --location=$REGION --display-name="$LAKE_DISPLAY_NAME"

echo_warn "Waiting for lake to become ACTIVE..."
ATT=0
while true; do
  STATE=$(gcloud dataplex lakes describe $LAKE_NAME --project=$PROJECT_ID --location=$REGION --format='value(state)' 2>/dev/null)
  if [[ "$STATE" == "ACTIVE" ]]; then
    echo_success "Lake is ACTIVE."
    break
  fi
  ((ATT++)); [[ $ATT -ge 20 ]] && echo_error "Lake did not become ACTIVE in time." && exit 1
  echo_warn "Current state: $STATE. Retrying in 30s..."
  sleep 30
done

# 2. Create Curated Zone
echo_info "Creating curated zone..."
gcloud dataplex zones create $ZONE_NAME \
  --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME \
  --display-name="$ZONE_DISPLAY_NAME" --type=CURATED --resource-location-type=SINGLE_REGION

echo_warn "Waiting for zone to become ACTIVE..."
ATT=0
while true; do
  STATE=$(gcloud dataplex zones describe $ZONE_NAME --project=$PROJECT_ID --lake=$LAKE_NAME --location=$REGION --format='value(state)' 2>/dev/null)
  if [[ "$STATE" == "ACTIVE" ]]; then
    echo_success "Zone is ACTIVE."
    break
  fi
  ((ATT++)); [[ $ATT -ge 20 ]] && echo_error "Zone did not become ACTIVE in time." && exit 1
  echo_warn "Current state: $STATE. Retrying in 30s..."
  sleep 30
done

# 3. Attach BigQuery Dataset as Asset
echo_info "Attaching BigQuery dataset asset..."
gcloud dataplex assets create $ASSET_NAME \
  --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME --zone=$ZONE_NAME \
  --display-name="$ASSET_DISPLAY_NAME" --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$PROJECT_ID/datasets/customers --discovery-enabled

echo_success "Asset created."

echo_info "Proceed to the UI to apply aspects to table columns."

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
