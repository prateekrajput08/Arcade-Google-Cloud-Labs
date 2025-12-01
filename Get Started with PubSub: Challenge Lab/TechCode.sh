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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${TEAL_TEXT}${BOLD_TEXT}Please enter the required details when prompted.${RESET_FORMAT}"
echo

run_form_1() {

    echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${CYAN_TEXT}Creating a subscription to the topic...${RESET_FORMAT}"
    echo
    gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic
    
    echo
    echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${YELLOW_TEXT}Publishing a message to the topic...${RESET_FORMAT}"
    echo "${YELLOW_TEXT}Sending message: '${BOLD_TEXT}Hello World${RESET_FORMAT}${YELLOW_TEXT}' to all subscriptions.${RESET_FORMAT}"
    echo
    gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"
    
    echo
    echo "${MAGENTA_TEXT}${BOLD_TEXT}Waiting:${RESET_FORMAT} ${MAGENTA_TEXT}Allowing some time for processing...${RESET_FORMAT}"
    sleep 10
    
    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Pulling messages from the subscription...${RESET_FORMAT}"
    echo "${GREEN_TEXT}Fetching up to ${BOLD_TEXT}5${RESET_FORMAT}${GREEN_TEXT} messages sent to the topic.${RESET_FORMAT}"
    gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5
    
    echo
    echo "${RED_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${RED_TEXT}Creating a snapshot of the subscription...${RESET_FORMAT}"
    gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription

}

run_form_2() {

    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter your GCP region: ${RESET_FORMAT}" LOCATION
    export LOCATION
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${WHITE_TEXT}Creating Pub/Sub schema using Avro format...${RESET_FORMAT}"
    echo
    gcloud pubsub schemas create city-temp-schema \
            --type=avro \
            --definition='{                                             
                "type" : "record",                               
                "name" : "Avro",                                 
                "fields" : [                                     
                { "name" : "city", "type" : "string" },           
                { "name" : "temperature", "type" : "double" },    
                { "name" : "pressure", "type" : "int" },          
                { "name" : "time_position", "type" : "string" }   
            ]                                                    
        }'
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${WHITE_TEXT}Creating Pub/Sub topic with JSON message encoding...${RESET_FORMAT}"
    echo
    gcloud pubsub topics create temp-topic \
            --message-encoding=JSON \
            --schema=temperature-schema
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${WHITE_TEXT}Enabling necessary Google Cloud services...${RESET_FORMAT}"
    echo
    gcloud services enable eventarc.googleapis.com
    gcloud services enable run.googleapis.com
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${WHITE_TEXT}Generating Node.js Cloud Function file...${RESET_FORMAT}"
    echo
    cat > index.js <<'EOF_END'
    const functions = require('@google-cloud/functions-framework');
    
    functions.cloudEvent('helloPubSub', cloudEvent => {
      const base64name = cloudEvent.data.message.data;
    
      const name = base64name
        ? Buffer.from(base64name, 'base64').toString()
        : 'World';
    
      console.log(`Hello, ${name}!`);
    });
    EOF_END
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${WHITE_TEXT}Creating package.json with dependencies...${RESET_FORMAT}"
    echo
    cat > package.json <<'EOF_END'
    {
      "name": "gcf_hello_world",
      "version": "1.0.0",
      "main": "index.js",
      "scripts": {
        "start": "node index.js",
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      "dependencies": {
        "@google-cloud/functions-framework": "^3.0.0"
      }
    }
EOF_END
    
    echo
    echo "${BLUE_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${WHITE_TEXT}Deploying the Cloud Function...${RESET_FORMAT}"
    echo
    
    deploy_function() {
    gcloud functions deploy gcf-pubsub \
      --gen2 \
      --runtime=nodejs22 \
      --region=$LOCATION \
      --source=. \
      --entry-point=helloPubSub \
      --trigger-topic gcf-topic \
      --quiet
    }
    
    deploy_success=false
    
    echo "${CYAN_TEXT}${BOLD_TEXT}Deployment Status:${RESET_FORMAT} ${WHITE_TEXT}Deploying Cloud Function...${RESET_FORMAT}"
    while [ "$deploy_success" = false ]; do
        if deploy_function; then
            echo "${GREEN_TEXT}${BOLD_TEXT}✅ Success:${RESET_FORMAT} ${WHITE_TEXT}Function deployed successfully!${RESET_FORMAT}"
            deploy_success=true
        else
            echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Retrying:${RESET_FORMAT} ${WHITE_TEXT}Retrying in 20 seconds...${RESET_FORMAT}"
            sleep 20
        fi
    done
}

run_form_3() {

    gcloud pubsub topics create gcloud-pubsub-topic
    gcloud pubsub subscriptions create pubsub-subscription-message --topic=gcloud-pubsub-topic
    gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"
    echo "${WHITE_TEXT}Waiting 10 seconds for message to arrive...${RESET_FORMAT}"
    sleep 10
    gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5
    gcloud pubsub snapshots create pubsub-snapshot --subscription=pubsub-subscription-message
}

echo


echo "${GREEN_TEXT}${BOLD_TEXT}Choose the form number to execute:${RESET_FORMAT}"
read -p "${GREEN_TEXT}${BOLD_TEXT}Enter Form number (1, 2, or 3): ${RESET_FORMAT}" form_number

case $form_number in
    1) run_form_1 ;;
    2) run_form_2 ;;
    3) run_form_3 ;;
    *) echo "${MAROON_TEXT}${BOLD_TEXT}Invalid form number. Please enter 1, 2, or 3.${RESET_FORMAT}" ;;
esac

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more videos!${RESET_FORMAT}"
