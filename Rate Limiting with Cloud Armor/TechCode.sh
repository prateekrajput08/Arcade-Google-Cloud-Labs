
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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

read -p "ENTER REGION_1: " REGION1
read -p "ENTER REGION_2: " REGION2
read -p "ENTER ZONE_3: " ZONE3

export REGION3="${ZONE3%-*}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Fetching your GCP Project ID and Project Number...${RESET_FORMAT}"
PROJECT_ID=`gcloud config get-value project`
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo "${GREEN_TEXT}Project ID set to: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}Project Number set to: ${BOLD_TEXT}$PROJECT_NUMBER${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️ Enabling the OS Config API for your project...${RESET_FORMAT}"
gcloud services enable osconfig.googleapis.com
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule to allow HTTP traffic...${RESET_FORMAT}"
gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule for health checks...${RESET_FORMAT}"
gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Creating instance template for REGION1: ${REGION1}...${RESET_FORMAT}"
gcloud compute instance-templates create $REGION1-template --project=$PROJECT_ID --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --region=$REGION1 --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Creating instance template for REGION2: ${REGION2}...${RESET_FORMAT}"
gcloud compute instance-templates create $REGION2-template --project=$PROJECT_ID --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --region=$REGION2 --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🏗️ Creating Managed Instance Group (MIG) and configuring autoscaling for REGION1: ${REGION1}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create $REGION1-mig --project=$PROJECT_ID --base-instance-name=$REGION1-mig --template=projects/$PROJECT_ID/global/instanceTemplates/$REGION1-template --size=1 --region=$REGION1 --target-distribution-shape=EVEN --instance-redistribution-type=proactive --default-action-on-vm-failure=repair --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=pageless && gcloud beta compute instance-groups managed set-autoscaling $REGION1-mig --project=$PROJECT_ID --region=$REGION1 --mode=on --min-num-replicas=1 --max-num-replicas=5 --target-cpu-utilization=0.8 --cpu-utilization-predictive-method=none --cool-down-period=45
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🏗️ Creating Managed Instance Group (MIG) and configuring autoscaling for REGION2: ${REGION2}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create $REGION2-mig --project=$PROJECT_ID --base-instance-name=$REGION2-mig --template=projects/$PROJECT_ID/global/instanceTemplates/$REGION2-template --size=1 --region=$REGION2 --target-distribution-shape=EVEN --instance-redistribution-type=proactive --default-action-on-vm-failure=repair --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=pageless && gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig --project=$PROJECT_ID --region=$REGION2 --mode=on --min-num-replicas=1 --max-num-replicas=5 --target-cpu-utilization=0.8 --cpu-utilization-predictive-method=none --cool-down-period=45
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Setting up authentication token and project ID for API calls...${RESET_FORMAT}"
token=$(gcloud auth application-default print-access-token)
project_id=$(gcloud config get-value project)
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🩺 Creating a global HTTP health check via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {"enable": false},
    "name": "http-health-check",
    "tcpHealthCheck": {"port": 80, "proxyHeader": "NONE"},
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/global/healthChecks"
echo
echo "${YELLOW_TEXT}Waiting for health check to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️ Creating a default security policy for the backend service via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "description": "Default security policy for: http-backend",
    "name": "default-security-policy-for-backend-service-http-backend",
    "rules": [
      {
        "action": "allow",
        "match": {"config": {"srcIpRanges": ["*"]}, "versionedExpr": "SRC_IPS_V1"},
        "priority": 2147483647
      },
      {
        "action": "throttle",
        "description": "Default rate limiting rule",
        "match": {"config": {"srcIpRanges": ["*"]}, "versionedExpr": "SRC_IPS_V1"},
        "priority": 2147483646,
        "rateLimitOptions": {"conformAction": "allow", "enforceOnKey": "IP", "exceedAction": "deny(403)", "rateLimitThreshold": {"count": 500, "intervalSec": 60}}
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$project_id/global/securityPolicies"
echo
echo "${YELLOW_TEXT}Waiting for security policy to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ Creating the global backend service via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "backends": [
      {"balancingMode": "RATE", "capacityScaler": 1, "group": "projects/'"$project_id"'/regions/'"$REGION1"'/instanceGroups/'"$REGION1"'-mig", "maxRatePerInstance": 50},
      {"balancingMode": "UTILIZATION", "capacityScaler": 1, "group": "projects/'"$project_id"'/regions/'"$REGION2"'/instanceGroups/'"$REGION2"'-mig", "maxRatePerInstance": 100, "maxUtilization": 0.8}
    ],
    "enableCDN": true,
    "healthChecks": ["projects/'"$project_id"'/global/healthChecks/http-health-check"],
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-backend",
    "portName": "http",
    "protocol": "HTTP",
    "securityPolicy": "projects/'"$project_id"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/global/backendServices"
echo
echo "${YELLOW_TEXT}Waiting for backend service to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 60 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}🗺️ Creating the URL map for the load balancer via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "defaultService": "projects/'"$project_id"'/global/backendServices/http-backend",
    "name": "http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$project_id/global/urlMaps"
echo
echo "${YELLOW_TEXT}Waiting for URL map to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}🎯 Creating the first Target HTTP Proxy via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'"$project_id"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$project_id/global/targetHttpProxies"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🎯 Creating the second Target HTTP Proxy via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "name": "http-lb-target-proxy-2",
    "urlMap": "projects/'"$project_id"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$project_id/global/targetHttpProxies"
echo
echo "${YELLOW_TEXT}Waiting for target proxies to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}➡️ Creating the IPv4 Global Forwarding Rule via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$project_id"'/global/targetHttpProxies/http-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/global/forwardingRules"
echo
echo "${YELLOW_TEXT}Waiting for forwarding rule to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 20 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}➡️ Creating the IPv6 Global Forwarding Rule via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV6",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule-2",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$project_id"'/global/targetHttpProxies/http-lb-target-proxy-2"
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/global/forwardingRules"
echo
echo "${YELLOW_TEXT}Waiting for forwarding rule to be provisioned... ⏳${RESET_FORMAT}"
for i in $(seq 20 -1 1); do
  echo -ne "${YELLOW_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️ Setting named ports for the instance group in REGION1: ${REGION1} via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{"namedPorts": [{"name": "http", "port": 80}]}' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/regions/$REGION1/instanceGroups/$REGION1-mig/setNamedPorts"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️ Setting named ports for the instance group in REGION2: ${REGION2} via API...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d '{"namedPorts": [{"name": "http", "port": 80}]}' \
  "https://compute.googleapis.com/compute/beta/projects/$project_id/regions/$REGION2/instanceGroups/$REGION2-mig/setNamedPorts"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Creating the 'siege-vm' instance in ZONE3: ${ZONE3}...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will also configure Ops Agent and snapshot policies. ⚙️${RESET_FORMAT}"
gcloud compute instances create siege-vm --project=$PROJECT_ID --zone=$ZONE3 --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-osconfig=TRUE,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud --reservation-affinity=any && printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml && gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE3 --project=$PROJECT_ID --zone=$ZONE3 --file=config.yaml && gcloud compute resource-policies create snapshot-schedule default-schedule-1 --project=$PROJECT_ID --region=$REGION3 --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --daily-schedule --start-time=16:00 && gcloud compute disks add-resource-policies siege-vm --project=$PROJECT_ID --zone=$ZONE3 --resource-policies=projects/$PROJECT_ID/regions/$REGION3/resourcePolicies/default-schedule-1
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📦 Installing 'siege' utility on 'siege-vm' via SSH...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE3" "siege-vm" --project "$PROJECT_ID" --command "sudo apt-get -y install siege" --quiet
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️ Creating a new security policy 'rate-limit-siege' for rate limiting...${RESET_FORMAT}"
gcloud compute security-policies create rate-limit-siege \
    --description "policy for rate limiting"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🚦 Adding a rate limiting rule to 'rate-limit-siege' policy...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This rule will ban IPs exceeding 50 requests in 120 seconds for 300 seconds. ✋${RESET_FORMAT}"
gcloud beta compute security-policies rules create 100 \
    --security-policy=rate-limit-siege     \
    --expression="true" \
    --action=rate-based-ban                   \
    --rate-limit-threshold-count=50           \
    --rate-limit-threshold-interval-sec=120   \
    --ban-duration-sec=300           \
    --conform-action=allow           \
    --exceed-action=deny-404         \
    --enforce-on-key=IP
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔗 Attaching the 'rate-limit-siege' security policy to the 'http-backend' service...${RESET_FORMAT}"
gcloud compute backend-services update http-backend \
    --security-policy rate-limit-siege --global
echo


echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
