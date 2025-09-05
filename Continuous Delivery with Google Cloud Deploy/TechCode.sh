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
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo ""
  while [ -z "$ZONE" ]; do
    read -p "Enter ZONE: " ZONE
    if [ -z "$ZONE" ]; then
      echo "Zone shoudn't  be empty"
    fi
  done
fi
export ZONE

echo

REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo ""
  if [ -n "$ZONE" ]; then
    echo ""
    REGION="${ZONE%-*}"
    if [ -z "$REGION" ] || [ "$REGION" == "$ZONE" ]; then
        echo ""
    else
        echo ""
    fi
  else
    echo ""
  fi
fi

if [ -z "$REGION" ]; then
  echo ""
  while [ -z "$REGION" ]; do
    read -p "Enter REGION: " REGION
    if [ -z "$REGION" ]; then
      echo "Region shoudn't  be empty"
    fi
  done
fi

export REGION
echo

export PROJECT_ID=$(gcloud config get-value project)
echo

gcloud config set compute/region $REGION
echo

gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
clouddeploy.googleapis.com
echo ""
for i in $(seq 30 -1 1); do
  echo -ne ""
  sleep 1
done
echo -e "\r time complete"

echo
gcloud container clusters create test --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create staging --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create prod --node-locations=$ZONE --num-nodes=1  --async
echo

gcloud container clusters list --format="csv(name,status)"
echo

gcloud artifacts repositories create web-app \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION
echo

cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base
echo

envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml


if grep -q "{{project-id}}" web/skaffold.yaml; then
  echo ""
  cp web/skaffold.yaml web/skaffold.yaml.bak
  sed -i "s/{{project-id}}/$PROJECT_ID/g" web/skaffold.yaml
  echo ""
fi

cat web/skaffold.yaml
echo

if ! gsutil ls "gs://${PROJECT_ID}_cloudbuild/" &>/dev/null; then
  echo ""
  if gsutil mb -p "${PROJECT_ID}" -l "${REGION}" -b on "gs://${PROJECT_ID}_cloudbuild/"; then
    echo ""
    sleep 5
  else
    echo ""
    echo ""
  fi
else
  echo ""
fi
echo

cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--file-output artifacts.json
cd ..
echo ""
echo

if [ ! -f web/artifacts.json ]; then
    echo "Error: web/artifacts.json not found. 'skaffold build' might have failed or did not produce the artifact list. Cannot proceed with release creation."
fi
echo ""

echo

echo ""
gcloud artifacts docker images list \
$REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--include-tags \
--format yaml
echo

gcloud config set deploy/region $REGION
echo

cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
echo

gcloud beta deploy delivery-pipelines describe web-app
echo

echo ""
while true; do
  cluster_statuses=$(gcloud container clusters list --format="csv(name,status)" | tail -n +2)
  all_running=true 

  if [ -z "$cluster_statuses" ]; then
    echo ""
    all_running=false
  else
    echo ""
    echo "$cluster_statuses" | while IFS=, read -r cluster_name cluster_status; do
      # Trim whitespace which can affect comparisons
      cluster_name_trimmed=$(echo "$cluster_name" | tr -d '[:space:]')
      cluster_status_trimmed=$(echo "$cluster_status" | tr -d '[:space:]')

      if [ -z "$cluster_name_trimmed" ]; then # Skip empty lines that might result from gcloud output processing
          continue
      fi

      echo "${CYAN_TEXT}Cluster: ${cluster_name_trimmed}, Status: ${cluster_status_trimmed}${RESET_FORMAT}"
      if [[ "$cluster_status_trimmed" != "RUNNING" ]]; then
        all_running=false
      fi
    done
  fi

  if [ "$all_running" = true ] && [ -n "$cluster_statuses" ]; then
    break 
  fi
  
  echo ""
  for i in $(seq 10 -1 1); do
    echo -ne "\r $i seconds remaining before next check... "
    sleep 1
  done
  echo -e "\r Re-checking now...                             " 
done 
echo 

CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    echo ""
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done
echo

for CONTEXT_NAME in ${CONTEXTS[@]} 
do
    echo ""
    MAX_RETRIES=20
    RETRY_COUNT=0
    SUCCESS=false
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if kubectl --context ${CONTEXT_NAME} apply -f kubernetes-config/web-app-namespace.yaml; then
            echo ""
            SUCCESS=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT+1))
            echo "Failed to apply namespace to ${CONTEXT_NAME} (attempt ${RETRY_COUNT}/${MAX_RETRIES}). Will retry after delay.${RESET_FORMAT}"
            
            RETRY_WAIT_SECONDS=5
            for i in $(seq $RETRY_WAIT_SECONDS -1 1); do
          echo -ne "$i seconds remaining...                                 "
          sleep 1
            done
            echo -e "\r Retrying now...                                               ${RESET_FORMAT}"
        fi
    done
    if [ "$SUCCESS" != true ]; then
        echo " Failed to apply namespace to ${CONTEXT_NAME} after ${MAX_RETRIES} attempts. This might cause subsequent steps to fail.${RESET_FORMAT}"
    fi
done
echo " Namespace application process completed for all contexts.${RESET_FORMAT}"
echo

echo " Configuring Cloud Deploy targets for each context...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${CYAN_TEXT}${BOLD_TEXT}Processing target: ${CONTEXT}...${RESET_FORMAT}"
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file=clouddeploy-config/target-$CONTEXT.yaml --region=${REGION} --project=${PROJECT_ID}
done
echo ""
echo
echo
sleep 10

echo
gcloud beta deploy releases create web-app-001 \
  --delivery-pipeline web-app \
  --build-artifacts web/artifacts.json \
  --source web/ \
  --project=${PROJECT_ID} \
  --region=${REGION}

