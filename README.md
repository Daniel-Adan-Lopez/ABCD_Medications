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

To reproduce the medication category definitions used in the Tableau dashboard, users should rely on the following two files in this repository:

ABCD_Medication_Mapping_Github.xlsx

Mapping_2wk_Med_Use

These files contain the full medication mapping logic and category assignments used to generate the dashboard-level summaries, including harmonized medication groupings derived from ABCD medication variables. 

Users attempting to reproduce, extend, or audit the Tableau dashboard should use these files as the primary reference for medication classification.

If you have any questions, concerns, or encounter issues when using these files, please feel free to reach out to lopdanie@ohsu.edu
.

If you use this mapping framework in your work, please cite the following preprint:

Lopez, D. A., et al. [Title]. medRxiv (2025).
https://www.medrxiv.org/content/10.1101/2025.11.19.25340321v1

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
