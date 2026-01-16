#!/bin/bash

# Fetch active GCP project
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

# Exit if project ID is empty
if [[ -z "$PROJECT_ID" ]]; then
  echo "No active GCP project found. Run: gcloud config set project PROJECT_ID"
  exit 1
fi

BUCKET_NAME="gs://${PROJECT_ID}-bucket"
LIFECYCLE_FILE="gcs_lifecycle_rules.json"

echo "Creating lifecycle rules for bucket: $BUCKET_NAME"

# Generate lifecycle configuration
cat > "$LIFECYCLE_FILE" <<'JSON'
{
  "rule": [
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "NEARLINE"
      },
      "condition": {
        "daysSinceNoncurrentTime": 30,
        "matchesPrefix": ["projects/active/"]
      }
    },
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "NEARLINE"
      },
      "condition": {
        "daysSinceNoncurrentTime": 90,
        "matchesPrefix": ["archive/"]
      }
    },
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "COLDLINE"
      },
      "condition": {
        "daysSinceNoncurrentTime": 180,
        "matchesPrefix": ["archive/"]
      }
    },
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "age": 7,
        "matchesPrefix": ["processing/temp_logs/"]
      }
    }
  ]
}
JSON

# Apply lifecycle rules
gsutil lifecycle set "$LIFECYCLE_FILE" "$BUCKET_NAME"

echo "Lifecycle policy successfully applied."
