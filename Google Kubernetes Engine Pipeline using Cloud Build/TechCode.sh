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
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo ""
echo "${TEAL}${BOLD_TEXT}► Region   : ${RESET_FORMAT}${REGION}"
echo ""

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION

echo "${GREEN_TEXT}PROJECT_ID=${PROJECT_ID}  PROJECT_NUMBER=${PROJECT_NUMBER}${RESET_FORMAT}"

# ─── TASK 1 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 1 ] Initialize Environment${RESET_FORMAT}"

gcloud config set compute/region $REGION

echo "${CYAN_TEXT}→ Enabling APIs...${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com
echo "${GREEN_TEXT}✔ APIs enabled.${RESET_FORMAT}"

echo "${CYAN_TEXT}→ Creating Artifact Registry...${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION
echo "${GREEN_TEXT}✔ Artifact Registry created.${RESET_FORMAT}"

echo "${CYAN_TEXT}→ Creating GKE cluster (3-5 min)...${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild \
  --num-nodes 1 \
  --region $REGION
echo "${GREEN_TEXT}✔ GKE cluster ready.${RESET_FORMAT}"

curl -sS https://webi.sh/gh | sh 
gh auth login 
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}
echo "${GREEN_TEXT}✔ Git configured.${RESET_FORMAT}"

# ─── TASK 2 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 2 ] GitHub Repositories${RESET_FORMAT}"

gh repo create hello-cloudbuild-app --private
echo "${GREEN_TEXT}✔ hello-cloudbuild-app created.${RESET_FORMAT}"

gh repo create hello-cloudbuild-env --private
echo "${GREEN_TEXT}✔ hello-cloudbuild-env created.${RESET_FORMAT}"

cd ~
rm -rf hello-cloudbuild-app
mkdir hello-cloudbuild-app
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app
echo "${GREEN_TEXT}✔ Sample code downloaded.${RESET_FORMAT}"

cd ~/hello-cloudbuild-app
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"
git push google master
echo "${GREEN_TEXT}✔ App repo pushed.${RESET_FORMAT}"

# ─── TASK 3 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 3 ] Build Container Image${RESET_FORMAT}"

cd ~/hello-cloudbuild-app
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
echo "${CYAN_TEXT}→ Building image tag=${COMMIT_ID}...${RESET_FORMAT}"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .
echo "${GREEN_TEXT}✔ Image in Artifact Registry.${RESET_FORMAT}"

# ─── TASK 4 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 4 ] Create CI Trigger (Manual)${RESET_FORMAT}"
echo ""
echo "${YELLOW_TEXT}Go to Cloud Build > Triggers > Create Trigger:${RESET_FORMAT}"
echo "  Name            : ${CYAN_TEXT}hello-cloudbuild${RESET_FORMAT}"
echo "  Region          : ${CYAN_TEXT}${REGION}${RESET_FORMAT}"
echo "  Event           : ${CYAN_TEXT}Push to a branch${RESET_FORMAT}"
echo "  Repo            : ${CYAN_TEXT}${GITHUB_USERNAME}/hello-cloudbuild-app${RESET_FORMAT}"
echo "  Branch          : ${CYAN_TEXT}.* (any branch)${RESET_FORMAT}"
echo "  Config file     : ${CYAN_TEXT}cloudbuild.yaml${RESET_FORMAT}"
echo "  Service account : ${CYAN_TEXT}Compute Engine default${RESET_FORMAT}"
echo ""
read -p "${WHITE_TEXT}Press ENTER when CI trigger is created: ${RESET_FORMAT}"

# ─── CD Trigger (Manual) ──────────────────────────────────────
echo ""
echo "${YELLOW_TEXT}Create CD Trigger in Console:${RESET_FORMAT}"
echo "  Name            : ${CYAN_TEXT}hello-cloudbuild-deploy${RESET_FORMAT}"
echo "  Region          : ${CYAN_TEXT}${REGION}${RESET_FORMAT}"
echo "  Event           : ${CYAN_TEXT}Push to a branch${RESET_FORMAT}"
echo "  Repo            : ${CYAN_TEXT}${GITHUB_USERNAME}/hello-cloudbuild-env${RESET_FORMAT}"
echo "  Branch          : ${CYAN_TEXT}^candidate\$${RESET_FORMAT}  (type manually)"
echo "  Config file     : ${CYAN_TEXT}cloudbuild.yaml${RESET_FORMAT}"
echo "  Service account : ${CYAN_TEXT}Compute Engine default${RESET_FORMAT}"
echo ""
read -p "${WHITE_TEXT}Press ENTER when CD trigger is created: ${RESET_FORMAT}"

