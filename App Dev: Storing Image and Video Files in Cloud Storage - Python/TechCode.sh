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

gcloud config set project $DEVSHELL_PROJECT_ID
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start
sed -i s/us-central/$REGION/g prepare_environment.sh

. prepare_environment.sh

gsutil mb gs://$DEVSHELL_PROJECT_ID-media
wget https://storage.googleapis.com/cloud-training/quests/Google_Cloud_Storage_logo.png
gsutil cp Google_Cloud_Storage_logo.png gs://$DEVSHELL_PROJECT_ID-media
export GCLOUD_BUCKET=$DEVSHELL_PROJECT_ID-media

cd quiz/gcp

cat > storage.py <<EOF_END
# TODO: Get the Bucket name from the
# GCLOUD_BUCKET environment variable
bucket_name = os.getenv('GCLOUD_BUCKET')
# END TODO
# TODO: Import the storage module
from google.cloud import storage
# END TODO
# TODO: Create a client for Cloud Storage
storage_client = storage.Client()
# END TODO
# TODO: Use the client to get the Cloud Storage bucket
bucket = storage_client.get_bucket(bucket_name)
# END TODO

"""
Uploads a file to a given Cloud Storage bucket and returns the public url
to the new object.
"""
def upload_file(image_file, public):
    # TODO: Use the bucket to get a blob object
    blob = bucket.blob(image_file.filename)
    # END TODO
    # TODO: Use the blob to upload the file
    blob.upload_from_string(
        image_file.read(),
        content_type=image_file.content_type)
    # END TODO
    # TODO: Make the object public
    if public:
        blob.make_public()
    # END TODO
    # TODO: Modify to return the blob's Public URL
    return blob.public_url
    # END TODO
EOF_END

cd quiz/webapp/

cat > questions.py <<EOF_END
# TODO: Import the storage module
from quiz.gcp import storage, datastore
# END TODO
"""
uploads file into google cloud storage
- upload file
- return public_url
"""
def upload_file(image_file, public):
    if not image_file:
        return None
    # TODO: Use the storage client to Upload the file
    # The second argument is a boolean
    public_url = storage.upload_file(
       image_file,
       public
    )
    # END TODO
    # TODO: Return the public URL
    # for the object
    return public_url
    # END TODO
"""
uploads file into google cloud storage
- call method to upload file (public=true)
- call datastore helper method to save question
"""
def save_question(data, image_file):
    # TODO: If there is an image file, then upload it
    # And assign the result to a new Datastore
    # property imageUrl
    # If there isn't, assign an empty string
    if image_file:
        data['imageUrl'] = str(
                  upload_file(image_file, True))
    else:
        data['imageUrl'] = u''
    # END TODO
    data['correctAnswer'] = int(data['correctAnswer'])
    datastore.save_question(data)
    return

EOF_END

cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start
python run_server.py

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
