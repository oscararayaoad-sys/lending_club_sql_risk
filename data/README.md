# Data

The LendingClub dataset **is not included** in this repository due to its large size (several hundred megabytes, which exceeds GitHub's file size limit).

## How to Get the Dataset

1. Download the **"Lending Club Loan Data"** dataset from [Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club).
2. Use the accepted loans file (`accepted_*.csv`).
3. Place it inside this folder (`data/`).
4. Run the notebook `01_data_cleaning.ipynb` from the project's root directory to generate the cleaned CSV file (`lending_club_limpio.csv`).

## About the Dataset

- **Raw:** ~2.26 million rows, 100+ columns (2007–2018).
- **Cleaned (used in this project):** 1,230,327 completed loans, 15 columns + the `default` target variable.

The complete data cleaning process, along with its business and technical justifications, is thoroughly documented in `01_data_cleaning.ipynb`.