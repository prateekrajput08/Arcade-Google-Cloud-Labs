#!/bin/bash

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# SSH install dependencies and clone repo (idempotent)
echo "Installing packages and cloning repo via SSH..."
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  sudo apt-get update -y && \
  sudo apt-get install -y git maven openjdk-11-jdk lsof && \
  if [ ! -d speaking-with-a-webpage ]; then
    git clone https://github.com/googlecodelabs/speaking-with-a-webpage.git
  else
    echo 'Repository already cloned, skipping git clone.'
  fi
"

# Extra wait for VM readiness
echo " Waiting 30 seconds for VM to initialize..."
sleep 30

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo " External IP address: $EXTERNAL_IP"

echo " Connecting to VM via SSH to start Task 3 Jetty server..."

# Start Task 3 server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  sudo update-alternatives --set java /usr/lib/jvm/java-11-openjdk-amd64/bin/java || true
  cd speaking-with-a-webpage/01-hello-https
  nohup mvn clean jetty:run > jetty.log 2>&1 &
"

echo " Jetty server for Task 3 started on VM."
echo ""
echo " Open your browser and visit: https://$EXTERNAL_IP:8443"
echo "Your browser will warn about the self-signed SSL certificate — this is expected."
echo ""
read -p "After confirming the servlet is working and you've checked your progress in the lab, press Enter to continue to Task 4..."

# Stop Task 3 Jetty server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  PID=\$(sudo lsof -ti tcp:8443)
  if [ -n \"\$PID\" ]; then
    sudo kill \$PID
    echo ' Task 3 Jetty server stopped.'
  else
    echo 'No Jetty server found on port 8443.'
  fi
"

# Start Task 4 server
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  cd speaking-with-a-webpage/02-webaudio
  nohup mvn clean jetty:run > jetty.log 2>&1 &
  echo \$! > jetty.pid
"

echo ""
echo "Jetty server for Task 4 started on VM."
echo " Open your browser and visit: https://$EXTERNAL_IP:8443"
echo ""
read -p "After confirming the Task 4 servlet is working and you've checked your progress in the lab, press Enter to finish..."

echo ""
echo " Lab completed! Remember to stop the server when you're done by running:"
echo "   kill \$(cat jetty.pid)  # on the VM"
echo ""
# Final message

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
