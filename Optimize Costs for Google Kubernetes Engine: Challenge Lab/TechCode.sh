#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${BOLD_TEXT}${MAGENTA_TEXT}Please provide the following configuration values:${RESET_FORMAT}"

# Export the variables name correctly
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE (e.g. us-central1-a): ${WHITE_TEXT}${BOLD_TEXT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the CLUSTER_NAME (e.g. autoscale-cluster): ${WHITE_TEXT}${BOLD_TEXT}" CLUSTER_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the POOL_NAME (e.g. worker-pool): ${WHITE_TEXT}${BOLD_TEXT}" POOL_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the MAX_REPLICAS (e.g. 5): ${WHITE_TEXT}${BOLD_TEXT}" MAX_REPLICAS

echo "${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Configuration values received${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${BLUE_TEXT}STEP 1: Verifying Authentication${RESET_FORMAT}"
gcloud auth list
echo ""

PROJECT=$(gcloud config get-value project)
echo "${WHITE_TEXT}${BOLD_TEXT}Current Project: ${YELLOW_TEXT}${BOLD_TEXT}$PROJECT${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${GREEN_TEXT}STEP 2: Creating GKE Cluster${RESET_FORMAT}"
gcloud container clusters create $CLUSTER_NAME \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --num-nodes=2 || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create cluster${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}Cluster created successfully${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${CYAN_TEXT}STEP 3: Creating Namespaces${RESET_FORMAT}"
kubectl create namespace dev
kubectl create namespace prod
echo "${GREEN_TEXT}${BOLD_TEXT}Namespaces created${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${YELLOW_TEXT}STEP 4: Deploying Microservices Demo${RESET_FORMAT}"
git clone -q https://github.com/GoogleCloudPlatform/microservices-demo.git &&
cd microservices-demo && 
kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to deploy microservices${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}Microservices deployed to dev namespace${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${MAGENTA_TEXT}STEP 5: Creating Custom Node Pool${RESET_FORMAT}"
gcloud container node-pools create $POOL_NAME \
    --cluster=$CLUSTER_NAME \
    --machine-type=custom-2-3584 \
    --num-nodes=2 \
    --zone=$ZONE || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create node pool${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}Node pool created successfully${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${BLUE_TEXT}STEP 6: Migrating from Default Pool${RESET_FORMAT}"
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl cordon "$node"
done

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node"
done

kubectl get pods -o=wide --namespace=dev
echo "${GREEN_TEXT}${BOLD_TEXT}Workloads migrated to new node pool${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${RED_TEXT}STEP 7: Removing Default Node Pool${RESET_FORMAT}"
gcloud container node-pools delete default-pool \
    --cluster=$CLUSTER_NAME \
    --project=$DEVSHELL_PROJECT_ID \
    --zone $ZONE \
    --quiet || {
    echo "${YELLOW_TEXT}${BOLD_TEXT}Default pool may already be deleted${RESET_FORMAT}"
}
echo "${GREEN_TEXT}${BOLD_TEXT}Default pool removed${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${CYAN_TEXT}STEP 8: Creating Pod Disruption Budget${RESET_FORMAT}"
kubectl create poddisruptionbudget onlineboutique-frontend-pdb \
    --selector app=frontend \
    --min-available 1 \
    --namespace dev || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create PDB${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}PDB created successfully${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${YELLOW_TEXT}STEP 9: Updating Frontend Deployment${RESET_FORMAT}"
kubectl patch deployment frontend -n dev --type=json -p '[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/image",
    "value": "gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/imagePullPolicy",
    "value": "Always"
  }
]' || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to update deployment${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}Frontend deployment updated${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${MAGENTA_TEXT}STEP 10: Configuring Horizontal Pod Autoscaler${RESET_FORMAT}"
kubectl autoscale deployment frontend \
    --cpu-percent=50 \
    --min=1 \
    --max=$MAX_REPLICAS \
    --namespace dev || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to configure HPA${RESET_FORMAT}"
    exit 1
}

kubectl get hpa --namespace dev
echo "${GREEN_TEXT}${BOLD_TEXT}HPA configured successfully${RESET_FORMAT}"
echo ""

echo "${BOLD_TEXT}${BLUE_TEXT}STEP 11: Enabling Cluster Autoscaling${RESET_FORMAT}"
gcloud beta container clusters update $CLUSTER_NAME \
    --zone=$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --enable-autoscaling \
    --min-nodes 1 \
    --max-nodes 6 || {
    echo "${RED_TEXT}${BOLD_TEXT}Failed to enable cluster autoscaling${RESET_FORMAT}"
    exit 1
}
echo "${GREEN_TEXT}${BOLD_TEXT}Cluster autoscaling enabled${RESET_FORMAT}"

echo "${WHITE_TEXT}${BOLD_TEXT}Access your resources:${RESET_FORMAT}"
echo "${YELLOW_TEXT}GKE Cluster: https://console.cloud.google.com/kubernetes/list?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}Workloads: https://console.cloud.google.com/kubernetes/workload?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo ""

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