RELEASE_CREATION_STATUS=$?

if [ $RELEASE_CREATION_STATUS -eq 0 ]; then
  echo ""
  echo ""
else
  echo ""
  echo ""
  exit 1 # Exit if release creation fails, as subsequent steps depend on it.
fi
echo

test_rollout_succeeded=false
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for the initial rollout to 'test' target to complete...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --filter="targetId=test" --format="value(state)" | head -n 1)

  if [ "$status" == "SUCCEEDED" ]; then
    echo -e "\r Rollout to 'test' SUCCEEDED!                                        ${RESET_FORMAT}"
    test_rollout_succeeded=true
    break
  elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
    echo -e "\r Rollout to 'test' is ${status}. Please check logs.                 ${RESET_FORMAT}"
    test_rollout_succeeded=false
    break
  fi

  current_status_display=${status:-"UNKNOWN"}
  WAIT_DURATION=10
  for i in $(seq $WAIT_DURATION -1 1); do
    echo -ne " 'Test' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
    sleep 1
  done
  echo -ne "\r 'Test' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
done
echo

if [ "$test_rollout_succeeded" = true ]; then
  echo "${BLUE_TEXT}${BOLD_TEXT}🔬 Switching to 'test' Kubernetes context and verifying deployed resources...${RESET_FORMAT}"
  kubectx test
  kubectl get all -n web-app
  echo

  echo "Promoting release 'web-app-001' to the 'staging' target...${RESET_FORMAT}"
  gcloud beta deploy releases promote \
  --delivery-pipeline web-app \
  --release web-app-001 \
  --quiet
  echo
  staging_rollout_succeeded=false
  echo "Waiting for the rollout to 'staging' target to complete...${RESET_FORMAT}"
  while true; do
    status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --filter="targetId=staging" --format="value(state)" | head -n 1)

    if [ "$status" == "SUCCEEDED" ]; then
      echo -e "\r Rollout to 'staging' SUCCEEDED!                                        ${RESET_FORMAT}"
      staging_rollout_succeeded=true
      break
    elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
      echo -e "\r Rollout to 'staging' is ${status}. Please check logs.                 ${RESET_FORMAT}"
      staging_rollout_succeeded=false
      break
    fi

    current_status_display=${status:-"UNKNOWN"}
    WAIT_DURATION=10
    for i in $(seq $WAIT_DURATION -1 1); do
      echo -ne "'Staging' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
      sleep 1
    done
    echo -ne "\r 'Staging' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
  done
  echo

  if [ "$staging_rollout_succeeded" = true ]; then
    echo " Promoting release 'web-app-001' to the 'prod' target (this will require approval)...${RESET_FORMAT}"
    gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release web-app-001 \
    --quiet
    echo

    prod_rollout_pending_approval=false # Initialize correctly
    while true; do
      status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --filter="targetId=prod" --format="value(state)" | head -n 1) # Corrected filter to targetId

      if [ "$status" == "PENDING_APPROVAL" ]; then
        echo -e "\r Rollout to 'prod' is now PENDING_APPROVAL!                                 ${RESET_FORMAT}"
        prod_rollout_pending_approval=true # Set to true when condition met
        break
      elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" || "$status" == "SUCCEEDED" ]]; then
        echo -e "\r Rollout to 'prod' is ${status} instead of PENDING_APPROVAL. Please check logs. ${RESET_FORMAT}"
        prod_rollout_pending_approval=false
        break
      fi

      current_status_display=${status:-"UNKNOWN"}
      WAIT_DURATION=10
      for i in $(seq $WAIT_DURATION -1 1); do
        echo -ne " 'Prod' rollout status: ${current_status_display}. Waiting for PENDING_APPROVAL. $i seconds remaining... ${RESET_FORMAT}            "
        sleep 1
      done
      echo -ne "\r 'Prod' rollout status: ${current_status_display}. Re-checking now...                                           ${RESET_FORMAT}"
    done
    echo

    if [ "$prod_rollout_pending_approval" = true ]; then
      prod_rollout_name=$(gcloud beta deploy rollouts list \
        --delivery-pipeline web-app \
        --release web-app-001 \
        --filter="targetId=prod AND state=PENDING_APPROVAL" \
        --format="value(name)" | head -n 1)

      if [ -n "$prod_rollout_name" ]; then
        echo "Approving rollout '$prod_rollout_name' for 'prod' target...${RESET_FORMAT}" # Added approval message
        gcloud beta deploy rollouts approve "$prod_rollout_name" \
        --delivery-pipeline web-app \
        --release web-app-001 \
        --quiet
        echo

        prod_rollout_succeeded=false 
        while true; do
          status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --filter="targetId=prod" --format="value(state)" | head -n 1) # Corrected filter to targetId

          if [ "$status" == "SUCCEEDED" ]; then
            echo -e "\r Rollout to 'prod' SUCCEEDED!                                        ${RESET_FORMAT}"
            prod_rollout_succeeded=true # Set to true on success
            break
          elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
            echo -e "\r  Rollout to 'prod' is ${status}. Please check logs.                 ${RESET_FORMAT}"
            prod_rollout_succeeded=false
            break
          fi

          current_status_display=${status:-"UNKNOWN"}
          WAIT_DURATION=10
          for i in $(seq $WAIT_DURATION -1 1); do
            echo -ne " 'Prod' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
            sleep 1
          done
          echo -ne "\r 'Prod' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
        done
        echo

        if [ "$prod_rollout_succeeded" = true ]; then
          echo ""
          kubectx prod
          kubectl get all -n web-app
        else
          echo ""
        fi
      else
        echo ""
      fi
    else
      echo ""
    fi
  else
    echo ""
  fi
else
  echo ""
fi
echo

kubectx prod
kubectl get all -n web-app

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
