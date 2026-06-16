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
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services enable monitoring.googleapis.com \
    networkmanagement.googleapis.com

sleep 30

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting Lab Credentials...${RESET_FORMAT}"
 export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

cat > prepare_disk.sh <<'EOF_END'

gcloud auth login --quiet

export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud iam service-accounts create devops --display-name devops

sleep 45

gcloud iam service-accounts list  --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SA --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SA --role=roles/compute.instanceAdmin

gcloud compute instances create vm-2 \
--machine-type=e2-micro \
--service-account=$SA \
--zone=$ZONE \
--scopes=https://www.googleapis.com/auth/compute

cat > role-definition.yaml <<EOF
title: "My Company Admin"
description: "My custom role description."
stage: "ALPHA"
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

gcloud iam roles create editor --project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml

gcloud iam service-accounts create bigquery-qwiklab --display-name bigquery-qwiklab
sleep 15
echo "${YELLOW_TEXT}${BOLD_TEXT}SA: $SA_EMAIL${RESET_FORMAT}"
SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=bigquery-qwiklab")

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:$SA --role=roles/bigquery.dataViewer

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:$SA --role=roles/bigquery.user

SA=$(gcloud iam service-accounts list \
  --format="value(email)" \
  --filter="displayName=bigquery-qwiklab")

gcloud compute instances create bigquery-instance \
  --zone=$ZONE \
  --machine-type=e2-standard-2 \
  --service-account="$SA" \
  --scopes=https://www.googleapis.com/auth/cloud-platform

curl -H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/scopes

EOF_END

gcloud compute scp prepare_disk.sh lab-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

sleep 30

cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt install python3 -y
sudo apt-get install -y git python3-pip
sudo apt install python3.11-venv -y
python3 -m venv myvenv
source myvenv/bin/activate
pip install --upgrade pip
pip install google-cloud-bigquery pandas pyarrow db-dtypes google-auth


export ZONE=$(curl -s \
  -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/zone | awk -F/ '{print $NF}')
export DEVSHELL_PROJECT_ID=$(curl -s \
  -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)
export SA_EMAIL=$(gcloud config get-value account 2>/dev/null || curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" -H "Metadata-Flavor: Google")
echo "SA: $SA_EMAIL"

cat > query.py <<EOF
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials()

query = '''
SELECT name, SUM(number) as total_people
FROM \`bigquery-public-data.usa_names.usa_1910_2013\`
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''

client = bigquery.Client(
    project='$DEVSHELL_PROJECT_ID',
    credentials=credentials
)

print(client.query(query).to_dataframe())
EOF

sleep 10

source myvenv/bin/activate
python query.py
EOF_END

gcloud compute scp prepare_disk.sh bigquery-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh bigquery-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
