📌 **Code Requirements & Notes**

📂 **Dataset Version**  
All scripts currently require the **ABCD 6.0** data release.

📂 **What are the Medication Categories**
Distribution of medication categories can be found here: https://public.tableau.com/views/ABCD_Medications_v1/MedicationDashboard
And https://www.medrxiv.org/content/10.1101/2025.11.19.25340321v1

🗂️ **Mapping File**  
The code depends on a mapping file (e.g., ADHD_Medications.xlsx) that specifies which medications belong to each category.  

Use the appropriate mapping file for the medication category you want to recreate (e.g., *Any ADHD Medication*).  

The mapping file **must include at least** the following columns:  
1️⃣ **RXCUI**  
2️⃣ **Medication_Label**  
3️⃣ **Estimated_Use_Category_1**

📄 **Data Format Assumption**  
The scripts assume the ABCD data is in **long format** — meaning **one row per participant per visit** they attended.

💻 **Language**  
Code is currently written for **R** only.

🏷️ **Generated Variables**  
For each medication category in the mapping file, the scripts will create **three timeframe indicator variables**:

- `x1yr_` → Past year *(available starting Year 3 onward; not collected in Years 0–2)*  
- `x2wk_` → Past two weeks  
- `x24hr_` → Past 24 hours  

⚠️ **NA Handling**  
All **NA values** are recoded to **0**, meaning they are treated as **“did not take medication”** in the created variables.
