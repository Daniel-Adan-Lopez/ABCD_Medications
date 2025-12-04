📌 Code Requirements & Notes

📂 Dataset Version
All scripts require the ABCD 6.0 data release.

📂 Medication Categories
Information about the medication categories is available here:

Interactive dashboard: https://public.tableau.com/views/ABCD_Medications_v1/MedicationDashboard

Methodology preprint: https://www.medrxiv.org/content/10.1101/2025.11.19.25340321v1

🗂️ Mapping File
The code depends on a category-specific mapping file (e.g., ADHD_Medications.xlsx) that identifies all medications belonging to a given category.

Your mapping file must include at least the following columns:
1️⃣ RXCUI
2️⃣ Medication_Label
3️⃣ Estimated_Use_Category_1

📄 Data Format Assumption
The scripts assume the ABCD data is in long format, where each participant has one row per visit.

💻 Language
All scripts are written in R.

🏷️ Generated Variables
For each medication category in the mapping file, the scripts generate three indicator variables, one for each timeframe:

x1yr_ → Past year
(Only available starting in Year 3; not collected at baseline, Year 1, or Year 2)

x2wk_ → Past two weeks

x24hr_ → Past 24 hours

⚠️ Missing Data Handling
All NA values are recoded to 0, meaning they are treated as “did not take medication.”
