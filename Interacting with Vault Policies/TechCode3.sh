

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

set -e

export VAULT_ADDR="http://127.0.0.1:8200"

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 1: LOGIN AS ROOT (FOR SETUP)${RESET_FORMAT}"

read -s -p "${CYAN_TEXT}${BOLD_TEXT}Enter ROOT TOKEN: ${RESET_FORMAT}" ROOT_TOKEN
echo ""
vault login "$ROOT_TOKEN"

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 2: CREATE SECRETS${RESET_FORMAT}"

# security secrets
vault kv put secret/security/first username=password
vault kv put secret/security/second username=password

# appdev secrets
vault kv put secret/appdev/first username=password
vault kv put secret/appdev/beta-app/second username=password

# admin secrets
vault kv put secret/admin/first admin=password
vault kv put secret/admin/supersecret/second admin=password

echo "${CYAN_TEXT}${BOLD_TEXT}Secrets created successfully${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 3: VERIFY APPDEV POLICY${RESET_FORMAT}"

vault login -method=userpass username="app-dev" password="appdev123"

vault kv get secret/appdev/first
vault kv get secret/appdev/beta-app/second

vault kv put secret/appdev/appcreds credentials=creds123
vault kv destroy -versions=1 secret/appdev/appcreds

echo "${CYAN_TEXT}${BOLD_TEXT}Expected DENY below ↓${RESET_FORMAT}"
vault kv get secret/security/first || true
vault kv list secret/ || true

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 4: VERIFY SECURITY POLICY${RESET_FORMAT}"

vault login -method=userpass username="security" password="security123"

vault kv get secret/security/first
vault kv get secret/security/second

vault kv put secret/security/supersecure/bigsecret secret=idk
vault kv destroy -versions=1 secret/security/supersecure/bigsecret

vault kv get secret/appdev/first
vault kv list secret/

vault secrets enable -path=supersecret kv || true

echo "${CYAN_TEXT}${BOLD_TEXT}Expected DENY below ↓${RESET_FORMAT}"

vault kv get secret/admin/first || true
vault kv list secret/admin || true

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 5: VERIFY ADMIN POLICY${RESET_FORMAT}"

vault login -method=userpass username="admin" password="admin123"

vault kv get secret/admin/first
vault kv get secret/security/first

vault kv put secret/webserver/credentials web=awesome
vault kv destroy -versions=1 secret/webserver/credentials

vault kv get secret/appdev/first
vault kv list secret/appdev/

echo "${CYAN_TEXT}${BOLD_TEXT}STEP 6: FINAL VERIFICATION${RESET_FORMAT}"

vault policy list > policies-update.txt
gsutil cp policies-update.txt gs://$PROJECT_ID

vault auth enable gcp || true
vault auth list

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"

