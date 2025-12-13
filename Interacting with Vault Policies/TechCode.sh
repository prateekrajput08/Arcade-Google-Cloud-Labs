
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


# Install HashiCorp Vault
echo "${CYAN_TEXT}${BOLD_TEXT}Installing HashiCorp Vault${RESET_FORMAT}"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update -y
sudo apt-get install vault -y
vault --version

# Start Vault dev server manually
echo "${YELLOW_TEXT}Run this in a NEW Cloud Shell tab:${RESET_FORMAT}"
echo "${GREEN_TEXT}vault server -dev${RESET_FORMAT}"
read -p "Press ENTER once Vault dev server is running..."

# Configure Vault client
export VAULT_ADDR="http://127.0.0.1:8200"
vault status

# Login using root token
read -p "Paste ROOT TOKEN here: " ROOT_TOKEN
vault login "$ROOT_TOKEN"

# Enable userpass authentication
echo "${CYAN_TEXT}Enabling userpass authentication${RESET_FORMAT}"
vault auth enable userpass

# Create base example user
vault write auth/userpass/users/example-user \
  password="password!"

# Create demo policy (CLI)
cat > demo-policy.hcl <<EOF
path "sys/mounts" {
  capabilities = ["read"]
}

path "sys/policies/acl" {
  capabilities = ["read", "list"]
}
EOF

vault policy write demo-policy demo-policy.hcl

# Attach policy to user
vault write auth/userpass/users/example-user \
  password="password!" \
  policies="default,demo-policy"

# Login as example-user to refresh token
vault login -method=userpass username=example-user password=password!

# Verify permissions
vault secrets list || true
vault policy list

TOKEN=$(vault token lookup -format=json | jq -r .data.id)
vault token capabilities "$TOKEN" sys/policies/acl

# Save grading artifacts
vault policy list > policies.txt
vault token capabilities "$TOKEN" sys/policies/acl > token_capabilities.txt

PROJECT_ID=$(gcloud config get-value project)
gsutil cp policies.txt token_capabilities.txt gs://$PROJECT_ID

# Create example policy via CLI
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

vault policy write example-policy example-policy.hcl
gsutil cp example-policy.hcl gs://$PROJECT_ID
vault delete sys/policy/example-policy

# Associate policies with another user
vault write auth/userpass/users/firstname-lastname \
  password="s3cr3t!" \
  policies="default,demo-policy"

vault login -method=userpass username=firstname-lastname password="s3cr3t!"

# Create lab users (policies created manually in UI)
vault write auth/userpass/users/admin password="admin123" policies="admin"
vault write auth/userpass/users/app-dev password="appdev123" policies="appdev"
vault write auth/userpass/users/security password="security123" policies="security"

# Create secrets for testing
vault kv put secret/security/first username=password
vault kv put secret/security/second username=password

vault kv put secret/appdev/first username=password
vault kv put secret/appdev/beta-app/second username=password

vault kv put secret/admin/first admin=password
vault kv put secret/admin/supersecret/second admin=password

# Enable GCP auth method
vault auth enable gcp
vault auth list

# Final policy snapshot for grading
vault policy list > policies-update.txt
gsutil cp policies-update.txt gs://$PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}CLI automation completed successfully${RESET_FORMAT}"
echo "${YELLOW_TEXT}Complete remaining UI-based steps manually${RESET_FORMAT}"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
