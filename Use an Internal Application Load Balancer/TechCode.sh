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

export REGION=$(gcloud config get-value compute/region)
export ZONE=$(gcloud config get-value compute/zone)

# Replace with the IP shown in the lab
ILB_IP="REPLACE_WITH_LAB_IP"

msg() {
    echo "${GREEN_TEXT}${BOLD_TEXT}[+]${RESET_FORMAT} $1"
}

warn() {
    echo "${YELLOW_TEXT}${BOLD_TEXT}[!]${RESET_FORMAT} $1"
}

err() {
    echo "${RED_TEXT}${BOLD_TEXT}[-]${RESET_FORMAT} $1"
}

msg "Installing virtualenv..."
sudo apt-get update -y
sudo apt-get install -y virtualenv

msg "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

msg "Enabling Gemini API..."
gcloud services enable cloudaicompanion.googleapis.com


msg "Creating backend startup script..."

cat > backend.sh <<'EOF'
sudo chmod -R 777 /usr/local/sbin/

sudo cat << 'PYEOF' > /usr/local/sbin/serveprimes.py
import http.server

def is_prime(a):
    return a != 1 and all(a % i for i in range(2, int(a**0.5)+1))

class myHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(
            bytes(str(is_prime(int(self.path[1:]))).encode("utf-8"))
        )

http.server.HTTPServer(("",80), myHandler).serve_forever()
PYEOF

nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &
EOF

msg "Creating instance template..."

gcloud compute instance-templates create primecalc \
    --metadata-from-file startup-script=backend.sh \
    --no-address \
    --tags backend \
    --machine-type=e2-medium

msg "Creating backend firewall rule..."

gcloud compute firewall-rules create http \
    --network default \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --target-tags backend \
    --quiet || true

msg "Creating managed instance group..."

gcloud compute instance-groups managed create backend \
    --size 3 \
    --template primecalc \
    --zone "$ZONE"

msg "Creating health check..."

gcloud compute health-checks create http ilb-health \
    --request-path /2

msg "Creating backend service..."

gcloud compute backend-services create prime-service \
    --load-balancing-scheme internal \
    --region "$REGION" \
    --protocol tcp \
    --health-checks ilb-health

msg "Adding backend group..."

gcloud compute backend-services add-backend prime-service \
    --instance-group backend \
    --instance-group-zone "$ZONE" \
    --region "$REGION"

msg "Creating forwarding rule..."

gcloud compute forwarding-rules create prime-lb \
    --load-balancing-scheme internal \
    --ports 80 \
    --network default \
    --region "$REGION" \
    --address "$ILB_IP" \
    --backend-service prime-service

msg "Creating frontend startup script..."

cat > frontend.sh <<EOF
sudo chmod -R 777 /usr/local/sbin/

sudo cat << 'PYEOF' > /usr/local/sbin/getprimes.py
import urllib.request
from multiprocessing.dummy import Pool as ThreadPool
import http.server

PREFIX="http://${ILB_IP}/"

def get_url(number):
    return urllib.request.urlopen(
        PREFIX + str(number)
    ).read().decode("utf-8")

class myHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type","text/html")
        self.end_headers()

        i = int(self.path[1:]) if len(self.path) > 1 else 1

        self.wfile.write("<html><body><table>".encode())

        pool = ThreadPool(10)
        results = pool.map(get_url, range(i, i + 100))

        for x in range(100):

            if not (x % 10):
                self.wfile.write("<tr>".encode())

            if results[x] == "True":
                self.wfile.write("<td bgcolor='#00ff00'>".encode())
            else:
                self.wfile.write("<td bgcolor='#ff0000'>".encode())

            self.wfile.write(str(x+i).encode() + "</td>".encode())

            if not ((x+1) % 10):
                self.wfile.write("</tr>".encode())

        self.wfile.write("</table></body></html>".encode())

http.server.HTTPServer(("",80), myHandler).serve_forever()
PYEOF

nohup python3 /usr/local/sbin/getprimes.py >/dev/null 2>&1 &
EOF

msg "Creating frontend VM..."

gcloud compute instances create frontend \
    --zone "$ZONE" \
    --metadata-from-file startup-script=frontend.sh \
    --tags frontend \
    --machine-type=e2-standard-2

msg "Creating frontend firewall rule..."

gcloud compute firewall-rules create http2 \
    --network default \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --target-tags frontend \
    --quiet || true

msg "Fetching frontend external IP..."

sleep 30

gcloud compute instances describe frontend \
    --zone "$ZONE" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Lab deployment complete!${RESET_FORMAT}"
echo "${YELLOW_TEXT}Open the IP above in your browser.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
