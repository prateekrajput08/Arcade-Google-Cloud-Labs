#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          INITIATING EXECUTION     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the first REGION: ${RESET_FORMAT}" REGION1
echo "${GREEN_TEXT}${BOLD_TEXT}First REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the second REGION: ${RESET_FORMAT}" REGION2
echo "${GREEN_TEXT}${BOLD_TEXT}Second REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the VM_ZONE: ${RESET_FORMAT}" VM_ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}VM_ZONE set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$VM_ZONE${RESET_FORMAT}"
echo

# Export variables after collecting input
export REGION1 REGION2 VM_ZONE

export INSTANCE_NAME=$REGION1-mig
export INSTANCE_NAME_2=$REGION2-mig

echo "${YELLOW_TEXT}${BOLD_TEXT}Configuring firewall rule to permit incoming HTTP traffic...${RESET_FORMAT}"
echo
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up firewall rule to allow health check probes...${RESET_FORMAT}"
echo
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating instance template for the first region: ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud compute instance-templates create $REGION1-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION1 --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating instance template for the second region: ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud compute instance-templates create $REGION2-template --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION2 --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Establishing managed instance group and enabling autoscaling for region: ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud beta compute instance-groups managed create $REGION1-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION1-mig --size=1 --template=$REGION1-template --region=$REGION1 --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling $REGION1-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION1 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Establishing managed instance group and enabling autoscaling for region: ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud beta compute instance-groups managed create $REGION2-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION2-mig --size=1 --template=$REGION2-template --region=$REGION2 --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION2 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8
echo

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

echo "${GREEN_TEXT}${BOLD_TEXT}Defining a global TCP health check for the load balancer...${RESET_FORMAT}"
echo
# Create TCP Health Check
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "checkIntervalSec": 5,
        "description": "",
        "healthyThreshold": 2,
        "logConfig": {
            "enable": false
        },
        "name": "http-health-check",
        "tcpHealthCheck": {
            "port": 80,
            "proxyHeader": "NONE"
        },
        "timeoutSec": 5,
        "type": "TCP",
        "unhealthyThreshold": 2
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/healthChecks"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for health check creation to complete...${RESET_FORMAT}"
sleep 60
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Configuring backend services and associating instance groups...${RESET_FORMAT}"
echo
# Create Backend Services
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "backends": [
            {
                "balancingMode": "RATE",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION1"'/instanceGroups/'"$REGION1-mig"'",
                "maxRatePerInstance": 50
            },
            {
                "balancingMode": "UTILIZATION",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION2"'/instanceGroups/'"$REGION2-mig"'",
                "maxRatePerInstance": 80,
                "maxUtilization": 0.8
            }
        ],
        "cdnPolicy": {
            "cacheKeyPolicy": {
                "includeHost": true,
                "includeProtocol": true,
                "includeQueryString": true
            },
            "cacheMode": "CACHE_ALL_STATIC",
            "clientTtl": 3600,
            "defaultTtl": 3600,
            "maxTtl": 86400,
            "negativeCaching": false,
            "serveWhileStale": 0
        },
        "compressionMode": "DISABLED",
        "connectionDraining": {
            "drainingTimeoutSec": 300
        },
        "description": "",
        "enableCDN": true,
        "healthChecks": [
            "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"
        ],
        "loadBalancingScheme": "EXTERNAL",
        "logConfig": {
            "enable": true,
            "sampleRate": 1
        },
        "name": "http-backend"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for backend service creation to complete...${RESET_FORMAT}"
sleep 60
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Setting up the URL map to direct traffic to the backend service...${RESET_FORMAT}"
echo
# Create URL Map
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
        "name": "http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for URL map creation to complete...${RESET_FORMAT}"
sleep 60
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Creating the primary target HTTP proxy for the load balancer...${RESET_FORMAT}"
echo
# Create Target HTTP Proxy
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "http-lb-target-proxy",
        "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for target proxy creation to complete...${RESET_FORMAT}"
sleep 60
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Establishing the primary global forwarding rule (IPv4)...${RESET_FORMAT}"
echo
# Create Forwarding Rule
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "IPProtocol": "TCP",
        "ipVersion": "IPV4",
        "loadBalancingScheme": "EXTERNAL",
        "name": "http-lb-forwarding-rule",
        "networkTier": "PREMIUM",
        "portRange": "80",
        "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for forwarding rule creation to complete...${RESET_FORMAT}"
