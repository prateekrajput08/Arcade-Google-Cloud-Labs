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


export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud container clusters create gmp-cluster --num-nodes=3 --zone=$ZONE

gcloud container clusters get-credentials gmp-cluster --zone=$ZONE

kubectl create ns gmp-test

kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/manifests/setup.yaml

kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/manifests/operator.yaml

kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/example-app.yaml

cat > op-config.yaml <<'EOF_END'
apiVersion: monitoring.googleapis.com/v1alpha1
collection:
  filter:
    matchOneOf:
    - '{job="prom-example"}'
    - '{__name__=~"job:.+"}'
kind: OperatorConfig
metadata:
  annotations:
    components.gke.io/layer: addon
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"monitoring.googleapis.com/v1alpha1","kind":"OperatorConfig","metadata":{"annotations":{"components.gke.io/layer":"addon"},"labels":{"addonmanager.kubernetes.io/mode":"Reconcile"},"name":"config","namespace":"gmp-public"}}
  creationTimestamp: "2022-03-14T22:34:23Z"
  generation: 1
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
  name: config
  namespace: gmp-public
  resourceVersion: "2882"
  uid: 4ad23359-efeb-42bb-b689-045bd704f295
EOF_END

export PROJECT=$(gcloud config get-value project)

gsutil mb -p $PROJECT gs://$PROJECT

gsutil cp op-config.yaml gs://$PROJECT

gsutil -m acl set -R -a public-read gs://$PROJECT


#-----------------------------------------------------end----------------------------------------------------------#
# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
