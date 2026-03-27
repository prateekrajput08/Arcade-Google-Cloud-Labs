#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Ask user for zone
echo "${YELLOW_TEXT}Enter your compute zone (e.g., us-west1-b): ${RESET_FORMAT}"
read ZONE

echo "${YELLOW_TEXT}Using zone: ${ZONE}${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${BLUE_TEXT}Starting Task 1...${RESET_FORMAT}"

gsutil cp gs://spls/gsp051/continuous-deployment-on-kubernetes.zip .
unzip -o continuous-deployment-on-kubernetes.zip
cd continuous-deployment-on-kubernetes

echo "${BLUE_TEXT}Starting Task 2...${RESET_FORMAT}"

gcloud container clusters create jenkins-cd \
--num-nodes 2 \
--machine-type e2-standard-2 \
--scopes "https://www.googleapis.com/auth/source.read_write,cloud-platform"

gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info

echo "${BLUE_TEXT}Starting Task 3...${RESET_FORMAT}"

helm repo add jenkins https://charts.jenkins.io
helm repo update

echo "${BLUE_TEXT}Starting Task 4...${RESET_FORMAT}"

helm install cd jenkins/jenkins -f jenkins/values.yaml --wait

kubectl get pods

kubectl create clusterrolebinding jenkins-deploy \
--clusterrole=cluster-admin \
--serviceaccount=default:cd-jenkins

export POD_NAME=$(kubectl get pods --namespace default \
-l "app.kubernetes.io/component=jenkins-master" \
-l "app.kubernetes.io/instance=cd" \
-o jsonpath="{.items[0].metadata.name}")

kubectl port-forward $POD_NAME 8080:8080 >> /dev/null &

kubectl get svc

echo "${BLUE_TEXT}Starting Task 5...${RESET_FORMAT}"

printf $(kubectl get secret cd-jenkins \
-o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

echo "${BLUE_TEXT}Starting Task 6 & 7...${RESET_FORMAT}"

cd sample-app

kubectl create ns production

kubectl apply -f k8s/production -n production
kubectl apply -f k8s/canary -n production
kubectl apply -f k8s/services -n production

kubectl scale deployment gceme-frontend-production \
-n production --replicas 4

kubectl get pods -n production -l app=gceme -l role=frontend
kubectl get pods -n production -l app=gceme -l role=backend

kubectl get service gceme-frontend -n production

echo "${YELLOW_TEXT}Waiting for external IP...${RESET_FORMAT}"

while true; do
  FRONTEND_SERVICE_IP=$(kubectl get svc gceme-frontend \
    -n production \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

  if [[ -n "$FRONTEND_SERVICE_IP" ]]; then
    echo "${GREEN_TEXT}External IP found: $FRONTEND_SERVICE_IP${RESET_FORMAT}"
    break
  fi

  echo "${RED_TEXT}Still waiting...${RESET_FORMAT}"
  sleep 10
done

echo "${TEAL}Testing frontend service...${RESET_FORMAT}"
curl http://$FRONTEND_SERVICE_IP/version

echo "${BLUE_TEXT}Starting Task 8...${RESET_FORMAT}"

curl -sS https://webi.sh/gh | sh

gh auth login
gh api user -q ".login"

GITHUB_USERNAME=$(gh api user -q ".login")

git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

echo "${GREEN_TEXT}GitHub Username: ${GITHUB_USERNAME}${RESET_FORMAT}"
echo "${GREEN_TEXT}Email: ${USER_EMAIL}${RESET_FORMAT}"

gh repo create default --private

git init

git config credential.helper gcloud.sh

git remote add origin https://github.com/${GITHUB_USERNAME}/default

git add .
git commit -m "Initial commit"
git push origin master

echo "${GREEN_TEXT}${BOLD_TEXT}=== DONE ===${RESET_FORMAT}"
echo "${MAGENTA_TEXT}Open Jenkins → Web Preview → Port 8080${RESET_FORMAT}"
