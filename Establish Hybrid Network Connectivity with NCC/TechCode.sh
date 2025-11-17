#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
CYAN_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
YELLOW_TEXT=$'\033[0;96m'
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


if [[ -z "$zone" ]]; then
    echo "${CYAN_TEXT}Enter your Zone (example: us-central1-f):${RESET_FORMAT}"
    read zone
fi

if [[ -z "$zone" ]]; then
    echo "${RED_TEXT}Zone cannot be empty. Exiting.${RESET_FORMAT}"
    exit 1
fi

# Extract region automatically from zone
region=$(echo "$zone" | awk -F'-' '{print $1"-"$2}')

echo "${GREEN_TEXT}Using Zone: $zone${RESET_FORMAT}"
echo "${GREEN_TEXT}Detected Region: $region${RESET_FORMAT}"

gcloud config set compute/zone "$zone" >/dev/null
gcloud config set compute/region "$region" >/dev/null

# Project Detection
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
echo "${GREEN_TEXT}Using Project ID: $PROJECT_ID${RESET_FORMAT}"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Enabling Required API${RESET_FORMAT}"
gcloud services enable networkconnectivity.googleapis.com


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Cloud Routers${RESET_FORMAT}"

routing_vpc_network_name="routing-vpc"
routing_vpc_router_name="routing-vpc-cr"
routing_vpc_router_asn=64525

on_prem_network_name="on-prem-net-vpc"
on_prem_router_name="on-prem-router"
on_prem_router_asn=64526

gcloud compute routers create "$routing_vpc_router_name" \
    --region="$region" \
    --network="$routing_vpc_network_name" \
    --asn="$routing_vpc_router_asn"

gcloud compute routers create "$on_prem_router_name" \
    --region="$region" \
    --network="$on_prem_network_name" \
    --asn="$on_prem_router_asn"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating VPN Gateways${RESET_FORMAT}"

routing_vpn_gateway_name="routing-vpc-vpn-gateway"
on_prem_gateway_name="on-prem-vpn-gateway"

gcloud compute vpn-gateways create "$routing_vpn_gateway_name" \
    --region="$region" \
    --network="$routing_vpc_network_name"

gcloud compute vpn-gateways create "$on_prem_gateway_name" \
    --region="$region" \
    --network="$on_prem_network_name"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating VPN Tunnels${RESET_FORMAT}"

secret_key=$(openssl rand -base64 24)
routing_vpc_tunnel_name="routing-vpc-tunnel"
on_prem_tunnel_name="on-prem-tunnel"

gcloud compute vpn-tunnels create "$routing_vpc_tunnel_name" \
    --vpn-gateway="$routing_vpn_gateway_name" \
    --peer-gcp-gateway="$on_prem_gateway_name" \
    --router="$routing_vpc_router_name" \
    --region="$region" \
    --interface=0 \
    --shared-secret="$secret_key"

gcloud compute vpn-tunnels create "$on_prem_tunnel_name" \
    --vpn-gateway="$on_prem_gateway_name" \
    --peer-gcp-gateway="$routing_vpn_gateway_name" \
    --router="$on_prem_router_name" \
    --region="$region" \
    --interface=0 \
    --shared-secret="$secret_key"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Configuring BGP Peering${RESET_FORMAT}"

interface_hub_name="if-hub-to-prem"
hub_router_ip="169.254.1.1"
prem_router_ip="169.254.1.2"

gcloud compute routers add-interface "$routing_vpc_router_name" \
    --interface-name="$interface_hub_name" \
    --ip-address="$hub_router_ip" \
    --mask-length=30 \
    --vpn-tunnel="$routing_vpc_tunnel_name" \
    --region="$region"

gcloud compute routers add-bgp-peer "$routing_vpc_router_name" \
    --peer-name="bgp-hub-to-prem" \
    --peer-ip-address="$prem_router_ip" \
    --interface="$interface_hub_name" \
    --peer-asn="$on_prem_router_asn" \
    --region="$region"

gcloud compute routers add-interface "$on_prem_router_name" \
    --interface-name="if-prem-to-hub" \
    --ip-address="$prem_router_ip" \
    --mask-length=30 \
    --vpn-tunnel="$on_prem_tunnel_name" \
    --region="$region"

gcloud compute routers add-bgp-peer "$on_prem_router_name" \
    --peer-name="bgp-prem-to-hub" \
    --peer-ip-address="$hub_router_ip" \
    --interface="if-prem-to-hub" \
    --peer-asn="$routing_vpc_router_asn" \
    --region="$region"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Announcing Prefixes${RESET_FORMAT}"

gcloud compute routers update "$routing_vpc_router_name" \
    --advertisement-mode custom \
    --set-advertisement-groups=all_subnets \
    --set-advertisement-ranges="10.0.1.0/24" \
    --region="$region"

gcloud compute routers update "$on_prem_router_name" \
    --advertisement-mode custom \
    --set-advertisement-groups=all_subnets \
    --region="$region"

gcloud compute routers update-bgp-peer "$on_prem_router_name" \
    --peer-name="bgp-prem-to-hub" \
    --advertised-route-priority="111" \
    --region="$region"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating NCC Hub and Spokes${RESET_FORMAT}"

hub_name="mesh-hub"
gcloud network-connectivity hubs create "$hub_name"

vpc_spoke_name="workload-vpc-spoke"
gcloud network-connectivity spokes linked-vpc-network create "$vpc_spoke_name" \
    --hub="$hub_name" \
    --vpc-network="workload-vpc" \
    --global

vpn_spoke_name="hybrid-spoke"
gcloud network-connectivity spokes linked-vpn-tunnels create "$vpn_spoke_name" \
    --region="$region" \
    --hub="$hub_name" \
    --vpn-tunnels="$routing_vpc_tunnel_name"


echo
echo "${GREEN_TEXT}${BOLD_TEXT}Setup Complete${RESET_FORMAT}"
echo "To test connectivity:"
echo "ssh vm3-onprem --zone $zone"
echo "curl 10.0.1.2 -v"
echo


# Final message
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
