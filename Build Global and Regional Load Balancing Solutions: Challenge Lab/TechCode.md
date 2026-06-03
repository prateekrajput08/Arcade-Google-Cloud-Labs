# GSP539 - Build Global and Regional Load Balancing Solutions (Challenge Lab)

## Overview

This challenge lab requires implementing two different load balancing architectures within the same VPC network:

1. **Regional Internal Proxy Network Load Balancer (Layer 4)**
   - Private internal service
   - Accessible only within the VPC
   - Used for the Transaction Validation Service (TVS)

2. **Global External Application Load Balancer (Layer 7)**
   - Public HTTPS endpoint
   - Multi-region backend deployment
   - Used for the Market Data Feed service

---

# Task 1: Secure Internal Transaction Processor (Regional Internal Proxy NLB)

## Objective

Create a secure internal load balancing solution that:

- Uses a regional Managed Instance Group (MIG)
- Is accessible only through an internal IP address
- Uses a Regional Internal Proxy Network Load Balancer

---

## Step 1: Create Regional Managed Instance Group

Navigate to:

```text
Compute Engine → Instance Groups → Create Instance Group
```

Configure:

| Property | Value |
|----------|--------|
| Name | mig-proxy-internal |
| Template | template-proxy-internal |
| Region | Region B |
| Type | Managed |

Create the instance group.

### Configure Named Port

Open the instance group and add:

| Name | Port |
|------|------|
| tcp80 | 80 |

Save changes.

---

## Step 2: Create Firewall Rules

### Health Check Firewall Rule

Navigate to:

```text
VPC Network → Firewall → Create Firewall Rule
```

Configure:

| Property | Value |
|----------|--------|
| Name | fw-health-check-proxy-internal |
| Direction | Ingress |
| Target Tags | tag-proxy-internal |
| Source Ranges | 130.211.0.0/22,35.191.0.0/16 |
| Protocol | TCP |
| Port | 80 |

Create the rule.

### Proxy Subnet Firewall Rule

Create another firewall rule:

| Property | Value |
|----------|--------|
| Name | fw-proxy-subnet-internal |
| Direction | Ingress |
| Target Tags | tag-proxy-internal |
| Source Range | 10.129.0.0/23 |
| Protocol | TCP |
| Port | 80 |

Create.

---

## Step 3: Create Proxy-Only Subnet

Navigate to:

```text
VPC Network → VPC Networks → lb-network
```

Create subnet:

| Property | Value |
|----------|--------|
| Name | proxy-only-subnet |
| Region | Region B |
| Purpose | Regional Managed Proxy |
| CIDR | 10.129.0.0/23 |

Create the subnet.

---

## Step 4: Create Health Check

Navigate to:

```text
Network Services → Health Checks
```

Create:

| Property | Value |
|----------|--------|
| Name | hc-internal-proxy |
| Protocol | TCP |
| Port | 80 |

Save.

---

## Step 5: Create Internal Proxy Load Balancer

Navigate to:

```text
Network Services → Load Balancing
```

Create:

```text
Regional Internal Proxy Network Load Balancer
```

Backend configuration:

| Property | Value |
|----------|--------|
| Backend | mig-proxy-internal |
| Region | Region B |
| Health Check | hc-internal-proxy |

---

## Step 6: Reserve Internal Static IP

Navigate to:

```text
VPC Network → IP Addresses
```

Reserve:

| Property | Value |
|----------|--------|
| Name | ip-internal-proxy |
| Type | Internal |
| Region | Region B |
| Purpose | Shared Load Balancer VIP |

---

## Step 7: Create Forwarding Rule

Frontend configuration:

| Property | Value |
|----------|--------|
| Name | rule-internal-proxy |
| Protocol | TCP |
| Port | 110 |
| IP Address | ip-internal-proxy |

Finish load balancer creation.

---

## Step 8: Create Client VM

Navigate to:

```text
Compute Engine → VM Instances → Create VM
```

Configure:

| Property | Value |
|----------|--------|
| Name | vm-client-internal |
| Region | Region B |
| Network Tag | allow-ssh |

Create the VM.

---

## Step 9: Validate Access

SSH into the VM.

Test connectivity:

```bash
nc -vz INTERNAL_LB_IP 110
```

or

```bash
curl http://INTERNAL_LB_IP:110
```

Successful responses confirm connectivity.

---

# Task 2: Global External Market Data Feed (Global External ALB)

## Objective

Deploy a global HTTPS Application Load Balancer with:

- Two regional backends
- SSL termination
- Cross-region traffic distribution

