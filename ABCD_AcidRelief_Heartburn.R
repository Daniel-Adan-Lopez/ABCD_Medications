
library(dplyr)
library(stringr)
library(furrr)
library(purrr)
library(tidyr)
library(readxl)

# -------------------------------------------------
#  1. Load Data & Medication Mapping
# -------------------------------------------------
#identifying and subsetting only the medication variables. Taking both the RX
#and the OTC variables. 
ABCD_meds_subset <- ABCD_6_0_full %>%  #subsetting is not really essential, just to make it easier to work with the data
  select(
    participant_id,
    session_id,
    matches("^ph_p_meds__rx__id_"),      # RX IDs
    matches("^ph_p_meds__rx__label_"),   # RX Labels
    matches("^ph_p_meds__otc__id_"),     # OTC IDs
    matches("^ph_p_meds__otc__label_"),   # OTC Labels
    matches("^ph_p_meds__rx_"),
    matches("^ph_p_meds__otc_")
  )


str(ABCD_meds_subset)
#'data.frame':	68190 obs. of  378 variables:

med_data <- ABCD_meds_subset   #could just be your ABCD dataframe. Just requires the OTC and RX variables.
meds_info <- read.csv("C:/Users/indoo/Downloads/ABCD_Acid_Relief_73025.csv") #downloaded off Github


# RXCUIs where label matching is unreliable
#There were errors on these. Not really important since we are relying on the RXCUI
#column mostly rather than the med label column, but keeping it in just in case. 
force_rx_only <- c("1150360", "1159901", "1440934", "393497", "55062", "6142", "702425")


# -------------------------------------------------
#  2. Define Columns & Early Visits
# -------------------------------------------------
#early and late is used to differentiate between time frames collected at every visit (past 24 hrs,
#past 2 weeks), and those collected only at year 3 onwards (past year use).
#will be important when creating the different time frame variants for each medication category.

rx_cols_early        <- paste0("ph_p_meds__rx__id_", str_pad(1:15, 3, pad = "0"))
rx_label_cols_early  <- paste0("ph_p_meds__rx__label_", str_pad(1:15, 3, pad = "0"))
rx_cols_late         <- paste0("ph_p_meds__rx__id_", str_pad(1:15, 3, pad = "0"), "__v01")
rx_label_cols_late   <- paste0("ph_p_meds__rx__label_", str_pad(1:15, 3, pad = "0"), "__v01")
rx_confirm_late      <- paste0("ph_p_meds__rx_", str_pad(1:15, 3, pad = "0"), "__01")

otc_cols_early       <- paste0("ph_p_meds__otc__id_", str_pad(1:15, 3, pad = "0"))
otc_label_cols_early <- paste0("ph_p_meds__otc__label_", str_pad(1:15, 3, pad = "0"))
otc_cols_late        <- paste0("ph_p_meds__otc__id_", str_pad(1:15, 3, pad = "0"), "__v01")
otc_label_cols_late  <- paste0("ph_p_meds__otc__label_", str_pad(1:15, 3, pad = "0"), "__v01")

early_sessions <- c("ses-00A", "ses-01A", "ses-02A") #session_id variable

med_data <- med_data %>%
  mutate(is_early_visit = session_id %in% early_sessions)

# -------------------------------------------------
# 3. Process Rows for Past 2 Week Flags 
# -------------------------------------------------

row_list <- med_data %>%
  select(participant_id, session_id, is_early_visit,
         all_of(c(rx_cols_early, rx_label_cols_early,
                  rx_cols_late, rx_label_cols_late, rx_confirm_late,
                  otc_cols_early, otc_label_cols_early,
                  otc_cols_late, otc_label_cols_late))) %>%
  split(., seq_len(nrow(.)))

process_row <- function(row) {
  is_early <- row$is_early_visit
  
  rx_ids <- if (is_early) {
    unlist(row[rx_cols_early])
  } else {
    confirms <- unlist(row[rx_confirm_late])
    ids <- unlist(row[rx_cols_late])
    ids[!(confirms == 1)] <- NA
    ids
  }
  
  rx_labels <- if (is_early) {
    unlist(row[rx_label_cols_early])
  } else {
    confirms <- unlist(row[rx_confirm_late])
    labels <- unlist(row[rx_label_cols_late])
    labels[!(confirms == 1)] <- NA
    labels
  }
  
  otc_ids <- if (is_early) {
    unlist(row[otc_cols_early])
  } else {
    unlist(row[otc_cols_late])
  }
  
  otc_labels <- if (is_early) {
    unlist(row[otc_label_cols_early])
  } else {
    unlist(row[otc_label_cols_late])
  }
  
  list(
    rx_ids_all = rx_ids,
    rx_labels_all = rx_labels,
    otc_ids_all = otc_ids,
    otc_labels_all = otc_labels
  )
}

