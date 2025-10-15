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

# Set dataset names
export DATASET_NAME_1=covid
export DATASET_NAME_2=covid_data

# Task 1: Create dataset and partitioned table
echo "${CYAN}${BOLD}TASK 1: Creating COVID dataset and partitioned table${RESET}"
bq mk --dataset $DEVSHELL_PROJECT_ID:covid
sleep 10

echo "${YELLOW}Creating partitioned oxford_policy_tracker table...${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE $DATASET_NAME_1.oxford_policy_tracker
PARTITION BY date
OPTIONS(
partition_expiration_days=2175,
description='oxford_policy_tracker table in the COVID 19 Government Response public dataset with expiry time set to 2175 days.'
) AS
SELECT
   *
FROM
   \`bigquery-public-data.covid19_govt_response.oxford_policy_tracker\`
WHERE
   alpha_3_code NOT IN ('GBR', 'BRA', 'CAN','USA')
"
echo "${GREEN}Task 1 completed successfully!${RESET}"
echo

# Task 2: Alter table to add columns
echo "${CYAN}${BOLD}TASK 2: Adding columns to global_mobility_tracker_data${RESET}"
echo "${YELLOW}Adding population, country_area and mobility structure...${RESET}"
bq query --use_legacy_sql=false \
"
ALTER TABLE $DATASET_NAME_2.global_mobility_tracker_data
ADD COLUMN population INT64,
ADD COLUMN country_area FLOAT64,
ADD COLUMN mobility STRUCT<
   avg_retail      FLOAT64,
   avg_grocery     FLOAT64,
   avg_parks       FLOAT64,
   avg_transit     FLOAT64,
   avg_workplace   FLOAT64,
   avg_residential FLOAT64
>
"
echo "${GREEN}Task 2 completed successfully!${RESET}"
echo

# Task 3: Create population data table and update
echo "${CYAN}${BOLD}TASK 3: Creating and updating population data${RESET}"
echo "${YELLOW}Creating pop_data_2019 table (full schema copy)...${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE $DATASET_NAME_2.pop_data_2019 AS
SELECT *
FROM 
  \`bigquery-public-data.covid19_ecdc.covid_19_geographic_distribution_worldwide\`
"

echo "${YELLOW}Creating lightweight projection (country_territory_code, pop_data_2019) for joins...${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE $DATASET_NAME_2.pop_data_2019_small AS
SELECT
  country_territory_code,
  pop_data_2019
FROM 
  \`$DEVSHELL_PROJECT_ID.$DATASET_NAME_2.pop_data_2019\`
GROUP BY
  country_territory_code,
  pop_data_2019
ORDER BY
  country_territory_code
"

echo "${YELLOW}Updating population data...${RESET}"
bq query --use_legacy_sql=false \
"
UPDATE
   \`$DATASET_NAME_2.consolidate_covid_tracker_data\` t0
SET
   population = t1.pop_data_2019
FROM
   \`$DATASET_NAME_2.pop_data_2019_small\` t1
WHERE
   TRIM(t0.alpha_3_code) = TRIM(t1.country_territory_code);
"
echo "${GREEN}Task 3 completed successfully!${RESET}"
echo

# Task 4: Update country area data
echo "${CYAN}${BOLD}TASK 4: Updating country area data${RESET}"
echo "${YELLOW}Updating country_area from census data...${RESET}"
bq query --use_legacy_sql=false \
"
UPDATE
   \`$DATASET_NAME_2.consolidate_covid_tracker_data\` t0
SET
   t0.country_area = t1.country_area
FROM
   \`bigquery-public-data.census_bureau_international.country_names_area\` t1
WHERE
   t0.country_name = t1.country_name
"
echo "${GREEN}Task 4 completed successfully!${RESET}"
echo

# Bonus Task: Update mobility data
echo "${CYAN}${BOLD}BONUS TASK: Updating mobility data${RESET}"
echo "${YELLOW}Updating mobility metrics...${RESET}"
bq query --use_legacy_sql=false \
"
UPDATE
   \`$DATASET_NAME_2.consolidate_covid_tracker_data\` t0
SET
   t0.mobility.avg_retail      = t1.avg_retail,
   t0.mobility.avg_grocery     = t1.avg_grocery,
   t0.mobility.avg_parks       = t1.avg_parks,
   t0.mobility.avg_transit     = t1.avg_transit,
   t0.mobility.avg_workplace   = t1.avg_workplace,
   t0.mobility.avg_residential = t1.avg_residential
FROM
   (SELECT country_region, date,
      AVG(retail_and_recreation_percent_change_from_baseline) as avg_retail,
      AVG(grocery_and_pharmacy_percent_change_from_baseline)  as avg_grocery,
      AVG(parks_percent_change_from_baseline) as avg_parks,
      AVG(transit_stations_percent_change_from_baseline) as avg_transit,
      AVG(workplaces_percent_change_from_baseline) as avg_workplace,
      AVG(residential_percent_change_from_baseline)  as avg_residential
      FROM \`bigquery-public-data.covid19_google_mobility.mobility_report\`
      GROUP BY country_region, date
   ) AS t1
WHERE
   CONCAT(t0.country_name, t0.date) = CONCAT(t1.country_region, t1.date)
"
echo "${GREEN}Bonus task completed successfully!${RESET}"
echo

# Additional data quality checks
echo "${CYAN}${BOLD}Running data quality checks...${RESET}"
echo "${YELLOW}Identifying countries with missing data...${RESET}"
bq query --use_legacy_sql=false \
"
SELECT DISTINCT country_name
FROM \`$DATASET_NAME_2.oxford_policy_tracker_worldwide\`
WHERE population is NULL
UNION ALL
SELECT DISTINCT country_name
FROM \`$DATASET_NAME_2.oxford_policy_tracker_worldwide\`
WHERE country_area IS NULL
ORDER BY country_name ASC
"

# Create additional tables for analysis
echo "${YELLOW}Creating country_area_data table...${RESET}"
bq query --use_legacy_sql=false \
"
CREATE TABLE $DATASET_NAME_2.country_area_data AS
SELECT *
FROM \`bigquery-public-data.census_bureau_international.country_names_area\`;
"

echo "${YELLOW}Creating mobility_data table...${RESET}"
bq query --use_legacy_sql=false \
"CREATE TABLE $DATASET_NAME_2.mobility_data AS
SELECT *
FROM \`bigquery-public-data.covid19_google_mobility.mobility_report\`"

# Data cleaning
echo "${YELLOW}Cleaning data by removing NULL values...${RESET}"
bq query --use_legacy_sql=false \
"DELETE FROM covid_data.oxford_policy_tracker_by_countries
WHERE population IS NULL AND country_area IS NULL"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
