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
# Color Definitions
BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
RESET=$(tput sgr0)
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



# Task 1 - Total confirmed cases
echo "${BOLD}${RED}Task 1. Total confirmed cases${RESET}"
echo -n "${BOLD}${GREEN}Please enter the month (format: MM): ${RESET}"
read input_month
echo -n "${BOLD}${GREEN}Please enter the date (format: DD): ${RESET}"
read input_day

year="2020"
input_date="${year}-${input_month}-${input_day}"

bq query --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_cases_worldwide
 FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
 WHERE date='${input_date}'"

# Task 2 - Worst affected areas
echo "${BOLD}${RED}Task 2. Worst affected areas${RESET}"
echo -n "${BOLD}${GREEN}Please enter the death count threshold: ${RESET}"
read death_threshold

bq query --use_legacy_sql=false \
"WITH deaths_by_states AS (
    SELECT subregion1_name as state, sum(cumulative_deceased) as death_count
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' 
      AND date='${input_date}' 
      AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
)
SELECT count(*) as count_of_states
FROM deaths_by_states
WHERE death_count > ${death_threshold}"

# Task 3 - Identify hotspots
echo "${BOLD}${RED}Task 3. Identify hotspots${RESET}"
echo -n "${BOLD}${GREEN}Please enter the confirmed case threshold: ${RESET}"
read case_threshold

bq query --use_legacy_sql=false \
"SELECT * FROM (
    SELECT subregion1_name as state, sum(cumulative_confirmed) as total_confirmed_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_code='US' AND date='${input_date}' AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
    ORDER BY total_confirmed_cases DESC
)
WHERE total_confirmed_cases > ${case_threshold}"

# Task 4 - Fatality ratio
echo "${BOLD}${RED}Task 4. Fatality ratio${RESET}"
echo -n "${BOLD}${GREEN}Please enter the start date (format: YYYY-MM-DD): ${RESET}"
read start_date
echo -n "${BOLD}${GREEN}Please enter the end date (format: YYYY-MM-DD): ${RESET}"
read end_date

bq query --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_confirmed_cases,
       sum(cumulative_deceased) as total_deaths,
       (sum(cumulative_deceased)/sum(cumulative_confirmed))*100 as case_fatality_ratio
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE country_name='Italy' AND date BETWEEN '${start_date}' AND '${end_date}'"

# Task 5 - Identifying specific day
echo "${BOLD}${RED}Task 5. Identifying specific day${RESET}"
echo -n "${BOLD}${GREEN}Please enter the death threshold: ${RESET}"
read death_threshold

bq query --use_legacy_sql=false \
"SELECT date
 FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
 WHERE country_name='Italy' AND cumulative_deceased > ${death_threshold}
 ORDER BY date ASC
 LIMIT 1"

# Task 6 - Finding days with zero net new cases
echo "${BOLD}${RED}Task 6. Finding days with zero net new cases${RESET}"
echo -n "${BOLD}${GREEN}Please enter the start date (format: YYYY-MM-DD): ${RESET}"
read start_date
echo -n "${BOLD}${GREEN}Please enter the end date (format: YYYY-MM-DD): ${RESET}"
read end_date

bq query --use_legacy_sql=false \
"WITH india_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name ='India' AND date BETWEEN '${start_date}' AND '${end_date}'
    GROUP BY date
    ORDER BY date ASC
), india_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day, cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
    FROM india_cases_by_date
)
SELECT count(*)
FROM india_previous_day_comparison
WHERE net_new_cases = 0"

# Task 7 - Doubling rate
echo "${BOLD}${RED}Task 7. Doubling rate${RESET}"
echo -n "${BOLD}${GREEN}Please enter the percentage increase threshold: ${RESET}"
read percentage_threshold

bq query --use_legacy_sql=false \
"WITH us_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' AND date BETWEEN '2020-03-22' AND '2020-04-20'
    GROUP BY date
    ORDER BY date ASC
), us_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day,
           cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
           (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
    FROM us_cases_by_date
)
SELECT Date, cases AS Confirmed_Cases_On_Day, previous_day AS Confirmed_Cases_Previous_Day, percentage_increase AS Percentage_Increase_In_Cases
FROM us_previous_day_comparison
WHERE percentage_increase > ${percentage_threshold}"

# Task 8 - Recovery rate
echo "${BOLD}${RED}Task 8. Recovery rate${RESET}"
echo -n "${BOLD}${GREEN}Please enter the limit: ${RESET}"
read limit

bq query --use_legacy_sql=false \
"WITH cases_by_country AS (
  SELECT
    country_name AS country,
    sum(cumulative_confirmed) AS cases,
    sum(cumulative_recovered) AS recovered_cases
  FROM
    bigquery-public-data.covid19_open_data.covid19_open_data
  WHERE
    date = '2020-05-10'
  GROUP BY
    country_name
), recovered_rate AS
(SELECT
  country, cases, recovered_cases,
  (recovered_cases * 100)/cases AS recovery_rate
FROM cases_by_country
)
SELECT country, cases AS confirmed_cases, recovered_cases, recovery_rate
FROM recovered_rate
WHERE cases > 50000
ORDER BY recovery_rate DESC
LIMIT ${limit}"

# Task 9 - CDGR - Cumulative daily growth rate
echo "${BOLD}${RED}Task 9. CDGR - Cumulative daily growth rate${RESET}"
echo -n "${BOLD}${GREEN}Please enter the second date (format: YYYY-MM-DD): ${RESET}"
read second_date

bq query --use_legacy_sql=false \
"WITH france_cases AS (
    SELECT date, SUM(cumulative_confirmed) AS total_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='France' AND date IN ('2020-01-24', '${second_date}')
    GROUP BY date
    ORDER BY date
), summary AS (
    SELECT total_cases AS first_day_cases, LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
           DATE_DIFF(LEAD(date) OVER(ORDER BY date), date, day) AS days_diff
    FROM france_cases
    LIMIT 1
)
SELECT first_day_cases, last_day_cases, days_diff,
       POWER((last_day_cases/first_day_cases),(1/days_diff))-1 AS cdgr
FROM summary"

# Task 10 - Create a Looker Studio report
echo
echo "${BOLD}${RED}Task 10. Create a Looker Studio report${RESET}"
echo -n "${BOLD}${GREEN}Please enter the start date (format: YYYY-MM-DD): ${RESET}"
read start_date
echo -n "${BOLD}${GREEN}Please enter the end date (format: YYYY-MM-DD): ${RESET}"
read end_date

bq query --use_legacy_sql=false \
"SELECT date, SUM(cumulative_confirmed) AS country_cases,
       SUM(cumulative_deceased) AS country_deaths
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE date BETWEEN '${start_date}' AND '${end_date}'
  AND country_name='United States of America'
GROUP BY date
ORDER BY date"


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
