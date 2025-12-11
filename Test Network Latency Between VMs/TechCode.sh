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

# Step 1: Get default zone & region
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting default zone & region${RESET_FORMAT}"
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE_1
gcloud config set compute/region $REGION_1

get_and_export_zones() {
  echo
  echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter values for the following:${RESET_FORMAT}"

  echo
  read -p "$(echo -e "${CYAN}${BOLD_TEXT}Enter ZONE_2 (e.g., us-central1-a): ${RESET_FORMAT}")" ZONE_2
  export ZONE_2=$ZONE_2
  REGION_2=$(echo "$ZONE_2" | sed 's/-[a-z]$//')
  export REGION_2=$REGION_2

  echo

  read -p "$(echo -e "${CYAN}${BOLD_TEXT}Enter ZONE_3 (e.g., us-central1-b): ${RESET_FORMAT}")" ZONE_3
  export ZONE_3=$ZONE_3
  REGION_3=$(echo "$ZONE_3" | sed 's/-[a-z]$//')
  export REGION_3=$REGION_3
  echo
}

get_and_export_zones

# Step 2: Create VM us-test-01
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating instance us-test-01${RESET_FORMAT}"
gcloud compute instances create us-test-01 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 3: Create VM us-test-02
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating instance us-test-02${RESET_FORMAT}"
gcloud compute instances create us-test-02 \
--subnet subnet-$REGION_2 \
--zone $ZONE_2 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 4: Create VM us-test-03
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating instance us-test-03${RESET_FORMAT}"
gcloud compute instances create us-test-03 \
--subnet subnet-$REGION_3 \
--zone $ZONE_3 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 5: Create VM us-test-04
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating instance us-test-04${RESET_FORMAT}"
gcloud compute instances create us-test-04 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--tags ssh,http

# Step 6: Install tools on us-test-01
echo "${BOLD_TEXT}${YELLOW_TEXT}Installing tools on us-test-01${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

timeout 10 traceroute -m 8 www.icann.org
EOF_END

gcloud compute scp prepare_disk.sh us-test-01:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-01 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 7: Install tools on us-test-02
echo "${BOLD_TEXT}${YELLOW_TEXT}Installing tools on us-test-02${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

timeout 10 traceroute -m 8 www.icann.org
EOF_END

gcloud compute scp prepare_disk.sh us-test-02:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet
gcloud compute ssh us-test-02 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 8: Start iperf server on us-test-01
echo "${BOLD_TEXT}${YELLOW_TEXT}Starting iperf server on us-test-01${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'
nohup iperf -s > iperf-server.log 2>&1 &
EOF_END

gcloud compute scp prepare_disk.sh us-test-01:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-01 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 9: Run iperf client from us-test-02 to us-test-01
echo "${BOLD_TEXT}${YELLOW_TEXT}Running iperf client on us-test-02${RESET_FORMAT}"
cat > prepare_disk.sh <<EOF_END
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

iperf -c us-test-01.$ZONE_1 #run in client mode
EOF_END

gcloud compute scp prepare_disk.sh us-test-02:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet
gcloud compute ssh us-test-02 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 10: Install tools on us-test-04
echo "${BOLD_TEXT}${YELLOW_TEXT}Installing tools on us-test-04${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege
EOF_END

gcloud compute scp prepare_disk.sh us-test-04:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-04 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
