#!/bin/bash
# Enhanced Color Definitions
COLOR_BLACK=$'\033[0;30m'
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_MAGENTA=$'\033[0;35m'
COLOR_CYAN=$'\033[0;36m'
COLOR_WHITE=$'\033[0;37m'
COLOR_RESET=$'\033[0m'

# Text Formatting
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
BLINK=$'\033[5m'
REVERSE=$'\033[7m'

clear
# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`


gcloud services enable aiplatform.googleapis.com --project=$PROJECT_ID

sleep 20

bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE embedding_conn

SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.US.embedding_conn | jq -r '.cloudResource.serviceAccountId')


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/bigquery.dataOwner

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/aiplatform.user



bq mk CustomerReview



bq query --use_legacy_sql=false \
"

"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`CustomerReview.Embeddings\`
REMOTE WITH CONNECTION \`us.embedding_conn\`
OPTIONS (ENDPOINT = 'text-embedding-005');
"

bq query --use_legacy_sql=false \
"
LOAD DATA OVERWRITE CustomerReview.customer_reviews
(
    customer_review_id INT64,
    customer_id INT64,
    location_id INT64,
    review_datetime DATETIME,
    review_text STRING,
    social_media_source STRING,
    social_media_handle STRING
)
FROM FILES (
    format = 'CSV',
    uris = ['gs://spls/gsp1249/customer_reviews.csv']
);
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`CustomerReview.customer_reviews_embedded\` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
    MODEL \`CustomerReview.Embeddings\`,
    (SELECT review_text AS content FROM \`CustomerReview.customer_reviews\`)
);
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`CustomerReview.vector_search_result\` AS
SELECT
    query.query,
    base.content
FROM
    VECTOR_SEARCH(
        TABLE \`CustomerReview.customer_reviews_embedded\`,
        'ml_generate_embedding_result',
        (
            SELECT
                ml_generate_embedding_result,
                content AS query
            FROM
                ML.GENERATE_EMBEDDING(
                    MODEL \`CustomerReview.Embeddings\`,
                    (SELECT 'service' AS content)
                )
        ),
        top_k => 5,
        options => '{"fraction_lists_to_search": 0.01}'
    );
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`CustomerReview.Gemini\`
REMOTE WITH CONNECTION \`us.embedding_conn\`
OPTIONS (ENDPOINT = 'gemini-pro');
"


bq query --use_legacy_sql=false \
"
SELECT
    ml_generate_text_llm_result AS generated
FROM
    ML.GENERATE_TEXT(
        MODEL \`CustomerReview.Gemini\`,
        (
            SELECT
                CONCAT(
                    'Summarize what customers think about our services',
                    STRING_AGG(FORMAT('review text: %s', base.content), ',\n')
                ) AS prompt
            FROM
                \`CustomerReview.vector_search_result\` AS base
        ),
        STRUCT(
            0.4 AS temperature,
            300 AS max_output_tokens,
            0.5 AS top_p,
            5 AS top_k,
            TRUE AS flatten_json_output
        )
    );
"


bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE embedding_conn

SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.US.embedding_conn | jq -r '.cloudResource.serviceAccountId')


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/bigquery.dataOwner

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/aiplatform.user



bq mk CustomerReview



bq query --use_legacy_sql=false \
"

"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`CustomerReview.Embeddings\`
REMOTE WITH CONNECTION \`us.embedding_conn\`
OPTIONS (ENDPOINT = 'text-embedding-005');
"

bq query --use_legacy_sql=false \
"
LOAD DATA OVERWRITE CustomerReview.customer_reviews
(
    customer_review_id INT64,
    customer_id INT64,
    location_id INT64,
    review_datetime DATETIME,
    review_text STRING,
    social_media_source STRING,
    social_media_handle STRING
)
FROM FILES (
    format = 'CSV',
    uris = ['gs://spls/gsp1249/customer_reviews.csv']
);
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`CustomerReview.customer_reviews_embedded\` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
    MODEL \`CustomerReview.Embeddings\`,
    (SELECT review_text AS content FROM \`CustomerReview.customer_reviews\`)
);
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`CustomerReview.vector_search_result\` AS
SELECT
    query.query,
    base.content
FROM
    VECTOR_SEARCH(
        TABLE \`CustomerReview.customer_reviews_embedded\`,
        'ml_generate_embedding_result',
        (
            SELECT
                ml_generate_embedding_result,
                content AS query
            FROM
                ML.GENERATE_EMBEDDING(
                    MODEL \`CustomerReview.Embeddings\`,
                    (SELECT 'service' AS content)
                )
        ),
        top_k => 5,
        options => '{"fraction_lists_to_search": 0.01}'
    );
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`CustomerReview.Gemini\`
REMOTE WITH CONNECTION \`us.embedding_conn\`
OPTIONS (ENDPOINT = 'gemini-pro');
"


bq query --use_legacy_sql=false \
"
SELECT
    ml_generate_text_llm_result AS generated
FROM
    ML.GENERATE_TEXT(
        MODEL \`CustomerReview.Gemini\`,
        (
            SELECT
                CONCAT(
                    'Summarize what customers think about our services',
                    STRING_AGG(FORMAT('review text: %s', base.content), ',\n')
                ) AS prompt
            FROM
                \`CustomerReview.vector_search_result\` AS base
        ),
        STRUCT(
            0.4 AS temperature,
            300 AS max_output_tokens,
            0.5 AS top_p,
            5 AS top_k,
            TRUE AS flatten_json_output
        )
    );
"

# Final message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
