#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'        # ERROR
GREEN_TEXT=$'\033[0;92m'      # SUCCESS
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'       # ACTION
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'       # (KEEP used for start/end)
WHITE_TEXT=$'\033[0;97m'      # NEUTRAL

TEAL_TEXT=$'\033[38;5;50m'    # INFO
PURPLE_TEXT=$'\033[0;35m'     # SECTION HEADER
GOLD_TEXT=$'\033[0;33m'       # WARNING
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear


echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


echo "${TEAL_TEXT}${BOLD_TEXT}Detecting default Compute Zone...${RESET_FORMAT}"

ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${GOLD_TEXT}${BOLD_TEXT}Default zone not detected.${RESET_FORMAT}"
  while true; do
    read -p "${BLUE_TEXT}${BOLD_TEXT}Enter Zone (e.g., us-central1-a): ${RESET_FORMAT}" ZONE_INPUT
    if [ -z "$ZONE_INPUT" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}Zone cannot be empty.${RESET_FORMAT}"
    elif [[ "$ZONE_INPUT" =~ ^[a-z0-9]+-[a-z0-9]+-[a-z]$ ]]; then
      ZONE="$ZONE_INPUT"
      break
    else
      echo "${RED_TEXT}${BOLD_TEXT}Invalid zone format.${RESET_FORMAT}"
    fi
  done
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Using Zone: ${WHITE_TEXT}${ZONE}${RESET_FORMAT}"

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Detecting Region...${RESET_FORMAT}"

REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${GOLD_TEXT}${BOLD_TEXT}Default region not detected.${RESET_FORMAT}"
  if [ -n "$ZONE" ]; then
    echo "${TEAL_TEXT}${BOLD_TEXT}Deriving Region from Zone...${RESET_FORMAT}"
    REGION="${ZONE%-*}"
  else
    while true; do
      read -p "${BLUE_TEXT}${BOLD_TEXT}Enter Region (e.g., us-central1): ${RESET_FORMAT}" REGION_INPUT
      if [ -z "$REGION_INPUT" ]; then
        echo "${RED_TEXT}${BOLD_TEXT}Region cannot be empty.${RESET_FORMAT}"
      elif [[ "$REGION_INPUT" =~ ^[a-z0-9]+-[a-z0-9]+$ ]]; then
        REGION="$REGION_INPUT"
        break
      else
        echo "${RED_TEXT}${BOLD_TEXT}Invalid region format.${RESET_FORMAT}"
      fi
    done
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION

gcloud config set compute/region $REGION >/dev/null

echo
echo "${PURPLE_TEXT}${BOLD_TEXT}Enabling required Google Cloud APIs...${RESET_FORMAT}"

gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com

echo
echo "${GOLD_TEXT}${BOLD_TEXT}Waiting 20 seconds for services to initialize...${RESET_FORMAT}"

for i in $(seq 20 -1 1); do
  echo -ne "${WHITE_TEXT}${BOLD_TEXT}$i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Services initialized successfully.${RESET_FORMAT}"

echo
echo "${PURPLE_TEXT}${BOLD_TEXT}Assigning IAM Roles...${RESET_FORMAT}"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role="roles/clouddeploy.jobRunner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role="roles/container.developer"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Artifact Registry Repository...${RESET_FORMAT}"

gcloud artifacts repositories create cicd-challenge \
--description="Image registry" \
--repository-format=docker \
--location=$REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating GKE Clusters (Async)...${RESET_FORMAT}"
gcloud container clusters create cd-staging --node-locations=$ZONE --num-nodes=1 --async
gcloud container clusters create cd-production --node-locations=$ZONE --num-nodes=1 --async

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Cloning Cloud Deploy Tutorials Repository...${RESET_FORMAT}"

cd ~
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Generating skaffold.yaml from template...${RESET_FORMAT}"
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
sed -i "s/{{project-id}}/$PROJECT_ID/g" web/skaffold.yaml

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Checking Cloud Storage Bucket...${RESET_FORMAT}"

if ! gsutil ls "gs://${PROJECT_ID}_cloudbuild/" &>/dev/null; then
  echo "${GOLD_TEXT}${BOLD_TEXT}Bucket missing. Creating...${RESET_FORMAT}"
  gsutil mb -p "$PROJECT_ID" -l "$REGION" -b on "gs://${PROJECT_ID}_cloudbuild/"
fi

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Building Project with Skaffold...${RESET_FORMAT}"

cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/cicd-challenge \
--file-output artifacts.json
cd ..

echo
echo "${PURPLE_TEXT}${BOLD_TEXT}Preparing Delivery Pipeline...${RESET_FORMAT}"

cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
sed -i "s/targetId: staging/targetId: cd-staging/" clouddeploy-config/delivery-pipeline.yaml
sed -i "s/targetId: prod/targetId: cd-production/" clouddeploy-config/delivery-pipeline.yaml
sed -i "/targetId: test/d" clouddeploy-config/delivery-pipeline.yaml

gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Waiting for clusters to reach RUNNING state...${RESET_FORMAT}"

CLUSTERS=("cd-production" "cd-staging")

for cluster in "${CLUSTERS[@]}"; do
  status=$(gcloud container clusters describe "$cluster" --format="value(status)")
  while [ "$status" != "RUNNING" ]; do
    echo "${GOLD_TEXT}${BOLD_TEXT}$cluster is $status. Waiting...${RESET_FORMAT}"
    sleep 10
    status=$(gcloud container clusters describe "$cluster" --format="value(status)")
  done
  echo "${GREEN_TEXT}${BOLD_TEXT}$cluster is RUNNING.${RESET_FORMAT}"
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring kubectl contexts...${RESET_FORMAT}"

CONTEXTS=("cd-staging" "cd-production")

for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Applying Kubernetes Namespace...${RESET_FORMAT}"

for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud Deploy Targets...${RESET_FORMAT}"

for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

echo
echo "${PURPLE_TEXT}${BOLD_TEXT}Creating First Release (web-app-001)...${RESET_FORMAT}"

gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Monitoring rollout...${RESET_FORMAT}"

while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Staging rollout SUCCEEDED.${RESET_FORMAT}"
    break
  fi
  echo "${GOLD_TEXT}${BOLD_TEXT}Rollout status: $status. Waiting...${RESET_FORMAT}"
  sleep 10
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Promoting Release to Production...${RESET_FORMAT}"

gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Waiting for PENDING_APPROVAL...${RESET_FORMAT}"

while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "PENDING_APPROVAL" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Ready for approval.${RESET_FORMAT}"
    break
  fi
  sleep 10
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Approving Production Rollout...${RESET_FORMAT}"

gcloud beta deploy rollouts approve web-app-001-to-cd-production-0001 \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Monitoring production rollout...${RESET_FORMAT}"

while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Production rollout SUCCEEDED.${RESET_FORMAT}"
    break
  fi
  sleep 10
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Second Release (web-app-002)...${RESET_FORMAT}"

cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/cicd-challenge \
--file-output artifacts.json
cd ..

gcloud beta deploy releases create web-app-002 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

echo
echo "${TEAL_TEXT}${BOLD_TEXT}Waiting for rollout...${RESET_FORMAT}"

while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-002 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Second rollout SUCCEEDED.${RESET_FORMAT}"
    break
  fi
  sleep 10
done

echo
echo "${GOLD_TEXT}${BOLD_TEXT}Rolling back Staging Target...${RESET_FORMAT}"

gcloud deploy targets rollback cd-staging \
   --delivery-pipeline=web-app \
   --quiet


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
