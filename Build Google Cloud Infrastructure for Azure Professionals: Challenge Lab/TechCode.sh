
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

# Get Zone Input
echo "${YELLOW}${BOLD}Please enter your preferred zone (e.g., us-central1-a):${RESET}"
read ZONE
export ZONE
export REGION=${ZONE%-*}

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring project settings...${RESET_FORMAT}"
gcloud auth list
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${GREEN_TEXT}${BOLD_TEXT}=== NETWORK CONFIGURATION ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating VPC networks and subnets...${RESET_FORMAT}"
gcloud compute networks create griffin-dev-vpc --subnet-mode custom
gcloud compute networks subnets create griffin-dev-wp --region=$REGION --range=192.168.16.0/20 --network=griffin-dev-vpc
gcloud compute networks subnets create griffin-dev-mgmt --region=$REGION --network=griffin-dev-vpc --range=192.168.32.0/20

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading deployment manager configuration...${RESET_FORMAT}"
gsutil cp -r gs://cloud-training/gsp321/dm .
cd dm
sed -i s/SET_REGION/$REGION/g prod-network.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying production network...${RESET_FORMAT}"
gcloud deployment-manager deployments create prod-network --config=prod-network.yaml
cd ..

echo "${GREEN_TEXT}${BOLD_TEXT}=== BASTION HOST SETUP ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating bastion host and firewall rules...${RESET_FORMAT}"
gcloud compute instances create bastion --zone=$ZONE \
    --network-interface=network=griffin-dev-vpc,subnet=griffin-dev-mgmt \
    --network-interface=network=griffin-prod-vpc,subnet=griffin-prod-mgmt \
    --tags=ssh

gcloud compute firewall-rules create fw-ssh-dev --target-tags ssh --allow=tcp:22 --network=griffin-dev-vpc --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create fw-ssh-prod --target-tags ssh --allow=tcp:22 --network=griffin-prod-vpc --source-ranges=0.0.0.0/0

echo "${GREEN_TEXT}${BOLD_TEXT}=== DATABASE SETUP ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud SQL instance...${RESET_FORMAT}"
gcloud sql instances create griffin-dev-db --region=$REGION --database-version=MYSQL_5_7 --root-password="password123"

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring WordPress database...${RESET_FORMAT}"
gcloud sql databases create wordpress --instance=griffin-dev-db
gcloud sql users create wp_user --instance=griffin-dev-db --password="securepassword"
gcloud sql users list --instance=griffin-dev-db --format="value(name)" --filter="host='%'"

echo "${GREEN_TEXT}${BOLD_TEXT}=== KUBERNETES CLUSTER SETUP ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating GKE cluster...${RESET_FORMAT}"
gcloud container clusters create griffin-dev --zone=$ZONE \
    --machine-type e2-standard-4 \
    --network griffin-dev-vpc \
    --subnetwork griffin-dev-wp \
    --num-nodes 2

gcloud container clusters get-credentials griffin-dev --zone=$ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading Kubernetes configurations...${RESET_FORMAT}"
cd ~/
gsutil cp -r gs://cloud-training/gsp321/wp-k8s .

echo "${GREEN_TEXT}${BOLD_TEXT}=== WORDPRESS DEPLOYMENT ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Kubernetes resources...${RESET_FORMAT}"
cat > wp-k8s/wp-env.yaml <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-volumeclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: database
type: Opaque
stringData:
  username: wp_user
  password: securepassword
EOF

cd wp-k8s
kubectl create -f wp-env.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating service account credentials...${RESET_FORMAT}"
gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
kubectl create secret generic cloudsql-instance-credentials --from-file key.json

INSTANCE_ID=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')

echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying WordPress...${RESET_FORMAT}"
cat > wp-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
        - image: wordpress
          name: wordpress
          env:
          - name: WORDPRESS_DB_HOST
            value: 127.0.0.1:3306
          - name: WORDPRESS_DB_USER
            valueFrom:
              secretKeyRef:
                name: database
                key: username
          - name: WORDPRESS_DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: database
                key: password
          ports:
            - containerPort: 80
              name: wordpress
          volumeMounts:
            - name: wordpress-persistent-storage
              mountPath: /var/www/html
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.33.2
          command: ["/cloud_sql_proxy",
                    "-instances=$INSTANCE_ID=tcp:3306",
                    "-credential_file=/secrets/cloudsql/key.json"]
          securityContext:
            runAsUser: 2
            allowPrivilegeEscalation: false
          volumeMounts:
            - name: cloudsql-instance-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
      volumes:
        - name: wordpress-persistent-storage
          persistentVolumeClaim:
            claimName: wordpress-volumeclaim
        - name: cloudsql-instance-credentials
          secret:
            secretName: cloudsql-instance-credentials
EOF

kubectl create -f wp-deployment.yaml
kubectl create -f wp-service.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}=== USER PERMISSIONS ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Updating user permissions...${RESET_FORMAT}"
IAM_POLICY_JSON=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)
USERS=$(echo $IAM_POLICY_JSON | jq -r '.bindings[] | select(.role == "roles/viewer").members[]')

for USER in $USERS; do
  if [[ $USER == *"user:"* ]]; then
    USER_EMAIL=$(echo $USER | cut -d':' -f2)
    gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
      --member=user:$USER_EMAIL \
      --role=roles/editor
  fi
done

echo "${GREEN_TEXT}${BOLD_TEXT}=== MONITORING SETUP ===${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for WordPress service to be ready...${RESET_FORMAT}"
sleep 60

EXTERNAL_IP=$(kubectl get services wordpress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring uptime monitoring...${RESET_FORMAT}"
cat > terraform.tfvars <<EOF
project_id = "$DEVSHELL_PROJECT_ID"
external_ip = "$EXTERNAL_IP"
EOF

cat > monitoring.tf <<EOF
variable "project_id" {
  description = "The project ID"
}

variable "external_ip" {
  description = "The external IP address"
}

provider "google" {
  project = var.project_id
}

resource "google_monitoring_uptime_check_config" "wordpress_uptime" {
  display_name = "wordpress-uptime-check"
  timeout      = "60s"

  http_check {
    port           = "80"
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.external_ip
    }
  }

  checker_type = "STATIC_IP_CHECKERS"
}
EOF

terraform init
terraform apply --auto-approve

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
