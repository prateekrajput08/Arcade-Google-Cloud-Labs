
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

echo "${YELLOW_TEXT}${BOLD_TEXT}Vault Policy Management Script${RESET_FORMAT}""

# Ask for Root Token
read -s -p "Enter Vault ROOT TOKEN: " ROOT_TOKEN
echo ""
export VAULT_ADDR="http://127.0.0.1:8200"

echo "${YELLOW_TEXT}${BOLD_TEXT}Logging into Vault as root...${RESET_FORMAT}""
vault login "$ROOT_TOKEN"

echo "${YELLOW_TEXT}${BOLD_TEXT}Listing existing policies${RESET_FORMAT}""

vault read sys/policy || vault policy list

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating example-policy${RESET_FORMAT}""

tee example-policy.hcl <<EOF
# List, create, update, and delete key/value secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}
EOF

cat example-policy.hcl

vault policy write example-policy example-policy.hcl

echo "${YELLOW_TEXT}${BOLD_TEXT}Updating example-policy${RESET_FORMAT}""

tee example-policy.hcl <<EOF
# List, create, update, and delete key/value secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}
EOF

cat example-policy.hcl

vault write sys/policy/example-policy policy=@example-policy.hcl

echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading policy to GCS bucket${RESET_FORMAT}""

gsutil cp example-policy.hcl gs://$PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Deleting example-policy${RESET_FORMAT}""

vault delete sys/policy/example-policy

echo "${YELLOW_TEXT}${BOLD_TEXT}Current policies:${RESET_FORMAT}""
vault policy list

echo "${YELLOW_TEXT}${BOLD_TEXT}Associating policies with users (Task 6)${RESET_FORMAT}""

vault auth enable userpass || true

vault write auth/userpass/users/firstname-lastname \
  password="s3cr3t!" \
  policies="default,demo-policy"

echo "${YELLOW_TEXT}${BOLD_TEXT}User firstname-lastname created${RESET_FORMAT}""

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating token with policies${RESET_FORMAT}""

vault token create -policy=dev-readonly -policy=logs || true

echo "${YELLOW_TEXT}${BOLD_TEXT}Task 7: Creating users${RESET_FORMAT}""

vault write auth/userpass/users/admin \
  password="admin123" \
  policies="admin"

vault write auth/userpass/users/app-dev \
  password="appdev123" \
  policies="appdev"

vault write auth/userpass/users/security \
  password="security123" \
  policies="security"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             FOLLOW VIDEO TO GET FULL SCORE            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
