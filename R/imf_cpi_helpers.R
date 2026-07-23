# shared IMF/CPI (DBnomics) fetch + tidy helpers
# sourced by pull_imf_cpi.R, pull_imf_cpi_all.R, group_cpi_divergence.R
suppressPackageStartupMessages({library(tidyverse); library(jsonlite); library(here)})

HERE <- here::here()   # repo root (via .here sentinel or .git)

# PNG (docx embeds this) + TIFF (LZW 300 dpi, what the publisher wants)
save_fig <- function(plot, stem, width, height, dpi = 150) {
  png_dir  <- file.path(HERE, "plots", "png")
  tiff_dir <- file.path(HERE, "plots", "tiff")
  dir.create(png_dir,  showWarnings = FALSE, recursive = TRUE)
  dir.create(tiff_dir, showWarnings = FALSE, recursive = TRUE)
  ggsave(file.path(png_dir,  paste0(stem, ".png")), plot,
         width = width, height = height, dpi = dpi)
  ggsave(file.path(tiff_dir, paste0(stem, ".tif")), plot,
         width = width, height = height, dpi = 300, device = "tiff", compression = "lzw")
  invisible(stem)
}

# COICOP-1999 divisions + all-items <-> IMF indicator stems
DIVISIONS <- tribble(
  ~stem,     ~coicop, ~division,
  "PCPI",    "00",    "All items",
  "PCPIF",   "01",    "Food & non-alcoholic beverages",
  "PCPIFBT", "02",    "Alcohol, tobacco & narcotics",
  "PCPIA",   "03",    "Clothing & footwear",
  "PCPIH",   "04",    "Housing, water, electricity, gas & fuels",
  "PCPIHO",  "05",    "Furnishings & household equipment",
  "PCPIM",   "06",    "Health",
  "PCPIT",   "07",    "Transport",
  "PCPIEC",  "08",    "Communication",
  "PCPIR",   "09",    "Recreation & culture",
  "PCPIED",  "10",    "Education",
  "PCPIRE",  "11",    "Restaurants & hotels",
  "PCPIO",   "12",    "Miscellaneous goods & services"
)

MEASURES <- tribble(
  ~suffix,       ~measure,
  "_IX",         "index",
  "_PC_CP_A_PT", "yoy_pct",
  "_PC_PP_PT",   "mom_pct",
  "_WT_PT",      "weight_pct"
)

# all IMF/CPI reference areas (codes + names), from the DBnomics dataset metadata
imf_cpi_countries <- function() {
  url <- "https://api.db.nomics.world/v22/datasets/IMF/CPI"
  js  <- jsonlite::fromJSON(url, simplifyVector = FALSE)
  ref <- js$datasets$docs[[1]]$dimensions_values_labels$REF_AREA
  tibble(code = names(ref), name = unlist(ref))
}

# fetch one country's monthly series (all indicators), tidy long, NA-safe
fetch_country <- function(cc, freq = "M") {
  base <- "https://api.db.nomics.world/v22/series/IMF/CPI"
  dims <- URLencode(sprintf('{"FREQ":["%s"],"REF_AREA":["%s"]}', freq, cc), reserved = TRUE)
  url  <- sprintf("%s?dimensions=%s&observations=1&limit=1000", base, dims)
  js   <- tryCatch(jsonlite::fromJSON(url, simplifyVector = FALSE),
                   error = function(e) { message("  ! fetch failed ", cc, ": ", conditionMessage(e)); NULL })
  if (is.null(js)) return(tibble())
  docs <- js$series$docs
  if (!length(docs)) return(tibble())
  map_dfr(docs, function(d) {
    tibble(country   = d$dimensions$REF_AREA %||% cc,
           indicator = d$dimensions$INDICATOR,
           period    = unlist(d$period),
           value     = map_dbl(d$value, ~ if (is.null(.x) || identical(.x, "NA")) NA_real_ else as.numeric(.x)))
  })
}

split_indicator <- function(ind) {
  for (i in seq_len(nrow(MEASURES))) {
    suf <- MEASURES$suffix[i]
    if (endsWith(ind, suf))
      return(tibble(stem = substr(ind, 1, nchar(ind) - nchar(suf)), measure = MEASURES$measure[i]))
  }
  tibble(stem = ind, measure = NA_character_)
}

# raw (country, indicator, period, value) -> tidy long with coicop/division/measure
tidy_cpi <- function(raw) {
  if (!nrow(raw)) return(tibble())
  parsed <-
    raw |>
    distinct(indicator) |>
    mutate(parts = map(indicator, split_indicator)) |>
    unnest(parts)
  raw |>
    left_join(parsed, by = "indicator") |>
    inner_join(DIVISIONS, by = "stem") |>
    filter(!is.na(measure)) |>
    transmute(country, coicop, division, measure, period, date = ym(period), value) |>
    arrange(country, coicop, measure, date)
}

# hand-set income-group baskets (low ~60% food, high ~25% + services), each
# normalised to sum to 1 per group. the un-normalised version was the original bug.
GROUP_WEIGHTS <- tribble(
  ~coicop, ~low,   ~mid,   ~high,
  "01",    0.594,  0.429,  0.250,
  "02",    0.020,  0.029,  0.020,
  "03",    0.079,  0.076,  0.080,
  "04",    0.178,  0.143,  0.100,
  "05",    0.030,  0.048,  0.060,
  "06",    0.040,  0.057,  0.100,
  "07",    0.030,  0.114,  0.180,
  "08",    0.010,  0.019,  0.030,
  "09",    0.005,  0.029,  0.080,
  "10",    0.005,  0.010,  0.030,
  "11",    0.000,  0.010,  0.030,
  "12",    0.010,  0.038,  0.040
) |>
  mutate(across(c(low, mid, high), ~ .x / sum(.x)))   # enforce sum(w) = 1
