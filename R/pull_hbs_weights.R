#!/usr/bin/env Rscript
# citable income-group consumption baskets (weights) from Eurostat HBS
# table hbs_str_t223, 2020 wave, per-mille of total expenditure, COICOP-native.
# covers 34 countries: EU27 + NO, UK + enlargement (ME, MK, RS, TR, XK).
# low = QU1 (bottom quintile), mid = QU3, high = QU5; each normalised to sum to 1.
# usage:  Rscript R/pull_hbs_weights.R [YEAR]        # default 2020
# output: data/hbs_weights_by_country.csv  (per-country low/mid/high)
#         data/hbs_weights.csv             (EU27 reference basket)
source(here::here("R", "imf_cpi_helpers.R"))

args <- commandArgs(trailingOnly = TRUE)
yr   <- ifelse(length(args) >= 1, args[1], "2020")

divs <- sprintf("CP%02d", 1:12)
qmap <- c(low = "QU1", mid = "QU3", high = "QU5")
qp   <- paste0("&coicop=", divs, collapse = "")
qq   <- paste0("&quant_inc=", unname(qmap), collapse = "")
url  <- sprintf(paste0("https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
                       "hbs_str_t223?format=JSON&lang=EN&unit=PM&time=%s%s%s"), yr, qp, qq)
js   <- jsonlite::fromJSON(url, simplifyVector = FALSE)

# JSON-stat decode (row-major; last dim varies fastest)
ids <- unlist(js$id); sizes <- unlist(js$size)
stride <- rev(cumprod(rev(c(sizes[-1], 1)))); names(stride) <- ids
pos <- function(dim, code) js$dimension[[dim]]$category$index[[code]]
val <- js$value
getcell <- function(codes) {
  lin <- sum(map_dbl(ids, ~ pos(.x, codes[[.x]]) * stride[[.x]]))
  v <- val[[as.character(lin)]]; if (is.null(v)) NA_real_ else as.numeric(v)
}

# individual countries only (drop EU/EA aggregates), keep EU27 as a reference row
geos <- names(js$dimension$geo$category$index)
geos <- geos[!str_detect(geos, "^(EU|EA)")]
geos <- c("EU27_2020", geos)
# Eurostat geo code -> ISO2 used by IMF/DBnomics
iso2 <- function(g) recode(g, EL = "GR", UK = "GB", XK = "XK", EU27_2020 = "EU27", .default = g)

grid <-
  expand_grid(geo = geos, grp = names(qmap), coicop = divs)
raw <-
  grid |>
  mutate(permille = pmap_dbl(list(geo, grp, coicop), function(g, gr, cp)
    getcell(c(freq = "A", quant_inc = qmap[[gr]], coicop = cp, unit = "PM", geo = g, time = yr))))

wt <-
  raw |>
  mutate(coicop = substr(coicop, 3, 4)) |>
  pivot_wider(names_from = grp, values_from = permille) |>
  group_by(geo) |>
  mutate(across(c(low, mid, high), ~ .x / sum(.x, na.rm = TRUE))) |>   # normalise Σw=1 per country
  ungroup() |>
  left_join(DIVISIONS, by = "coicop") |>
  mutate(country_iso2 = iso2(geo)) |>
  filter(!is.na(low)) |>
  select(geo, country_iso2, coicop, division, low, mid, high) |>
  arrange(geo, coicop)

dir.create(file.path(HERE, "data"), showWarnings = FALSE)
write_csv(wt, file.path(HERE, "data", "hbs_weights_by_country.csv"))
wt |> filter(geo == "EU27_2020") |> select(coicop, division, low, mid, high) |>
  write_csv(file.path(HERE, "data", "hbs_weights.csv"))

ncoun <- n_distinct(wt$geo) - 1
cat(sprintf("Eurostat HBS hbs_str_t223, year %s: %d countries + EU27 reference\n", yr, ncoun))
cat("countries:", paste(sort(setdiff(unique(wt$country_iso2), "EU27")), collapse = " "), "\n")
cat("\nfood share (CP01, %) low vs high, selected:\n")
wt |> filter(coicop == "01", country_iso2 %in% c("EU27","DE","RO","BG","RS","TR")) |>
  transmute(country_iso2, food_low = round(low*100,1), food_high = round(high*100,1),
            gap_pp = round((low-high)*100,1)) |> as.data.frame() |> print(row.names = FALSE)
cat("\nsaved: data/hbs_weights_by_country.csv, data/hbs_weights.csv\n")
