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


git clone https://github.com/rosera/pet-theory.git

cd pet-theory/lab02

npm i && npm audit fix --force

gcloud firestore databases create --location=nam5

firebase login --no-localhost

firebase init


cd public


rm customer.js
rm styles.css

cat > customer.js <<'EOF_CP'
let user;

firebase.auth().onAuthStateChanged(function(newUser) {
  user = newUser;
  if (user) {
    const db = firebase.firestore();
    db.collection("customers").doc(user.email).onSnapshot(function(doc) {
      const cust = doc.data();
      if (cust) {
        document.getElementById('customerName').setAttribute('value', cust.name);
        document.getElementById('customerPhone').setAttribute('value', cust.phone);
      }
      document.getElementById('customerEmail').innerText = user.email;
    });
  }
});

document.getElementById('saveProfile').addEventListener('click', function(ev) {
  const db = firebase.firestore();
  var docRef = db.collection('customers').doc(user.email);
  docRef.set({
    name: document.getElementById('customerName').value,
    email: user.email,
    phone: document.getElementById('customerPhone').value,
  })
})

EOF_CP


cat > styles.css <<'EOF_CP'
body { background: #ECEFF1; color: rgba(0,0,0,0.87); font-family: Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 0; }
#message { background: white; max-width: 360px; margin: 100px auto 16px; padding: 32px 24px 16px; border-radius: 3px; }
#message h3 { color: #888; font-weight: normal; font-size: 16px; margin: 16px 0 12px; }
#message h2 { color: #ffa100; font-weight: bold; font-size: 16px; margin: 0 0 8px; }
#message h1 { font-size: 22px; font-weight: 300; color: rgba(0,0,0,0.6); margin: 0 0 16px;}
#message p { line-height: 140%; margin: 16px 0 24px; font-size: 14px; }
#message a { display: block; text-align: center; background: #039be5; text-transform: uppercase; text-decoration: none; color: white; padding: 16px; border-radius: 4px; }
#message, #message a { box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24); }
#load { color: rgba(0,0,0,0.4); text-align: center; font-size: 13px; }
@media (max-width: 600px) {
  body, #message { margin-top: 0; background: white; box-shadow: none; }
  body { border-top: 16px solid #ffa100; }
}
EOF_CP

firebase deploy


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
