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

# ========================= FETCH ZONE & REGION =========================
echo "${TEAL_TEXT}${BOLD_TEXT}Fetching project zone and region...${RESET_FORMAT}"

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN_TEXT}Zone    : $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Region  : $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}Project : $PROJECT_ID${RESET_FORMAT}"
echo

# ========================= AUTH & CONFIG =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Validating authentication and setting configuration...${RESET_FORMAT}"
gcloud auth list
gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"
echo

# ========================= CREATE GKE CLUSTER =========================
echo "${GOLD_TEXT}${BOLD_TEXT}Creating GKE cluster...${RESET_FORMAT}"
gcloud container clusters create test-cluster --num-nodes=3 --enable-ip-alias
echo

# ========================= FRONTEND POD =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying frontend pod...${RESET_FORMAT}"
cat << EOF > gb_frontend_pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: gb-frontend
  name: gb-frontend
spec:
    containers:
    - name: gb-frontend
      image: gcr.io/google-samples/gb-frontend-amd64:v5
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
      ports:
      - containerPort: 80
EOF

kubectl apply -f gb_frontend_pod.yaml
echo

# ========================= CLUSTER IP SERVICE =========================
echo "${NAVY_TEXT}${BOLD_TEXT}Creating ClusterIP service...${RESET_FORMAT}"
cat << EOF > gb_frontend_cluster_ip.yaml
apiVersion: v1
kind: Service
metadata:
  name: gb-frontend-svc
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
spec:
  type: ClusterIP
  selector:
    app: gb-frontend
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
EOF

kubectl apply -f gb_frontend_cluster_ip.yaml
echo

# ========================= INGRESS =========================
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating ingress resource...${RESET_FORMAT}"
cat << EOF > gb_frontend_ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gb-frontend-ingress
spec:
  defaultBackend:
    service:
      name: gb-frontend-svc
      port:
        number: 80
EOF

kubectl apply -f gb_frontend_ingress.yaml
echo

# ========================= WAIT =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for backend services to initialize...${RESET_FORMAT}"
sleep 600

# ========================= BACKEND HEALTH =========================
echo "${TEAL_TEXT}${BOLD_TEXT}Checking backend service health...${RESET_FORMAT}"
BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global

BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global

kubectl get ingress gb-frontend-ingress
echo

# ========================= PART 2 =========================
echo "${CYAN_TEXT}${BOLD_TEXT}Proceeding to Part 2...${RESET_FORMAT}"

while true; do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Do you Want to proceed? (Y/n): ${RESET_FORMAT}"
    read confirm
    case "$confirm" in
        [Yy])
            echo "${GREEN_TEXT}Continuing execution...${RESET_FORMAT}"
            break
            ;;
        [Nn]|"")
            echo "${RED_TEXT}Operation canceled.${RESET_FORMAT}"
            break
            ;;
        *)
            echo "${MAROON_TEXT}Invalid input. Enter Y or N.${RESET_FORMAT}"
            ;;
    esac
done

# ========================= LOCUST SETUP =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Downloading Locust files...${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp769/locust-image .

echo "${BLUE_TEXT}${BOLD_TEXT}Building Locust container image...${RESET_FORMAT}"
gcloud builds submit \
    --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image

gsutil cp gs://spls/gsp769/locust_deploy_v2.yaml .
sed 's/${GOOGLE_CLOUD_PROJECT}/'$GOOGLE_CLOUD_PROJECT'/g' locust_deploy_v2.yaml | kubectl apply -f -

kubectl get service locust-main
echo

# ========================= LIVENESS PROBE =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Deploying liveness probe demo...${RESET_FORMAT}"
cat > liveness-demo.yaml <<EOF_END
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: liveness-probe
  name: liveness-demo-pod
spec:
  containers:
  - name: liveness-demo-pod
    image: centos
    args:
    - /bin/sh
    - -c
    - touch /tmp/alive; sleep infinity
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/alive
      initialDelaySeconds: 5
      periodSeconds: 10
EOF_END

kubectl apply -f liveness-demo.yaml
kubectl describe pod liveness-demo-pod
kubectl exec liveness-demo-pod -- rm /tmp/alive
kubectl describe pod liveness-demo-pod
echo

# ========================= READINESS PROBE =========================
echo "${PURPLE_TEXT}${BOLD_TEXT}Deploying readiness probe demo...${RESET_FORMAT}"
cat << EOF > readiness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: readiness-probe
  name: readiness-demo-pod
spec:
  containers:
  - name: readiness-demo-pod
    image: nginx
    ports:
    - containerPort: 80
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthz
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-demo-svc
  labels:
    demo: readiness-probe
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    demo: readiness-probe
EOF

kubectl apply -f readiness-demo.yaml
kubectl get service readiness-demo-svc
kubectl describe pod readiness-demo-pod

sleep 45

kubectl exec readiness-demo-pod -- touch /tmp/healthz
kubectl describe pod readiness-demo-pod | grep ^Conditions -A 5
echo

# ========================= DEPLOYMENT UPDATE =========================
echo "${GOLD_TEXT}${BOLD_TEXT}Updating frontend to Deployment...${RESET_FORMAT}"
kubectl delete pod gb-frontend

cat << EOF > gb_frontend_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gb-frontend
  labels:
    run: gb-frontend
spec:
  replicas: 5
  selector:
    matchLabels:
      run: gb-frontend
  template:
    metadata:
      labels:
        run: gb-frontend
    spec:
      containers:
        - name: gb-frontend
          image: gcr.io/google-samples/gb-frontend-amd64:v5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
          ports:
            - containerPort: 80
              protocol: TCP
EOF

kubectl apply -f gb_frontend_deployment.yaml
echo

# ========================= LOCUST UI =========================
gcloud builds submit \
    --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image

export LOCUST_IP=$(kubectl get svc locust-main -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$LOCUST_IP:8089
echo "${CYAN_TEXT}${BOLD_TEXT}Locust UI URL: http://$LOCUST_IP:8089${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
