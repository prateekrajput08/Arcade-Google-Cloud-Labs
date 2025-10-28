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
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Set region from zone
export REGION="${ZONE%-*}"
echo "${BLUE_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo "${BLUE_TEXT}Region: $REGION${RESET_FORMAT}"

# Check authentication
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Google Cloud authentication...${RESET_FORMAT}"
gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)
echo "${BLUE_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating GKE Cluster...${RESET_FORMAT}"

# Create GKE cluster
gcloud beta container --project "$PROJECT_ID" clusters create "quiz-cluster" --zone "$ZONE" --no-enable-basic-auth --cluster-version "latest" --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/cloud-platform" --num-nodes "3" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --binauthz-evaluation-mode=DISABLED --enable-managed-prometheus --enable-shielded-nodes --node-locations "$ZONE"

echo "${GREEN_TEXT}${BOLD_TEXT}GKE cluster created successfully!${RESET_FORMAT}"

# Get cluster credentials
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting cluster credentials...${RESET_FORMAT}"
gcloud container clusters get-credentials quiz-cluster --zone "$ZONE" --project $PROJECT_ID

# Check pods
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking cluster status...${RESET_FORMAT}"
kubectl get pods

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Artifact Registry repository...${RESET_FORMAT}"

# Create Artifact Registry repository
gcloud artifacts repositories create container-dev-repo --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for Container Dev Workshop"

echo "${GREEN_TEXT}${BOLD_TEXT}Artifact Registry repository created!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Dockerfiles...${RESET_FORMAT}"

# Create frontend Dockerfile
cat > frontend/Dockerfile <<EOF_END
FROM gcr.io/google_appengine/python

RUN virtualenv -p python3.7 /env

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

ADD . /app

CMD gunicorn -b 0.0.0.0:\$PORT quiz:app
EOF_END

# Create backend Dockerfile
cat > backend/Dockerfile <<EOF_END
FROM gcr.io/google_appengine/python

RUN virtualenv -p python3.7 /env

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

ADD . /app

CMD python -m quiz.console.worker
EOF_END

echo "${GREEN_TEXT}${BOLD_TEXT}Dockerfiles created successfully!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Building Docker images with Cloud Build...${RESET_FORMAT}"

# Build and push images to Artifact Registry
echo "${YELLOW_TEXT}${BOLD_TEXT}Building frontend image...${RESET_FORMAT}"
gcloud builds submit -t $REGION-docker.pkg.dev/$PROJECT_ID/container-dev-repo/quiz-frontend:v1 ./frontend/

echo "${YELLOW_TEXT}${BOLD_TEXT}Building backend image...${RESET_FORMAT}"
gcloud builds submit -t $REGION-docker.pkg.dev/$PROJECT_ID/container-dev-repo/quiz-backend:v1 ./backend/

echo "${GREEN_TEXT}${BOLD_TEXT}Docker images built and pushed to Artifact Registry!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Kubernetes deployment files...${RESET_FORMAT}"

# Create frontend deployment with Artifact Registry images
cat > frontend-deployment.yaml <<EOF_END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-frontend
  labels:
    app: quiz-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quiz-app
      tier: frontend
  template:
    metadata:
      labels:
        app: quiz-app
        tier: frontend
    spec:
      containers:
      - name: quiz-frontend
        image: $REGION-docker.pkg.dev/$PROJECT_ID/container-dev-repo/quiz-frontend:v1
        imagePullPolicy: Always
        ports:
        - name: http-server
          containerPort: 8080
        env:
          - name: GCLOUD_PROJECT
            value: $PROJECT_ID
          - name: GCLOUD_BUCKET
            value: $GCLOUD_BUCKET
EOF_END

# Create backend deployment with Artifact Registry images
cat > backend-deployment.yaml <<EOF_END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-backend
  labels:
    app: quiz-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: quiz-app
      tier: backend
  template:
    metadata:
      labels:
        app: quiz-app
        tier: backend
    spec:
      containers:
      - name: quiz-backend
        image: $REGION-docker.pkg.dev/$PROJECT_ID/container-dev-repo/quiz-backend:v1
        imagePullPolicy: Always
        env:
          - name: GCLOUD_PROJECT
            value: $PROJECT_ID
          - name: GCLOUD_BUCKET
            value: $GCLOUD_BUCKET
EOF_END

echo "${GREEN_TEXT}${BOLD_TEXT}Deployment files created successfully!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Deploying to Kubernetes cluster...${RESET_FORMAT}"

# Deploy to Kubernetes
kubectl create -f ./frontend-deployment.yaml
kubectl create -f ./backend-deployment.yaml
kubectl create -f ./frontend-service.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking deployment status...${RESET_FORMAT}"
kubectl get deployments
kubectl get services
kubectl get pods

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for services to be ready...${RESET_FORMAT}"
sleep 30

# Get the external IP
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting service external IP...${RESET_FORMAT}"
kubectl get service quiz-frontend

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
