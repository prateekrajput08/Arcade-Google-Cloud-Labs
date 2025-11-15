#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
CYAN_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
YELLOW_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Create Spanner instance
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Spanner instance: banking-ops-instance${RESET_FORMAT}"
gcloud spanner instances create banking-ops-instance \
  --config=regional-$REGION \
  --description="TechCode" \
  --nodes=1

# Create database
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating database: banking-ops-db${RESET_FORMAT}"
gcloud spanner databases create banking-ops-db --instance=banking-ops-instance

# Create tables
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating database tables${RESET_FORMAT}"
gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance \
  --ddl="CREATE TABLE Portfolio (
    PortfolioId INT64 NOT NULL,
    Name STRING(MAX),
    ShortName STRING(MAX),
    PortfolioInfo STRING(MAX))
    PRIMARY KEY (PortfolioId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance \
  --ddl="CREATE TABLE Category (
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    CategoryName STRING(MAX),
    PortfolioInfo STRING(MAX))
    PRIMARY KEY (CategoryId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance \
  --ddl="CREATE TABLE Product (
    ProductId INT64 NOT NULL,
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    ProductName STRING(MAX),
    ProductAssetCode STRING(25),
    ProductClass STRING(25))
    PRIMARY KEY (ProductId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance \
  --ddl="CREATE TABLE Customer (
    CustomerId STRING(36) NOT NULL,
    Name STRING(MAX) NOT NULL,
    Location STRING(MAX) NOT NULL)
    PRIMARY KEY (CustomerId)"

# Insert sample data
echo "${YELLOW_TEXT}${BOLD_TEXT}Inserting sample data${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance \
  --sql='INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo)
  VALUES 
    (1, "Banking", "Bnkg", "All Banking Business"),
    (2, "Asset Growth", "AsstGrwth", "All Asset Focused Products"),
    (3, "Insurance", "Insurance", "All Insurance Focused Products")'

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance \
  --sql='INSERT INTO Category (CategoryId, PortfolioId, CategoryName)
  VALUES 
    (1, 1, "Cash"),
    (2, 2, "Investments - Short Return"),
    (3, 2, "Annuities"),
    (4, 3, "Life Insurance")'

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance \
  --sql='INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass)
  VALUES 
    (1, 1, 1, "Checking Account", "ChkAcct", "Banking LOB"),
    (2, 2, 2, "Mutual Fund Consumer Goods", "MFundCG", "Investment LOB"),
    (3, 3, 2, "Annuity Early Retirement", "AnnuFixed", "Investment LOB"),
    (4, 4, 3, "Term Life Insurance", "TermLife", "Insurance LOB"),
    (5, 1, 1, "Savings Account", "SavAcct", "Banking LOB"),
    (6, 1, 1, "Personal Loan", "PersLn", "Banking LOB"),
    (7, 1, 1, "Auto Loan", "AutLn", "Banking LOB"),
    (8, 4, 3, "Permanent Life Insurance", "PermLife", "Insurance LOB"),
    (9, 2, 2, "US Savings Bonds", "USSavBond", "Investment LOB")'

# Download customer data
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading customer data${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Create%20and%20Manage%20Cloud%20Spanner%20Instances%3A%20Challenge%20Lab/Customer_List_500.csv

# Prepare Dataflow
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Dataflow service${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

# Create manifest file
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating import manifest${RESET_FORMAT}"
cat > manifest.json << EOF_CP
{
  "tables": [
    {
      "table_name": "Customer",
      "file_patterns": [
        "gs://$DEVSHELL_PROJECT_ID/Customer_List_500.csv"
      ],
      "columns": [
        {"column_name" : "CustomerId", "type_name" : "STRING" },
        {"column_name" : "Name", "type_name" : "STRING" },
        {"column_name" : "Location", "type_name" : "STRING" }
      ]
    }
  ]
}
EOF_CP

# Prepare GCS bucket
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Cloud Storage bucket${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID

# Create placeholder file
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating placeholder files${RESET_FORMAT}"
touch techcode
gsutil cp techcode gs://$DEVSHELL_PROJECT_ID/tmp/techcode

# Upload files to GCS
echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading files to Cloud Storage${RESET_FORMAT}"
gsutil cp Customer_List_500.csv gs://$DEVSHELL_PROJECT_ID
gsutil cp manifest.json gs://$DEVSHELL_PROJECT_ID

# Wait for operations to complete
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for setup to complete...${RESET_FORMAT}"
sleep 100

# Run Dataflow job
echo "${YELLOW_TEXT}${BOLD_TEXT}Running Dataflow import job${RESET_FORMAT}"
gcloud dataflow jobs run techcode \
  --gcs-location gs://dataflow-templates-"$REGION"/latest/GCS_Text_to_Cloud_Spanner \
  --region="$REGION" \
  --staging-location gs://$DEVSHELL_PROJECT_ID/tmp/ \
  --parameters instanceId=banking-ops-instance,databaseId=banking-ops-db,importManifest=gs://$DEVSHELL_PROJECT_ID/manifest.json

# Update schema
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating database schema${RESET_FORMAT}"
gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance \
  --ddl='ALTER TABLE Category ADD COLUMN MarketingBudget INT64;'


# Final message
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
