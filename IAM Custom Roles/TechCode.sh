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
    TEAL=$'\033[38;5;50m'

    # Define text formatting variables
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

echo 'title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete' > role-definition.yaml

gcloud iam roles create editor --project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml

gcloud iam roles create viewer --project $DEVSHELL_PROJECT_ID \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA

echo 'description: Edit access for App Versions
etag:
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/'$DEVSHELL_PROJECT_ID'/roles/editor
stage: ALPHA
title: Role Editor' > new-role-definition.yaml

gcloud iam roles update editor --project $DEVSHELL_PROJECT_ID \
--file new-role-definition.yaml --quiet

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--add-permissions storage.buckets.get,storage.buckets.list

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--stage DISABLED

gcloud iam roles delete viewer --project $DEVSHELL_PROJECT_ID

gcloud iam roles undelete viewer --project $DEVSHELL_PROJECT_ID

    # Final message
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
    echo
    echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
    echo
