Code Requirements & Notes

Dataset Version:
All scripts currently require the ABCD 6.0 data release.

Mapping File:
The code depends on a mapping file (CSV) that specifies which medications belong to which category.

Use the appropriate mapping file for the medication category you want to recreate (e.g., Acid Relief/Heartburn).

This file must include at least RXCUI, Medication_Label, and Estimated_Use_Category_1.

Language:
Code is currently written for R only.

Generated Variables:
For each medication category in the mapping file, the scripts will generate three timeframe indicator variables:

x1yr_ → Past year (available Year 3 onward; not collected in Years 0–2)

x2wk_ → Past two weeks

x24hr_ → Past 24 hours

NA Handling:
All missing values are recoded to 0, meaning they are treated as “did not take medication” in the created variables.


Usage
1. Load the ABCD dataset and required packages
library(dplyr)
library(tidyr)
library(stringr)
library(furrr)
library(purrr)

ABCD_data <- readRDS("ABCD_6.0_dataset.RDS")

2.  Load your medication mapping file
    meds_info <- read.csv("ABCD_Acid_Relief_73025.csv")

3. Run the medication processing pipeline
   source("medication_flags.R")
   # Process the dataset (example for Acid Relief/Heartburn)
   processed_data <- create_med_flags(
   ABCD_data,
   mapping_file = "ABCD_Acid_Relief_73025.csv"
)

4. Resulting Dataset
   Your dataset will now include three new binary variables for each medication category from the mapping file:

   x1yr_acid_relief_heartburn_treatment

   x2wk_acid_relief_heartburn_treatment

   x24hr_acid_relief_heartburn_treatment