cd ~/hello-cloudbuild-app
git commit --allow-empty -m "Trigger CI pipeline"
git push google master
echo "${GREEN_TEXT}✔ CI trigger fired.${RESET_FORMAT}"

# ─── TASK 5 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 5 ] SSH Keys and Secret Manager${RESET_FORMAT}"

cd ~
rm -rf workingdir
mkdir workingdir && cd workingdir
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"
echo "${GREEN_TEXT}✔ SSH key generated.${RESET_FORMAT}"

gcloud secrets create ssh_key_secret \
  --data-file=id_github \
  --replication-policy="automatic"
echo "${GREEN_TEXT}✔ Secret stored in Secret Manager.${RESET_FORMAT}"

echo ""
echo "${YELLOW_TEXT}Add deploy key to GitHub:${RESET_FORMAT}"
echo "  URL: ${UNDERLINE_TEXT}https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env/settings/keys${RESET_FORMAT}"
echo ""
echo "${TEAL}${BOLD_TEXT}--- PUBLIC KEY (copy everything below) ---${RESET_FORMAT}"
cat ~/workingdir/id_github.pub
echo "${TEAL}${BOLD_TEXT}--- END PUBLIC KEY ---${RESET_FORMAT}"
echo ""
echo "  Title         : ${CYAN_TEXT}SSH_KEY${RESET_FORMAT}"
echo "  Allow write   : ${CYAN_TEXT}YES${RESET_FORMAT}"
echo ""
read -p "${WHITE_TEXT}Press ENTER when deploy key is added: ${RESET_FORMAT}"

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
  --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
echo "${GREEN_TEXT}✔ Secret Manager IAM binding done.${RESET_FORMAT}"

rm -f ~/workingdir/id_github ~/workingdir/id_github.pub
echo "${GREEN_TEXT}✔ Local SSH keys deleted.${RESET_FORMAT}"

# ─── TASK 6 ───────────────────────────────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 6 ] CD Pipeline Setup${RESET_FORMAT}"

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
  --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role=roles/container.developer
echo "${GREEN_TEXT}✔ Cloud Build has GKE developer access.${RESET_FORMAT}"

cd ~
rm -rf hello-cloudbuild-env
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env

cd ~/hello-cloudbuild-env
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env
git branch -m master
git add . && git commit -m "initial commit"
git push google master
echo "${GREEN_TEXT}✔ Env repo initial commit pushed.${RESET_FORMAT}"

# Write delivery cloudbuild.yaml
cat > ~/hello-cloudbuild-env/cloudbuild.yaml << ENVEOF
steps:
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy
  args:
  - 'apply'
  - '-f'
  - 'kubernetes.yaml'
  env:
  - 'CLOUDSDK_COMPUTE_REGION=${REGION}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cloudbuild'

- name: 'gcr.io/cloud-builders/git'
  secretEnv: ['SSH_KEY']
  entrypoint: 'bash'
  args:
  - -c
  - |
    echo "\$\$SSH_KEY" >> /root/.ssh/id_rsa
    chmod 400 /root/.ssh/id_rsa
    cp known_hosts.github /root/.ssh/known_hosts
  volumes:
  - name: 'ssh'
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/git'
  args:
  - clone
  - --recurse-submodules
  - git@github.com:${GITHUB_USERNAME}/hello-cloudbuild-env.git
  volumes:
  - name: ssh
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/gcloud'
  id: Copy to production branch
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    set -x && \
    cd hello-cloudbuild-env && \
    git config user.email \$(gcloud auth list --filter=status:ACTIVE --format='value(account)') && \
    git fetch origin production && \
    git checkout production && \
    git checkout \$COMMIT_SHA kubernetes.yaml && \
    git commit -m "Manifest from commit \$COMMIT_SHA" && \
    git push origin production
  volumes:
  - name: ssh
    path: /root/.ssh

availableSecrets:
  secretManager:
  - versionName: projects/${PROJECT_NUMBER}/secrets/ssh_key_secret/versions/1
    env: 'SSH_KEY'

options:
  logging: CLOUD_LOGGING_ONLY
ENVEOF