---

## Step 1: Create Regional MIG in Region A

Navigate to:

```text
Compute Engine → Instance Groups
```

Create:

| Property | Value |
|----------|--------|
| Name | mig-alb-api-a |
| Template | template-alb-api |
| Region | Region A |

Configure named port:

| Name | Port |
|------|------|
| http80 | 80 |

Save.

---

## Step 2: Create Regional MIG in Region B

Create another instance group:

| Property | Value |
|----------|--------|
| Name | mig-alb-api-b |
| Template | template-alb-api |
| Region | Region B |

Configure named port:

| Name | Port |
|------|------|
| http80 | 80 |

Save.

---

## Step 3: Create HTTP Health Check

Navigate to:

```text
Network Services → Health Checks
```

Create:

| Property | Value |
|----------|--------|
| Name | http-check-alb |
| Protocol | HTTP |
| Port | 80 |

Save.

---

## Step 4: Create Global Backend Service

Navigate to:

```text
Network Services → Load Balancing
```

Create:

```text
Global External Application Load Balancer
```

Backend service:

| Property | Value |
|----------|--------|
| Name | service-alb-global |
| Protocol | HTTP |

Add:

- mig-alb-api-a
- mig-alb-api-b

For each backend:

| Property | Value |
|----------|--------|
| Balancing Mode | Rate |
| Maximum RPS | 1 |

Attach:

```text
http-check-alb
```

---

## Step 5: Create SSL Certificate

Open Cloud Shell.

Generate private key:

```bash
openssl genrsa -out key.pem 2048
```

Generate self-signed certificate:

```bash
openssl req -new -x509 \
-key key.pem \
-out cert.pem \
-days 1 \
-subj "/CN=example.com"
```

Create SSL certificate resource:

```bash
gcloud compute ssl-certificates create cert-self-signed \
    --certificate=cert.pem \
    --private-key=key.pem \
    --global
```

---

## Step 6: Reserve Global External IP

Navigate to:

```text
VPC Network → IP Addresses
```

Reserve:

| Property | Value |
|----------|--------|
| Name | ip-alb-global |
| Type | Global External |

---

## Step 7: Configure HTTPS Frontend

Frontend settings:

| Property | Value |
|----------|--------|
| Protocol | HTTPS |
| Port | 443 |
| IP Address | ip-alb-global |
| Certificate | cert-self-signed |

Finish load balancer creation.

---

## Step 8: Create Firewall Rule

Navigate to:

```text
VPC Network → Firewall
```

Create:

| Property | Value |
|----------|--------|
| Name | fw-allow-health-check-and-proxy |
| Direction | Ingress |
| Source Ranges | 130.211.0.0/22,35.191.0.0/16 |
| Protocol | TCP |
| Port | 80 |

Create.

---

# Task 3: Test Failover and Global Distribution

## Step 1: Verify Traffic Distribution

Obtain the ALB frontend IP address.

Run:

```bash
while true; do
curl -k -s https://LOAD_BALANCER_IP | grep "Hello from"
sleep 0.5
done
```

Expected output alternates between:

```text
Hello from Region A
Hello from Region B
```

This occurs because both backends have Maximum RPS set to 1.

---

## Step 2: Simulate Backend Failure

SSH into an instance in:

```text
mig-alb-api-a
```

Stop nginx:

```bash
sudo systemctl stop nginx
```

Wait for health checks to fail.

Expected behavior:

- Region A traffic drops to zero
- Region B receives all requests

---

## Step 3: Restore Backend

Restart nginx:

```bash
sudo systemctl start nginx
```

Wait until the instance becomes healthy.

Verify that requests again alternate between Region A and Region B.

---

# Completion Checklist

## Internal Proxy NLB

- [ ] mig-proxy-internal created
- [ ] tcp80 named port configured
- [ ] Health check firewall rule created
- [ ] Proxy subnet firewall rule created
- [ ] Internal static IP reserved
- [ ] rule-internal-proxy created
- [ ] vm-client-internal created
- [ ] Connectivity verified

## Global External ALB

- [ ] mig-alb-api-a created
- [ ] mig-alb-api-b created
- [ ] http-check-alb created
- [ ] service-alb-global created
- [ ] cert-self-signed created
- [ ] ip-alb-global reserved
- [ ] HTTPS frontend configured
- [ ] fw-allow-health-check-and-proxy created

## Failover Testing

- [ ] Traffic alternates between regions
- [ ] nginx stopped in Region A
- [ ] Failover verified
- [ ] nginx restarted
- [ ] Health restored
