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

    # Define text formatting variables
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

# Step 1: Set Compute Zone & Region
echo "${BOLD}${GREEN}Setting Compute Zone & Region${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE

gcloud config set compute/region $REGION

function set_regions {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Enter your REGION_2: ${RESET}"
        read -r REGION_2

        echo
        echo -n "${BOLD}${MAGENTA}Enter your REGION_3: ${RESET}"
        read -r REGION_3

        if [[ -z "$REGION_2" || -z "$REGION_3" ]]; then
            echo
            echo "${BOLD}${RED}Neither REGION_2 nor REGION_3 can be empty. Please enter valid values.${RESET}"
            echo
        else
            export REGION_2="$REGION_2"
            export ZONE_3="$ZONE_3"
            echo
            echo "${BOLD}${GREEN}REGION_2 set to $REGION_2${RESET}"
            echo "${BOLD}${BLUE}REGION_3 set to $REGION_3${RESET}"
            echo
            break
        fi
    done
}

# Call function to get input from user
set_regions

# Step 2: Creating Custom Network
echo "${BOLD}${YELLOW}Creating Custom Network${RESET}"
gcloud compute networks create taw-custom-network --subnet-mode custom

# Step 3: Creating Subnet in Region 1
echo "${BOLD}${RED}Creating Subnet in $REGION${RESET}"
gcloud compute networks subnets create subnet-$REGION \
   --network taw-custom-network \
   --region $REGION \
   --range 10.0.0.0/16

# Step 4: Creating Subnet in Region 2
echo "${BOLD}${GREEN}Creating Subnet in $REGION_2${RESET}"
gcloud compute networks subnets create subnet-$REGION_2 \
   --network taw-custom-network \
   --region $REGION_2 \
   --range 10.1.0.0/16

# Step 5: Creating Subnet in Region 3
echo "${BOLD}${BLUE}Creating Subnet in $REGION_3${RESET}"
gcloud compute networks subnets create subnet-$REGION_3 \
   --network taw-custom-network \
   --region $REGION_3 \
   --range 10.2.0.0/16

# Step 6: Listing Subnets
echo "${BOLD}${MAGENTA}Listing Subnets${RESET}"
gcloud compute networks subnets list \
   --network taw-custom-network

# Step 7: Creating Firewall Rule for HTTP Traffic
echo "${BOLD}${CYAN}Creating Firewall Rule for HTTP Traffic${RESET}"
gcloud compute firewall-rules create nw101-allow-http \
--allow tcp:80 --network taw-custom-network --source-ranges 0.0.0.0/0 \
--target-tags http

# Step 8: Creating Firewall Rule for ICMP Traffic
echo "${BOLD}${YELLOW}Creating Firewall Rule for ICMP Traffic${RESET}"
gcloud compute firewall-rules create "nw101-allow-icmp" --allow icmp --network "taw-custom-network" --target-tags rules

# Step 9: Creating Firewall Rule for Internal Traffic
echo "${BOLD}${RED}Creating Firewall Rule for Internal Traffic${RESET}"
gcloud compute firewall-rules create "nw101-allow-internal" --allow tcp:0-65535,udp:0-65535,icmp --network "taw-custom-network" --source-ranges "10.0.0.0/16","10.2.0.0/16","10.1.0.0/16"

# Step 10: Creating Firewall Rule for SSH Traffic
echo "${BOLD}${GREEN}Creating Firewall Rule for SSH Traffic${RESET}"
gcloud compute firewall-rules create "nw101-allow-ssh" --allow tcp:22 --network "taw-custom-network" --target-tags "ssh"

# Step 11: Creating Firewall Rule for RDP Traffic
echo "${BOLD}${BLUE}Creating Firewall Rule for RDP Traffic${RESET}"
gcloud compute firewall-rules create "nw101-allow-rdp" --allow tcp:3389 --network "taw-custom-network"

echo

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

    # Final message
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
    echo
    echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
    echo
