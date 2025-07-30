📌 Code Requirements & Notes

📂 Dataset Version
All scripts currently require the ABCD 6.0 data release.

🗂️ Mapping File
The code depends on a mapping file (CSV) that specifies which medications belong to each category.

Use the appropriate mapping file for the medication category you want to recreate (e.g., Acid Relief/Heartburn).

The mapping file must include at least the following columns:

RXCUI

Medication_Label

Estimated_Use_Category_1

💻 Language
Code is currently written for R only.

🏷️ Generated Variables
For each medication category in the mapping file, the scripts will create three timeframe indicator variables:

x1yr_ → Past year (available starting Year 3 onward; not collected in Years 0–2)

x2wk_ → Past two weeks

x24hr_ → Past 24 hours

⚠️ NA Handling
All NA values are recoded to 0, meaning they are treated as “did not take medication” in the created variables.
