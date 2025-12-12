
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

gcloud auth list

git clone https://github.com/GoogleCloudPlatform/policy-library.git

cd policy-library/
cp samples/iam_service_accounts_only.yaml policies/constraints

cat policies/constraints/iam_service_accounts_only.yaml

cat > main.tf <<EOF_END
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.84"
    }
  }
}

resource "google_project_iam_binding" "sample_iam_binding" {
  project = "$DEVSHELL_PROJECT_ID"
  role    = "roles/viewer"

  members = [
    "user:$USER_EMAIL"
  ]
}
EOF_END

terraform init

terraform plan -out=test.tfplan

terraform show -json ./test.tfplan > ./tfplan.json

sudo apt-get install google-cloud-sdk-terraform-tools

gcloud beta terraform vet tfplan.json --policy-library=.


cd policies/constraints


cat > iam_service_accounts_only.yaml <<EOF_END
apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPIAMAllowedPolicyMemberDomainsConstraintV1
metadata:
  name: service_accounts_only
spec:
  severity: high
  match:
    target: ["organizations/**"]
  parameters:
    domains:
      - gserviceaccount.com
      - qwiklabs.net
EOF_END


cd ~

cd policy-library

terraform plan -out=test.tfplan

gcloud beta terraform vet tfplan.json --policy-library=.

terraform apply test.tfplan

terraform plan -out=test.tfplan

gcloud beta terraform vet tfplan.json --policy-library=.

terraform apply test.tfplan

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
