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




gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION


gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com



sleep 60

mkdir ~/hello-http && cd $_
touch index.js && touch package.json


cat > index.js <<EOF_CP
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOF_CP


cat > package.json <<EOF_CP
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF_CP

#!/bin/bash

deploy_function() {
 gcloud functions deploy nodejs-http-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 1 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done



gcloud functions call nodejs-http-function \
  --gen2 --region $REGION



##################



PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher


mkdir ~/hello-storage && cd $_
touch index.js && touch package.json


cat > index.js <<EOF_CP
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF_CP


cat > package.json <<EOF_CP
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF_CP

BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
gsutil mb -l $REGION $BUCKET


#!/bin/bash

deploy_function() {
 gcloud functions deploy nodejs-storage-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloStorage \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 1 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done



echo "Hello World" > random.txt
gsutil cp random.txt $BUCKET/random.txt


gcloud functions logs read nodejs-storage-function \
  --region $REGION --gen2 --limit=100 --format "value(log)"


##################


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/eventarc.eventReceiver


cd ~
git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git


cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs



#!/bin/bash

deploy_function() {
 gcloud functions deploy gce-vm-labeler \
  --gen2 \
  --runtime nodejs22 \
  --entry-point labelVmCreation \
  --source . \
  --region $REGION \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location $REGION \
  --max-instances 1 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done



#################


gcloud compute instances create instance-1 --zone="$ZONE"

gcloud compute instances describe instance-1 --zone "$ZONE"



mkdir ~/hello-world-colored && cd $_
touch main.py



cat > main.py <<EOF_CP
import os

color = os.environ.get('COLOR')

def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF_CP

echo > requirements.txt 



#!/bin/bash

deploy_function() {
COLOR=yellow
gcloud functions deploy hello-world-colored \
  --gen2 \
  --runtime python39 \
  --entry-point hello_world \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars COLOR=$COLOR \
  --max-instances 1 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done




#############


mkdir ~/min-instances && cd $_
touch main.go


cat > main.go <<EOF_CP
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF_CP


echo "module example.com/mod" > go.mod


#!/bin/bash

deploy_function() {
 gcloud functions deploy slow-function \
  --gen2 \
  --runtime go121 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done


###############


gcloud functions call slow-function \
  --gen2 --region $REGION


export my_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

export path_url="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$my_project$my_region"
export path_url="${path_url}/slow--function:version_1"

gcloud run deploy slow-function \
--image=$path_url \
--min-instances=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID \
 && gcloud run services update-traffic slow-function --to-latest --region=$REGION


gcloud functions call slow-function \
  --gen2 --region $REGION


echo -e "\e[1;93mCheck the progress on TASK 1-6. After that, proceed with the next steps\e[0m"


while true; do
    echo -e "\e[1;93mDo you Want to proceed? (Y/n): \e[0m\c"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo -e "\e[34mRunning the command...\e[0m"
            break
            ;;
        [Nn]|"") 
            echo "Operation canceled."
            break
            ;;
        *) 
            echo -e "\e[31mInvalid input. Please enter Y or N.\e[0m" 
            ;;
    esac
done


SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

hey -n 10 -c 10 $SLOW_URL

gcloud run services delete slow-function --region $REGION --quiet



#!/bin/bash

deploy_function() {
 gcloud functions deploy slow-concurrent-function \
  --gen2 \
  --runtime go121 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    deploy_success=true
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done


#################


export my_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

export path_url="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$my_project$my_region"
export path_url="${path_url}slow--concurrent--function:version_1"

gcloud run deploy slow-concurrent-function \
--image=$path_url \
--concurrency=100 \
--cpu=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID \
--set-env-vars=LOG_EXECUTION_ID=true \
 && gcloud run services update-traffic slow-concurrent-function --to-latest --region=$REGION



SLOW_CONCURRENT_URL=$(gcloud functions describe slow-concurrent-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

hey -n 10 -c 10 $SLOW_CONCURRENT_URL


echo -e "\e[1;93mhttps://console.cloud.google.com/run/deploy/$REGION/slow-concurrent-function?project=$DEVSHELL_PROJECT_ID\e[0m"

# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
