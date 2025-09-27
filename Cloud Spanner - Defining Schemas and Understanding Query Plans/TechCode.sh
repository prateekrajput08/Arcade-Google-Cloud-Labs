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

declare -A PORTFOLIOS=(
    [1]="Banking,Bnkg,All Banking Business"
    [2]="Asset Growth,AsstGrwth,All Asset Focused Products"
    [3]="Insurance,Ins,All Insurance Focused Products"
)

for id in "${!PORTFOLIOS[@]}"; do
    IFS=',' read -r name short info <<< "${PORTFOLIOS[$id]}"
    echo "Creating portfolio: $name"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES ($id, '$name', '$short', '$info')"
done
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo ""


declare -A CATEGORIES=(
    [1]="1,Cash"
    [2]="2,Investments - Short Return"
    [3]="2,Annuities"
    [4]="3,Life Insurance"
)

for id in "${!CATEGORIES[@]}"; do
    IFS=',' read -r portfolio_id name <<< "${CATEGORIES[$id]}"
    echo "${WHITE}Creating category: ${YELLOW}$name${RESET}"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES ($id, $portfolio_id, '$name')"
done
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo ""


declare -A PRODUCTS=(
    [1]="1,1,Checking Account,ChkAcct,Banking LOB"
    [2]="2,2,Mutual Fund Consumer Goods,MFundCG,Investment LOB"
    [3]="3,2,Annuity Early Retirement,AnnuFixed,Investment LOB"
    [4]="4,3,Term Life Insurance,TermLife,Insurance LOB"
    [5]="1,1,Savings Account,SavAcct,Banking LOB"
    [6]="1,1,Personal Loan,PersLn,Banking LOB"
    [7]="1,1,Auto Loan,AutLn,Banking LOB"
    [8]="4,3,Permanent Life Insurance,PermLife,Insurance LOB"
    [9]="2,2,US Savings Bonds,USSavBond,Investment LOB"
)

for id in "${!PRODUCTS[@]}"; do
    IFS=',' read -r category_id portfolio_id name code class <<< "${PRODUCTS[$id]}"
    echo "${WHITE}Adding product: ${YELLOW}$name${RESET}"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES ($id, $category_id, $portfolio_id, '$name', '$code', '$class')"
done
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo ""


mkdir -p python-helper && cd python-helper || {
    echo "${RED}${BOLD} Failed to create python-helper directory${RESET}"
    exit 1
}

wget -q https://storage.googleapis.com/cloud-training/OCBL373/requirements.txt
wget -q https://storage.googleapis.com/cloud-training/OCBL373/snippets.py

pip install -q -r requirements.txt
pip install -q setuptools

echo "${WHITE}Executing database operations...${RESET}"
declare -a PYTHON_COMMANDS=(
    "insert_data"
    "query_data"
    "add_column"
    "update_data"
    "query_data_with_new_column"
    "add_index"
)

for command in "${PYTHON_COMMANDS[@]}"; do
    echo "${WHITE}Running: ${YELLOW}$command${RESET}"
    python snippets.py banking-ops-instance --database-id banking-ops-db $command
done

echo ""


# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo
