#!/usr/bin/env bash

set -e

# ================= COLORS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

# ================= SETUP =================
clear
export VAULT_ADDR="http://127.0.0.1:8200"

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Vault Policy Management Script${RESET_FORMAT}"
echo

# ================= READ ROOT TOKEN (PORTABLE) =================
printf "${GREEN_TEXT}Enter Vault ROOT TOKEN: ${RESET_FORMAT}"
stty -echo
read ROOT_TOKEN
stty echo
echo

if [ -z "$ROOT_TOKEN" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}❌ No token entered. Exiting.${RESET_FORMAT}"
  exit 1
fi

# ================= LOGIN =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Logging into Vault as root...${RESET_FORMAT}"
vault login "$ROOT_TOKEN"

# ================= LIST POLICIES =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Listing existing policies${RESET_FORMAT}"
vault policy list

# ================= CREATE POLICY =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating example-policy${RESET_FORMAT}"

cat > example-policy.hcl <<EOF
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts" {
  capabilities = ["read"]
}
EOF

vault policy write example-policy example-policy.hcl

# ================= UPDATE POLICY =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating example-policy${RESET_FORMAT}"

cat > example-policy.hcl <<EOF
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

path "sys/auth" {
  capabilities = ["read"]
}
EOF

vault write sys/policy/example-policy policy=@example-policy.hcl

# ================= UPLOAD POLICY =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading policy to GCS bucket${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
gsutil cp example-policy.hcl "gs://$PROJECT_ID"

# ================= DELETE POLICY =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Deleting example-policy${RESET_FORMAT}"
vault delete sys/policy/example-policy

echo "${YELLOW_TEXT}${BOLD_TEXT}Current policies:${RESET_FORMAT}"
vault policy list

# ================= USERPASS AUTH =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Associating policies with users (Task 6)${RESET_FORMAT}"
vault auth enable userpass || true

vault write auth/userpass/users/firstname-lastname \
  password="s3cr3t!" \
  policies="default,demo-policy"

echo "${GREEN_TEXT}${BOLD_TEXT}User firstname-lastname created${RESET_FORMAT}"

# ================= TOKEN CREATE =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating token with policies${RESET_FORMAT}"
vault token create -policy=dev-readonly -policy=logs || true

# ================= TASK 7 USERS =================
echo "${YELLOW_TEXT}${BOLD_TEXT}Task 7: Creating users${RESET_FORMAT}"

vault write auth/userpass/users/admin \
  password="admin123" \
  policies="admin"

vault write auth/userpass/users/app-dev \
  password="appdev123" \
  policies="appdev"

vault write auth/userpass/users/security \
  password="security123" \
  policies="security"

# ================= DONE =================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        SCRIPT COMPLETED SUCCESSFULLY ✅               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe${RESET_FORMAT}"

