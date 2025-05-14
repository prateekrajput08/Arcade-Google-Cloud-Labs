#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🧐 Detecting your default GCP zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
    echo "${YELLOW_TEXT}Hmm, couldn't automatically detect the default zone.${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}✍️ Please enter your ZONE:${RESET_FORMAT}"
    read -p "${GREEN_TEXT}Zone: ${RESET_FORMAT}" ZONE
fi

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Using GCP Zone: $ZONE${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️  Next up: Creating a GKE cluster named 'gmp-cluster'.${RESET_FORMAT}"
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone $ZONE --enable-managed-prometheus
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔑  Fetching Kubernetes credentials for 'gmp-cluster'.${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster --zone=$ZONE
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🏷️  Creating a new Kubernetes namespace: 'gmp-test'.${RESET_FORMAT}"
kubectl create ns gmp-test
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Deploying an example application to the 'gmp-test' namespace.${RESET_FORMAT}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/example-app.yaml
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📈 Setting up PodMonitoring for our example app.${RESET_FORMAT}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/pod-monitoring.yaml
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📥 Cloning the GoogleCloudPlatform Prometheus repository and moving into it.${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/prometheus && cd prometheus
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Switching to a specific version (v2.28.1-gmp.4) of the Prometheus code.${RESET_FORMAT}"
git checkout v2.28.1-gmp.4
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🔽 Downloading a Prometheus binary.${RESET_FORMAT}"
wget https://storage.googleapis.com/kochasoft/gsp1026/prometheus
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🆔 Fetching your GCP Project ID.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo

echo "${RED_TEXT}${BOLD_TEXT}🔥 Starting the Prometheus server!${RESET_FORMAT}"
./prometheus \
  --config.file=documentation/examples/prometheus.yml --export.label.project-id=$PROJECT_ID --export.label.location=$ZONE 
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Downloading the Prometheus Node Exporter.${RESET_FORMAT}"
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🗜️ Extracting the Node Exporter archive.${RESET_FORMAT}"
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating into the Node Exporter directory.${RESET_FORMAT}"
cd node_exporter-1.3.1.linux-amd64
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📝 Creating a 'config.yaml' for the Node Exporter.${RESET_FORMAT}"
cat > config.yaml <<EOF_END
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['localhost:9100']

EOF_END
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🆔 Confirming your GCP Project ID for storage operations.${RESET_FORMAT}"
export PROJECT=$(gcloud config get-value project)
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🪣 Creating a Google Cloud Storage bucket named after your Project ID.${RESET_FORMAT}"
gsutil mb -p $PROJECT gs://$PROJECT
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the 'config.yaml' to your new GCS bucket.${RESET_FORMAT}"
gsutil cp config.yaml gs://$PROJECT
echo

echo "${RED_TEXT}${BOLD_TEXT}🌐 Making objects in the GCS bucket publicly readable.${RESET_FORMAT}"
gsutil -m acl set -R -a public-read gs://$PROJECT
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