sleep 60
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Creating the secondary target HTTP proxy...${RESET_FORMAT}"
echo
# Create another Target HTTP Proxy
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "http-lb-target-proxy-2",
        "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for second target proxy creation...${RESET_FORMAT}"
sleep 60
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Establishing the secondary global forwarding rule (IPv6)...${RESET_FORMAT}"
echo
# Create another Forwarding Rule
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "IPProtocol": "TCP",
        "ipVersion": "IPV6",
        "loadBalancingScheme": "EXTERNAL",
        "name": "http-lb-forwarding-rule-2",
        "networkTier": "PREMIUM",
        "portRange": "80",
        "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy-2"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for second forwarding rule creation...${RESET_FORMAT}"
sleep 60
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Assigning named port 'http:80' to the instance group in region: ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}${YELLOW_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
# Set Named Ports for $REGION2 Instance Group
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "namedPorts": [
            {
                "name": "http",
                "port": 80
            }
        ]
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION2/instanceGroups/$INSTANCE_NAME_2/setNamedPorts"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for named port configuration...${RESET_FORMAT}"
sleep 60
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Assigning named port 'http:80' to the instance group in region: ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}${YELLOW_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
# Set Named Ports for $REGION1 Instance Group
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "namedPorts": [
            {
                "name": "http",
                "port": 80
            }
        ]
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION1/instanceGroups/$INSTANCE_NAME/setNamedPorts"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for named port configuration...${RESET_FORMAT}"
sleep 60
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Provisioning the 'siege-vm' instance for load testing in zone: ${CYAN_TEXT}${BOLD_TEXT}$VM_ZONE${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
echo
gcloud compute instances create siege-vm --project=$DEVSHELL_PROJECT_ID --zone=$VM_ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/us-central1-c/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for siege VM creation and startup...${RESET_FORMAT}"
sleep 60
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Retrieving the external IP address of the siege VM...${RESET_FORMAT}"
echo
export EXTERNAL_IP=$(gcloud compute instances describe siege-vm --zone=$VM_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
echo "${GREEN_TEXT}${BOLD_TEXT}Siege VM External IP:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$EXTERNAL_IP${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Allowing time for IP propagation...${RESET_FORMAT}"
sleep 20
echo

echo "${RED_TEXT}${BOLD_TEXT}Creating a Cloud Armor security policy named 'denylist-siege' to block the siege VM's IP...${RESET_FORMAT}"
echo
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d '{
        "adaptiveProtectionConfig": {
            "layer7DdosDefenseConfig": {
                "enable": false
            }
        },
        "description": "",
        "name": "denylist-siege",
        "rules": [
            {
                "action": "deny(403)",
                "description": "",
                "match": {
                    "config": {
                        "srcIpRanges": [
                             "'"${EXTERNAL_IP}"'"
                        ]
                    },
                    "versionedExpr": "SRC_IPS_V1"
                },
                "preview": false,
                "priority": 1000
            },
            {
                "action": "allow",
                "description": "Default rule, higher priority overrides it",
                "match": {
                    "config": {
                        "srcIpRanges": [
                            "*"
                        ]
                    },
                    "versionedExpr": "SRC_IPS_V1"
                },
                "preview": false,
                "priority": 2147483647
            }
        ],
        "type": "CLOUD_ARMOR"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for security policy creation...${RESET_FORMAT}"
sleep 60
echo

echo "${RED_TEXT}${BOLD_TEXT}Attaching the 'denylist-siege' security policy to the 'http-backend' service...${RESET_FORMAT}"
echo
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d "{
        \"securityPolicy\": \"projects/$DEVSHELL_PROJECT_ID/global/securityPolicies/denylist-siege\"
    }" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for security policy attachment...${RESET_FORMAT}"
sleep 60
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Retrieving the IP address of the load balancer...${RESET_FORMAT}"
echo
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)")
echo "${GREEN_TEXT}${BOLD_TEXT}Load Balancer IP Address:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$LB_IP_ADDRESS${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Connecting to the siege VM via SSH, installing siege, and initiating the load test against the LB IP...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Siege command: siege -c 150 -t 120s http://$LB_IP_ADDRESS${RESET_FORMAT}"
echo
gcloud compute ssh --zone "$VM_ZONE" "siege-vm" --project "$DEVSHELL_PROJECT_ID" --quiet --command "sudo apt-get -y update && sudo apt-get -y install siege && export LB_IP=$LB_IP_ADDRESS && echo 'Starting siege test...' && siege -c 150 -t 120s http://\$LB_IP && echo 'Siege test finished.'"



echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
