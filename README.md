📌 Code Requirements & Notes

📂 Dataset Version

All scripts require the ABCD 6.0 data release.

📚 Medication Categories

You can explore the medication categories at the following resources:

🔹 Interactive Tableau Dashboard
👉 https://public.tableau.com/views/ABCD_Medications_v1/MedicationDashboard

🔹 Methodology Preprint (medRxiv)
👉 https://www.medrxiv.org/content/10.1101/2025.11.19.25340321v1

🗂️ Mapping File

Each script depends on a mapping file (e.g., ADHD_Medications.xlsx) that determines which medications belong to each category.

Your mapping file must contain at least the following columns:

RXCUI	
Medication_Label
Estimated_Use_Category_1

📄 Data Format

Scripts assume the ABCD dataset is in long format:

One row per participant per visit

All medication survey items exist within that row

💻 Programming Language

All scripts are written in R.

🏷️ Generated Variables

For each category in the medication mapping file, the scripts generate three binary indicator variables:

Variable Prefix	Timeframe	Notes
x1yr_	Past year	Only collected starting in Year 3
x2wk_	Past 2 weeks	Available at all visits
x24hr_	Past 24 hours	Available at all visits

Each variable is coded:

1 → medication from that category was taken

0 → not taken

⚠️ Missing Data

All NA values in generated variables are recoded to 0, meaning “did not take medication.”
