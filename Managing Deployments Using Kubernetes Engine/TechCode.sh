#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO: Command \"$BASH_COMMAND\" failed."; read -p "Press [Enter] to exit..."' ERR

LOG() {
  echo -e "\n[INFO] $1\n"
}

# Fetch current GCP environment details
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
if [ -z "$PROJECT_ID" ]; then
  echo "No active Google Cloud project set. Please set one using 'gcloud config set project PROJECT_ID'"
  exit 1
fi

ZONE=$(gcloud config get-value compute/zone 2>/dev/null || true)
if [ -z "$ZONE" ]; then
  echo "No compute zone set. Please set one using 'gcloud config set compute/zone ZONE'"
  exit 1
fi

CLUSTER_NAME="bootcamp"
MACHINE_TYPE="e2-small"
NUM_NODES=3

LOG "Active project: $PROJECT_ID"
LOG "Compute zone: $ZONE"

# Explicitly set zone to avoid ambiguity
gcloud config set compute/zone "$ZONE"

# Download lab sample code
LOG "Downloading lab files"
gsutil -m cp -r gs://spls/gsp053/orchestrate-with-kubernetes .
cd orchestrate-with-kubernetes/kubernetes || exit

# Create cluster if it does not exist
if ! gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" &>/dev/null; then
  LOG "Creating Kubernetes cluster $CLUSTER_NAME"
  gcloud container clusters create "$CLUSTER_NAME" \
    --zone "$ZONE" \
    --machine-type "$MACHINE_TYPE" \
    --num-nodes "$NUM_NODES" \
    --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
else
  LOG "Cluster $CLUSTER_NAME already exists. Skipping creation."
fi

LOG "Waiting for cluster to be ready..."
sleep 60

# Deploy auth service
LOG "Deploying auth service"
kubectl apply -f deployments/auth.yaml
kubectl apply -f services/auth.yaml

# Deploy hello service
LOG "Deploying hello service"
kubectl apply -f deployments/hello.yaml
kubectl apply -f services/hello.yaml

# Create secrets and configmaps
LOG "Creating secrets and configmaps"
kubectl create secret generic tls-certs --from-file tls/ --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf --dry-run=client -o yaml | kubectl apply -f -

# Deploy frontend service
LOG "Deploying frontend service"
kubectl apply -f deployments/frontend.yaml
kubectl apply -f services/frontend.yaml

# Scale hello deployment up
LOG "Scaling hello deployment up to 5 replicas"
kubectl scale deployment hello --replicas=5
sleep 15

# Scale hello deployment down
LOG "Scaling hello deployment down to 3 replicas"
kubectl scale deployment hello --replicas=3
sleep 15

# Rolling update with set image command
LOG "Performing rolling update on hello deployment to version 2.0"
kubectl set image deployment/hello hello=gcr.io/google-samples/hello-app:2.0 --record
sleep 30

# Rollback to previous revision
LOG "Rolling back hello deployment to previous revision"
kubectl rollout undo deployment/hello
sleep 30

# Show rollout history
LOG "Displaying rollout history for hello deployment"
kubectl rollout history deployment/hello

# List all pods for verification
LOG "Listing all pods"
kubectl get pods

LOG "Script execution complete. Complete any manual steps or validations as per lab instructions."
