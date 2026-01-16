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

# Step 1: Set Project ID, Compute Zone & Region
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting Project ID, Compute Zone & Region${RESET_FORMAT}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE

# Step 2: Create Kubernetes Cluster
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Kubernetes Cluster${RESET_FORMAT}"
gcloud container clusters create gmp-cluster --num-nodes=1 --zone $ZONE

# Step 3: Create Logging Metric for Stopped VMs
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating log-based metric for stopped VMs${RESET_FORMAT}"
gcloud logging metrics create stopped-vm \
    --description="Metric for stopped VMs" \
    --log-filter='resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"'

# Step 4: Create Pub/Sub notification channel config file
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Pub/Sub notification channel config file${RESET_FORMAT}"
cat > pubsub-channel.json <<EOF_END
{
  "type": "pubsub",
  "displayName": "awesome",
  "description": "Hiiii There !!",
  "labels": {
    "topic": "projects/$DEVSHELL_PROJECT_ID/topics/notificationTopic"
  }
}
EOF_END

# Step 5: Create the Pub/Sub notification channel
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Pub/Sub notification channel${RESET_FORMAT}"
gcloud beta monitoring channels create --channel-content-from-file=pubsub-channel.json

# Step 6: Retrieve Notification Channel ID
echo "${BOLD}${YELLOW_TEXT}Retrieving Notification Channel ID${RESET_FORMAT}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Step 7: Create Alert Policy for Stopped VMs
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating alert policy for stopped VMs${RESET_FORMAT}"
cat > stopped-vm-alert-policy.json <<EOF_END
{
  "displayName": "stopped vm",
  "documentation": {
    "content": "Documentation content for the stopped vm alert policy",
    "mime_type": "text/markdown"
  },
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Log match condition",
      "conditionMatchedLog": {
        "filter": "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "300s"
    },
    "autoClose": "3600s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ]
}


EOF_END

# Step 8: Deploy Alert Policy
echo "${BOLD_TEXT}${YELLOW_TEXT}Deploying alert policy for stopped VMs${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

# Step 9: Create Artifact Registry
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Docker Artifact Registry${RESET_FORMAT}"
gcloud artifacts repositories create docker-repo --repository-format=docker \
    --location=$REGION --description="Docker repository" \
    --project=$DEVSHELL_PROJECT_ID

# Step 10: Download and Load Docker Image
echo "${BOLD_TEXT}${YELLOW_TEXT}Downloading and loading Docker image${RESET_FORMAT}"
 wget https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
 unzip flask_telemetry.zip
 docker load -i flask_telemetry.tar

# Step 11: Tag and Push Docker Image
echo "${BOLD_TEXT}${YELLOW_TEXT}Tagging and pushing Docker image${RESET_FORMAT}"
docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

gcloud container clusters list

# Step 12: Get Cluster Credentials
echo "${BOLD_TEXT}${YELLOW_TEXT}Getting Kubernetes cluster credentials${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster

# Step 13: Create Namespace
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Kubernetes namespace${RESET_FORMAT}"
kubectl create ns gmp-test

# Step 14: Download and Unpack Prometheus Setup
echo "${BOLD_TEXT}${YELLOW_TEXT}Downloading and unpacking Prometheus setup files${RESET_FORMAT}"
wget https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
unzip gmp_prom_setup.zip
cd gmp_prom_setup

# Step 15: Update Deployment with Docker Image
echo "${BOLD_TEXT}${YELLOW_TEXT}Updating deployment manifest with Docker image URL${RESET_FORMAT}"
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1|g" flask_deployment.yaml

# Step 16: Apply Kubernetes Resources
echo "${BOLD_TEXT}${YELLOW_TEXT}Applying Kubernetes deployment and service${RESET_FORMAT}"
kubectl -n gmp-test apply -f flask_deployment.yaml

kubectl -n gmp-test apply -f flask_service.yaml

# Step 17: Check Services
echo "${BOLD_TEXT}${YELLOW_TEXT}Checking Kubernetes services${RESET_FORMAT}"
kubectl get services -n gmp-test

# Step 18: Create Metric for hello-app Errors
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating log-based metric for hello-app errors${RESET_FORMAT}"
gcloud logging metrics create hello-app-error \
    --description="Metric for hello-app errors" \
    --log-filter='severity=ERROR
resource.labels.container_name="hello-app"
textPayload: "ERROR: 404 Error page not found"'

sleep 30

# Step 19: Create Alert Policy for hello-app Errors
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating alert policy for hello-app errors${RESET_FORMAT}"
cat > awesome.json <<'EOF_END'
{
  "displayName": "log based metric alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "New condition",
      "conditionThreshold": {
        "filter": 'metric.type="logging.googleapis.com/user/hello-app-error" AND resource.type="global"',
        "aggregations": [
          {
            "alignmentPeriod": "120s",
            "crossSeriesReducer": "REDUCE_SUM",
            "perSeriesAligner": "ALIGN_DELTA"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}

EOF_END

# Step 20: Deploy Alert Policy
echo "${BOLD_TEXT}${YELLOW_TEXT}Deploying alert policy for hello-app errors${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=awesome.json

# Step 21: Trigger Errors
echo "${BOLD_TEXT}${YELLOW_TEXT}Triggering errors to generate logs for metric${RESET_FORMAT}"
timeout 120 bash -c -- 'while true; do curl $(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')/error; sleep $((RANDOM % 4)) ; done'

echo

# Display completion message
echo "${BOLD_TEXT}${YELLOW_TEXT}Lab execution completed successfully!${RESET_FORMAT}"
echo "${BOLD_TEXT}${YELLOW_TEXT}Thank you for using Dr. Abhishek Cloud Tutorials${RESET_FORMAT}"

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
