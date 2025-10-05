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


# Function to display progress spinner
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

clear


# Get user inputs
echo "${YELLOW_TEXT}Please provide the following configuration parameters:${RESET_FORMAT}"
read -p "${YELLOW_TEXT}Enter TABLE_NAME: ${RESET_FORMAT}" TABLE_NAME
read -p "${YELLOW_TEXT}Enter FARE_AMOUNT_NAME: ${RESET_FORMAT}" FARE_AMOUNT_NAME
read -p "${YELLOW_TEXT}Enter TRIP_DISTANCE_NO: ${RESET_FORMAT}" TRIP_DISTANCE_NO
read -p "${YELLOW_TEXT}Enter FARE_AMOUNT: ${RESET_FORMAT}" FARE_AMOUNT
read -p "${YELLOW_TEXT}Enter PASSENGER_COUNT: ${RESET_FORMAT}" PASSENGER_COUNT
read -p "${YELLOW_TEXT}Enter MODEL_NAME: ${RESET_FORMAT}" MODEL_NAME

# Display configuration summary
echo
echo "${MAGENTA_TEXT}Configuration Summary ${RESET_FORMAT}"
echo "${WHITE_TEXT}TABLE_NAME: ${RESET_FORMAT}${CYAN_TEXT}$TABLE_NAME${RESET_FORMAT}"
echo "${WHITE_TEXT}FARE_AMOUNT_NAME: ${RESET_FORMAT}${CYAN_TEXT}$FARE_AMOUNT_NAME${RESET_FORMAT}"
echo "${WHITE_TEXT}TRIP_DISTANCE_NO: ${RESET_FORMAT}${CYAN_TEXT}$TRIP_DISTANCE_NO${RESET_FORMAT}"
echo "${WHITE_TEXT}FARE_AMOUNT: ${RESET_FORMAT}${CYAN_TEXT}$FARE_AMOUNT${RESET_FORMAT}"
echo "${WHITE_TEXT}PASSENGER_COUNT: ${RESET_FORMAT}${CYAN_TEXT}$PASSENGER_COUNT${RESET_FORMAT}"
echo "${WHITE_TEXT}MODEL_NAME: ${RESET_FORMAT}${CYAN_TEXT}$MODEL_NAME${RESET_FORMAT}"
echo

# Task 1: Data Cleaning & Preparation
section_header "TASK 1: DATA PREPARATION"
echo "${GREEN_TEXT}Cleaning and preparing taxi ride data...${RESET_FORMAT}"
(bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE
  taxirides.$TABLE_NAME AS
SELECT
  (tolls_amount + fare_amount) AS $FARE_AMOUNT_NAME,
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
FROM
  taxirides.historical_taxi_rides_raw
WHERE
  RAND() < 0.001
  AND trip_distance > $TRIP_DISTANCE_NO
  AND fare_amount >= $FARE_AMOUNT
  AND pickup_longitude > -78
  AND pickup_longitude < -70
  AND dropoff_longitude > -78
  AND dropoff_longitude < -70
  AND pickup_latitude > 37
  AND pickup_latitude < 45
  AND dropoff_latitude > 37
  AND dropoff_latitude < 45
  AND passenger_count > $PASSENGER_COUNT
" > /dev/null 2>&1) & spinner

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}Task 1: Data preparation completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}Task 1: Data preparation failed${RESET_FORMAT}"
    exit 1
fi

# Task 2: ML Model Creation & Training
section_header "TASK 2: MODEL TRAINING"
echo "${BLUE_TEXT}Creating and training ML model ($MODEL_NAME)...${RESET_FORMAT}"
(bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL taxirides.$MODEL_NAME
TRANSFORM(
  * EXCEPT(pickup_datetime)

  , ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
  , CAST(EXTRACT(DAYOFWEEK FROM pickup_datetime) AS STRING) AS dayofweek
  , CAST(EXTRACT(HOUR FROM pickup_datetime) AS STRING) AS hourofday
)
OPTIONS(input_label_cols=['$FARE_AMOUNT_NAME'], model_type='linear_reg')
AS

SELECT * FROM taxirides.$TABLE_NAME
" > /dev/null 2>&1) & spinner

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}Task 2: Model training completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}Task 2: Model training failed${RESET_FORMAT}"
    exit 1
fi

# Task 3: Batch Prediction Generation
section_header "TASK 3: PREDICTION GENERATION"
echo "${MAGENTA_TEXT}Generating batch predictions...${RESET_FORMAT}"
(bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE taxirides.2015_fare_amount_predictions
  AS
SELECT * FROM ML.PREDICT(MODEL taxirides.$MODEL_NAME,(
  SELECT * FROM taxirides.report_prediction_data)
)
" > /dev/null 2>&1) & spinner

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}Task 3: Prediction generation completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}Task 3: Prediction generation failed${RESET_FORMAT}"
    exit 1
fi



#-----------------------------------------------------end----------------------------------------------------------#
# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT_FORMAT}"
echo