# Parallelize for speed. Very helpful when doing multiple medication categories at once. 
future::plan(multisession, workers = parallel::detectCores() - 1)
med_lists <- furrr::future_map(row_list, process_row, .progress = TRUE)

# Attach list-columns back
med_data <- med_data %>%
  bind_cols(
    tibble::tibble(
      rx_ids_all     = map(med_lists, "rx_ids_all"),
      rx_labels_all  = map(med_lists, "rx_labels_all"),
      otc_ids_all    = map(med_lists, "otc_ids_all"),
      otc_labels_all = map(med_lists, "otc_labels_all")
    )
  )

# Helper to clean names
clean_colname <- function(category, prefix = "") {
  category %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("_+", "_") %>%
    str_replace_all("^_|_$", "") %>%
    paste0(prefix, .)
}

all_categories <- na.omit(unique(meds_info$Estimated_Use_Category_1))

# Loop over categories for x2wk
for (cat in all_categories) {
  col_name <- clean_colname(cat, prefix = "x2wk_")
  cat_meds <- meds_info %>% filter(Estimated_Use_Category_1 == cat)
  
  rx_ids   <- unique(as.character(cat_meds$RXCUI))
  labels   <- unique(as.character(cat_meds$Medication_Label))
  restrict_to_rx <- any(rx_ids %in% force_rx_only)
  
  med_data[[col_name]] <- mapply(function(rx_list, rx_labels, otc_list, otc_labels) {
    match_rx        <- any(rx_ids %in% rx_list, na.rm = TRUE)
    match_label     <- if (!restrict_to_rx) any(labels %in% rx_labels, na.rm = TRUE) else FALSE
    match_otc       <- any(rx_ids %in% otc_list, na.rm = TRUE)
    match_otc_label <- if (!restrict_to_rx) any(labels %in% otc_labels, na.rm = TRUE) else FALSE
    as.integer(match_rx | match_label | match_otc | match_otc_label)
  },
  med_data$rx_ids_all,
  med_data$rx_labels_all,
  med_data$otc_ids_all,
  med_data$otc_labels_all,
  SIMPLIFY = TRUE, USE.NAMES = FALSE)
}

# -------------------------------------------------
# 4. Past 24-Hour Flags (x24hr)
# -------------------------------------------------

# Function to extract 24hr info (RX and OTC)
extract_med_info <- function(data, type = c("rx", "otc")) {
  type <- match.arg(type)
  
  # Get BOTH early and late label columns
  label_cols_early <- grep(paste0("ph_p_meds__", type, "__label_\\d+$"), names(data), value = TRUE)
  label_cols_late  <- grep(paste0("ph_p_meds__", type, "__label_\\d+__v01$"), names(data), value = TRUE)
  
  all_label_cols <- c(label_cols_early, label_cols_late)
  index_nums <- str_extract(all_label_cols, "\\d+")
  
  # Build corresponding ID columns (with or without __v01)
  id_cols <- ifelse(
    grepl("__v01$", all_label_cols),
    paste0("ph_p_meds__", type, "__id_", index_nums, "__v01"),
    paste0("ph_p_meds__", type, "__id_", index_nums)
  )
  
  # 24‑hour flag columns never change (no __v01 suffix)
  taken_cols <- paste0("ph_p_meds__", type, "_", index_nums, "__01__06")
  
  bind_rows(lapply(seq_along(all_label_cols), function(i) {
    data %>%
      select(
        participant_id, session_id,
        label      = all_of(all_label_cols[i]),
        rxcui      = all_of(id_cols[i]),
        taken_24hr = all_of(taken_cols[i])
      ) %>%
      mutate(index = index_nums[i], type = type)
  }))
}

rx_data_long <- extract_med_info(med_data, "rx")
otc_data_long <- extract_med_info(med_data, "otc")

# Merge RX + OTC for 24hr
all_data_long <- bind_rows(rx_data_long, otc_data_long) %>%
  mutate(
    label = str_trim(tolower(label)),
    rxcui = as.character(rxcui),
    # ✅ Handles BOTH numeric 1/0 and text "Yes"/"No"
    taken_24hr = ifelse(taken_24hr %in% c(1, "1", "yes", "Yes"), 1, 0)
  )


# Clean mapping for 24hr merge
med_labels_clean <- meds_info %>%
  mutate(Medication_Label = str_trim(tolower(Medication_Label)),
         RXCUI = as.character(RXCUI))

joined_data <- all_data_long %>%
  left_join(med_labels_clean, by = c("label" = "Medication_Label")) %>%
  mutate(Estimated_Use_Category_1 = ifelse(is.na(Estimated_Use_Category_1),
                                           med_labels_clean$Estimated_Use_Category_1[match(rxcui, med_labels_clean$RXCUI)],
                                           Estimated_Use_Category_1)) %>%
  filter(!is.na(Estimated_Use_Category_1))

