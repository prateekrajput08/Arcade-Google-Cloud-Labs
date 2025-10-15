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


echo "${BLUE}${BOLD}Creating BigQuery Schema and Tables...${RESET}"
bq query --use_legacy_sql=false \
"
-- Create the dataset if it does not exist
CREATE SCHEMA IF NOT EXISTS covid
OPTIONS(
    description='Dataset for COVID-19 Government Response data'
);

-- Create the table with schema from the source table
CREATE OR REPLACE TABLE covid.oxford_policy_tracker
PARTITION BY date
OPTIONS(
    partition_expiration_days=1445,
    description='Oxford Policy Tracker table in the COVID-19 dataset with an expiry time of 1445 days.'
) AS
SELECT
    *
FROM
    \`bigquery-public-data.covid19_govt_response.oxford_policy_tracker\`
WHERE
    alpha_3_code NOT IN ('GBR', 'BRA', 'CAN', 'USA');
"

bq query --use_legacy_sql=false \
"
-- Create the dataset if it does not exist
CREATE SCHEMA IF NOT EXISTS covid_data
OPTIONS(
    description='Dataset for country area data from Census Bureau International public dataset'
);

-- Create the table with the schema from the source table
CREATE OR REPLACE TABLE covid_data.country_area_data
AS
SELECT
    *
FROM
    \`bigquery-public-data.census_bureau_international.country_names_area\`;
"

bq query --use_legacy_sql=false \
"
-- Create the dataset if it does not exist
CREATE SCHEMA IF NOT EXISTS covid_data
OPTIONS(
    description='Dataset for COVID-19 related mobility data'
);

-- Create the table with the schema from the source table
CREATE OR REPLACE TABLE covid_data.mobility_data
AS
SELECT
    *
FROM
    \`bigquery-public-data.covid19_google_mobility.mobility_report\`;
"


echo "${MAGENTA}${BOLD}Cleaning Data in BigQuery Tables...${RESET}"
bq query --use_legacy_sql=false \
"
DELETE FROM covid_data.oxford_policy_tracker_by_countries
WHERE population IS NULL;
"

bq query --use_legacy_sql=false \
"
DELETE FROM covid_data.oxford_policy_tracker_by_countries
WHERE country_area IS NULL;
"
echo

echo -e "\n"  # Adding one blank line

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