cd ~/hello-cloudbuild-env
git checkout -b production
git add . && git commit -m "Create cloudbuild.yaml for deployment"
git checkout -b candidate
git push google production
git push google candidate
echo "${GREEN_TEXT}✔ production and candidate branches pushed.${RESET_FORMAT}"

# Add known_hosts to app repo
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github
git add known_hosts.github
git commit -m "Adding known_host file"
git push google master
echo "${GREEN_TEXT}✔ known_hosts pushed to app repo.${RESET_FORMAT}"

# Write full CI cloudbuild.yaml (triggers CD)
cat > ~/hello-cloudbuild-app/cloudbuild.yaml << APPEOF
steps:
- name: 'python:3.7-slim'
  id: Test
  entrypoint: /bin/sh
  args:
  - -c
  - 'pip install flask && python test_app.py -v'

- name: 'gcr.io/cloud-builders/docker'
  id: Build
  args:
  - 'build'
  - '-t'
  - '${REGION}-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:\$SHORT_SHA'
  - '.'

- name: 'gcr.io/cloud-builders/docker'
  id: Push
  args:
  - 'push'
  - '${REGION}-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:\$SHORT_SHA'

- name: 'gcr.io/cloud-builders/git'
  secretEnv: ['SSH_KEY']
  entrypoint: 'bash'
  args:
  - -c
  - |
    echo "\$\$SSH_KEY" >> /root/.ssh/id_rsa
    chmod 400 /root/.ssh/id_rsa
    cp known_hosts.github /root/.ssh/known_hosts
  volumes:
  - name: 'ssh'
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/git'
  args:
  - clone
  - --recurse-submodules
  - git@github.com:${GITHUB_USERNAME}/hello-cloudbuild-env.git
  volumes:
  - name: ssh
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/gcloud'
  id: Change directory
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    cd hello-cloudbuild-env && \
    git checkout candidate && \
    git config user.email \$(gcloud auth list --filter=status:ACTIVE --format='value(account)')
  volumes:
  - name: ssh
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/gcloud'
  id: Generate manifest
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    sed "s/GOOGLE_CLOUD_PROJECT/\$PROJECT_ID/g" kubernetes.yaml.tpl | \
    sed "s/COMMIT_SHA/\$SHORT_SHA/g" > hello-cloudbuild-env/kubernetes.yaml
  volumes:
  - name: ssh
    path: /root/.ssh

- name: 'gcr.io/cloud-builders/gcloud'
  id: Push manifest
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    set -x && \
    cd hello-cloudbuild-env && \
    git add kubernetes.yaml && \
    git commit -m "Deploying image ${REGION}-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:\${SHORT_SHA} built from \${COMMIT_SHA}" && \
    git push origin candidate
  volumes:
  - name: ssh
    path: /root/.ssh

availableSecrets:
  secretManager:
  - versionName: projects/${PROJECT_NUMBER}/secrets/ssh_key_secret/versions/1
    env: 'SSH_KEY'

options:
  logging: CLOUD_LOGGING_ONLY
APPEOF

cd ~/hello-cloudbuild-app
git add cloudbuild.yaml
git commit -m "Trigger CD pipeline"
git push google master
echo "${GREEN_TEXT}✔ Full CI+CD pipeline pushed.${RESET_FORMAT}"

# ─── TASK 7/8: Wait then update app ───────────────────────────
echo ""
echo "${MAGENTA_TEXT}${BOLD_TEXT}[ TASK 7/8 ] Test Full Pipeline${RESET_FORMAT}"
echo "${CYAN_TEXT}→ Waiting 2 min for pipeline to complete...${RESET_FORMAT}"
sleep 120

echo "${CYAN_TEXT}→ Updating app to Hello Cloud Build...${RESET_FORMAT}"
cd ~/hello-cloudbuild-app

# Use python to do replacement to avoid bash ! issue
python3 -c "
content = open('app.py').read().replace('Hello World', 'Hello Cloud Build')
open('app.py', 'w').write(content)
content = open('test_app.py').read().replace('Hello World', 'Hello Cloud Build')
open('test_app.py', 'w').write(content)
print('Replacement done')
"

git add app.py test_app.py
git diff --cached --stat
git commit -m "Hello Cloud Build"
git push google master
echo "${GREEN_TEXT}✔ Hello Cloud Build pushed — full pipeline triggered.${RESET_FORMAT}"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
