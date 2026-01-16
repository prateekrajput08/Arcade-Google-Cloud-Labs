#!/bin/bash

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

if [[ -z "$PROJECT_ID" ]]; then
  echo "No active GCP project found. Run: gcloud config set project PROJECT_ID"
  exit 1
fi

BUCKET_NAME="gs://${PROJECT_ID}-bucket"
LIFECYCLE_FILE="gcs_lifecycle_rules.json"

echo "Creating lifecycle rules for bucket: $BUCKET_NAME"

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

gsutil lifecycle set "$LIFECYCLE_FILE" "$BUCKET_NAME"

echo "Lifecycle policy successfully applied."