# Complete grid to fill 0s
all_ids <- med_data %>% distinct(participant_id, session_id)
all_cats <- med_labels_clean %>% distinct(Estimated_Use_Category_1)
full_grid <- tidyr::crossing(all_ids, all_cats)

# Make wide x24hr table
med_24hr_wide <- full_grid %>%
  left_join(
    joined_data %>%
      group_by(participant_id, session_id, Estimated_Use_Category_1) %>%
      summarize(took_24hr = as.integer(any(taken_24hr == 1)), .groups = "drop"),
    by = c("participant_id", "session_id", "Estimated_Use_Category_1")
  ) %>%
  mutate(took_24hr = replace_na(took_24hr, 0),
         category_24hr = paste0("x24hr_", clean_colname(Estimated_Use_Category_1))) %>%
  select(participant_id, session_id, category_24hr, took_24hr) %>%
  pivot_wider(names_from = category_24hr, values_from = took_24hr, values_fill = 0)

# Attach x24hr columns
med_data <- med_data %>%
  left_join(med_24hr_wide, by = c("participant_id", "session_id"))

# -------------------------------------------------
# 5. Past Year Flags (x1yr)
# -------------------------------------------------

extract_past_year_info <- function(data, type = c("rx", "otc")) {
  type <- match.arg(type)
  label_cols <- grep(paste0("ph_p_meds__", type, "__label_\\d+__v01"), names(data), value = TRUE)
  index_nums <- str_extract(label_cols, "\\d+")
  id_cols <- paste0("ph_p_meds__", type, "__id_", index_nums, "__v01")
  
  bind_rows(lapply(seq_along(label_cols), function(i) {
    data %>%
      select(participant_id, session_id,
             label = all_of(label_cols[i]),
             rxcui = all_of(id_cols[i])) %>%
      mutate(index = index_nums[i], type = type)
  }))
}

rx_year_data <- extract_past_year_info(med_data, "rx")
otc_year_data <- extract_past_year_info(med_data, "otc")

# Combine RX + OTC for 1yr
all_year_data <- bind_rows(rx_year_data, otc_year_data) %>%
  mutate(label = str_trim(tolower(label)),
         rxcui = as.character(rxcui))

joined_year_data <- all_year_data %>%
  left_join(meds_info, by = c("label" = "Medication_Label")) %>%
  mutate(
    Estimated_Use_Category_1 = ifelse(
      is.na(Estimated_Use_Category_1),
      meds_info$Estimated_Use_Category_1[match(rxcui, meds_info$RXCUI)],
      Estimated_Use_Category_1
    )
  ) %>%
  filter(!is.na(Estimated_Use_Category_1))

# Build wide x1yr table
full_grid <- tidyr::crossing(all_ids, all_cats)

med_1yr_wide <- full_grid %>%
  left_join(
    joined_year_data %>%
      group_by(participant_id, session_id, Estimated_Use_Category_1) %>%
      summarize(took_1yr = 1, .groups = "drop"),
    by = c("participant_id", "session_id", "Estimated_Use_Category_1")
  ) %>%
  mutate(
    took_1yr = replace_na(took_1yr, 0),
    category_1yr = paste0("x1yr_", clean_colname(Estimated_Use_Category_1))
  ) %>%
  select(participant_id, session_id, category_1yr, took_1yr) %>%
  pivot_wider(names_from = category_1yr, values_from = took_1yr, values_fill = 0)

# Attach x1yr columns
med_data <- med_data %>%
  left_join(med_1yr_wide, by = c("participant_id", "session_id"))

# -------------------------------------------------
# 6. QC Check
# -------------------------------------------------
#past 24 hour use
table(med_data$session_id, med_data$x24hr_acid_relief_heartburn_treatment, useNA = "always")
0     1  <NA>
  ses-00A 11791    77     0
ses-01A 11154    65     0
ses-02A 10903    70     0
ses-03A 10405    45     0
ses-04A  9663    76     0
ses-05A  8819    66     0
ses-06A  5022    34     0

#past 2 week use
table(med_data$session_id, med_data$x2wk_acid_relief_heartburn_treatment, useNA = "always")
0     1  <NA>
  ses-00A 11751   117     0
ses-01A 11123    96     0
ses-02A 10859   114     0
ses-03A 10305   145     0
ses-04A  9588   151     0
ses-05A  8756   129     0
ses-06A  4963    93     0

#past year use. Only collected at year 3 onward. 
table(med_data$session_id, med_data$x1yr_acid_relief_heartburn_treatment, useNA = "always")
0     1  <NA>
  ses-00A 11868     0     0
ses-01A 11219     0     0
ses-02A 10973     0     0
ses-03A 10277   173     0
ses-04A  9569   170     0
ses-05A  8731   154     0
ses-06A  4947   109     0