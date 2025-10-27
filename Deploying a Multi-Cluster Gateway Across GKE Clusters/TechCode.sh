#!/bin/bash

# Prompt user for regions and zones
read -p "Enter first region (e.g., us-central1): " REGION1
read -p "Enter zone for cluster1 in $REGION1 (e.g., us-central1-a): " ZONE1
read -p "Enter zone for cluster2 in $REGION1 (e.g., us-central1-b): " ZONE2
read -p "Enter second region (e.g., us-east1): " REGION2
read -p "Enter zone for cluster3 in $REGION2 (e.g., us-east1-b): " ZONE3

PROJECT_ID=$(gcloud config get-value project)

# Enable GKE Enterprise (via Anthos API and create an empty fleet)
gcloud services enable anthos.googleapis.com --project=$PROJECT_ID
gcloud container fleet create --display-name=gke-enterprise-fleet --project=$PROJECT_ID

# Create clusters
gcloud container clusters create cluster1 \
  --zone=$ZONE1 \
  --enable-ip-alias \
  --machine-type=e2-standard-4 \
  --num-nodes=1 \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --release-channel=regular \
  --project=$PROJECT_ID --async

gcloud container clusters create cluster2 \
  --zone=$ZONE2 \
  --enable-ip-alias \
  --machine-type=e2-standard-4 \
  --num-nodes=1 \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --release-channel=regular \
  --project=$PROJECT_ID --async

gcloud container clusters create cluster3 \
  --zone=$ZONE3 \
  --enable-ip-alias \
  --machine-type=e2-standard-4 \
  --num-nodes=1 \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --release-channel=regular \
  --project=$PROJECT_ID

# Wait until clusters are up (optional, normally not more than 8 minutes)
echo "Waiting for clusters to be provisioned..."
gcloud container clusters list

# Get credentials and rename contexts
gcloud container clusters get-credentials cluster1 --zone=$ZONE1 --project=$PROJECT_ID
gcloud container clusters get-credentials cluster2 --zone=$ZONE2 --project=$PROJECT_ID
gcloud container clusters get-credentials cluster3 --zone=$ZONE3 --project=$PROJECT_ID

kubectl config rename-context gke_${PROJECT_ID}_${ZONE1}_cluster1 cluster1
kubectl config rename-context gke_${PROJECT_ID}_${ZONE2}_cluster2 cluster2
kubectl config rename-context gke_${PROJECT_ID}_${ZONE3}_cluster3 cluster3

# Enable Gateway API on cluster1
gcloud container clusters update cluster1 --gateway-api=standard --zone=$ZONE1 --project=$PROJECT_ID

# Register clusters to fleet
gcloud container fleet memberships register cluster1 \
  --gke-cluster $ZONE1/cluster1 \
  --enable-workload-identity \
  --project=$PROJECT_ID

gcloud container fleet memberships register cluster2 \
  --gke-cluster $ZONE2/cluster2 \
  --enable-workload-identity \
  --project=$PROJECT_ID

gcloud container fleet memberships register cluster3 \
  --gke-cluster $ZONE3/cluster3 \
  --enable-workload-identity \
  --project=$PROJECT_ID

gcloud container fleet memberships list --project=$PROJECT_ID

# Enable Multi-cluster Services (MCS)
gcloud container fleet multi-cluster-services enable --project $PROJECT_ID

# IAM for MCS
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[gke-mcs/gke-mcs-importer]" \
  --role "roles/compute.networkViewer" \
  --project=$PROJECT_ID

gcloud container fleet multi-cluster-services describe --project=$PROJECT_ID

# Enable Multi-cluster Gateway (MCG) controller
gcloud container fleet ingress enable \
  --config-membership=cluster1 \
  --project=$PROJECT_ID \
  --location=$REGION1

gcloud container fleet ingress describe --project=$PROJECT_ID

# Grant IAM for Gateway controller (you'll need to get the project number)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-multiclusteringress.iam.gserviceaccount.com" \
  --role "roles/container.admin" \
  --project=$PROJECT_ID

echo "Script completed. Proceed with deploying workloads as described in the lab."
