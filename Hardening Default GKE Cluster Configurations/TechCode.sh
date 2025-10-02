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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export MY_ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud container clusters create simplecluster --zone $MY_ZONE --num-nodes 2 --metadata=disable-legacy-endpoints=false

kubectl version


sleep 20

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath
spec:
  containers:
  - name: hostpath
    image: google/cloud-sdk:latest
    command: ["/bin/bash"]
    args: ["-c", "tail -f /dev/null"]
    volumeMounts:
    - mountPath: /rootfs
      name: rootfs
  volumes:
  - name: rootfs
    hostPath:
      path: /
EOF

kubectl get pod

sleep 20

gcloud beta container node-pools create second-pool --cluster=simplecluster --zone=$MY_ZONE --num-nodes=1 --metadata=disable-legacy-endpoints=true --workload-metadata-from-node=SECURE

sleep 20

kubectl create clusterrolebinding clusteradmin --clusterrole=cluster-admin --user="$(gcloud config list account --format 'value(core.account)')"

kubectl label namespace default pod-security.kubernetes.io/enforce=restricted

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
   name: pod-security-manager
rules:
- apiGroups: ['policy']
  resources: ['podsecuritypolicies']
  resourceNames: ['privileged', 'baseline', 'restricted']
  verbs: ['use']
- apiGroups: ['']
  resources: ['namespaces']
  verbs: ['get', 'list', 'watch', 'label']
EOF



cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
   name: pod-security-modifier
   namespace: default
subjects:
- kind: Group
  apiGroup: rbac.authorization.k8s.io
  name: system:authenticated
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-security-manager
EOF


sleep 20


gcloud iam service-accounts create demo-developer


MYPROJECT=$(gcloud config list --format 'value(core.project)')


gcloud projects add-iam-policy-binding "${MYPROJECT}" --role=roles/container.developer --member="serviceAccount:demo-developer@${MYPROJECT}.iam.gserviceaccount.com"


gcloud iam service-accounts keys create key.json --iam-account "demo-developer@${MYPROJECT}.iam.gserviceaccount.com"

sleep 15

gcloud auth activate-service-account --key-file=key.json


gcloud container clusters get-credentials simplecluster --zone $MY_ZONE

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath
spec:
  containers:
  - name: hostpath
    image: google/cloud-sdk:latest
    command: ["/bin/bash"]
    args: ["-c", "tail -f /dev/null"]
    volumeMounts:
    - mountPath: /rootfs
      name: rootfs
  volumes:
  - name: rootfs
    hostPath:
      path: /
EOF


kubectl delete pod hostpath

kubectl get psp  # If PodSecurityPolicies are enforced
kubectl get ns -o=jsonpath='{.items[*].metadata.annotations}'


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath
spec:
  containers:
  - name: hostpath
    image: google/cloud-sdk:latest
    command: ["/bin/bash"]
    args: ["-c", "tail -f /dev/null"]
    volumeMounts:
    - mountPath: /rootfs
      name: rootfs
  volumes:
  - name: rootfs
    hostPath:
      path: /
EOF



cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath
spec:
  securityContext:
    runAsNonRoot: true  # Ensure a non-root user
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:  # Add a seccomp profile
      type: RuntimeDefault
  containers:
  - name: hostpath
    image: google/cloud-sdk:latest
    command: ["/bin/bash"]
    args: ["-c", "tail -f /dev/null"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
EOF


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
