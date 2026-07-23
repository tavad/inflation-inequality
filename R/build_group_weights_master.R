#!/usr/bin/env Rscript
# merge HBS + GCD into per-country baskets -> data/group_weights_master.csv
# (country_iso2, coicop, division, low, mid, high, source, note): one basket
# triple per country, normalised Σ=1, ready to join onto the price panel by ISO2.
# prefer HBS (within-country quintiles, 2020) where available, else GCD (global
# percentile segments, 2010) for the developing world.
# caveat: HBS low/high = within-country Q1/Q5, GCD low/high = GLOBAL lowest/higher
# bins. related but not the same concept (tagged in the note column).
source(here::here("R", "imf_cpi_helpers.R"))
suppressPackageStartupMessages(library(countrycode))

gcd <-
  read_csv(file.path(HERE, "data", "gcd_weights_long.csv"), show_col_types = FALSE) |>
  filter(segment %in% c("Lowest", "Middle", "Higher")) |>
  mutate(grp = recode(segment, Lowest = "low", Middle = "mid", Higher = "high")) |>
  select(iso3, division, coicop, grp, weight) |>
  pivot_wider(names_from = grp, values_from = weight) |>
  mutate(country_iso2 = countrycode(iso3, "iso3c", "iso2c", warn = FALSE))

# a country's 'Higher' bin is degenerate/noisy if one division dominates it
noisy <-
  gcd |>
  group_by(country_iso2) |>
  summarise(noisy_high = max(high, na.rm = TRUE) > 0.40, .groups = "drop")

gcd <-
  gcd |>
  left_join(noisy, by = "country_iso2") |>
  filter(!is.na(country_iso2)) |>
  transmute(country_iso2, coicop, division, low, mid, high,
            source = "GCD_2010", note = ifelse(noisy_high, "noisy_global_higher", ""))

hbs <-
  read_csv(file.path(HERE, "data", "hbs_weights_by_country.csv"), show_col_types = FALSE) |>
  filter(country_iso2 != "EU27") |>
  transmute(country_iso2, coicop, division, low, mid, high, source = "HBS_2020", note = "")

hbs_c <- unique(hbs$country_iso2)
master <-
  bind_rows(hbs, gcd |> filter(!country_iso2 %in% hbs_c)) |>
  group_by(country_iso2) |>
  mutate(across(c(low, mid, high), ~ .x / sum(.x, na.rm = TRUE))) |>   # re-normalise Σ=1
  ungroup() |>
  arrange(country_iso2, coicop)

write_csv(master, file.path(HERE, "data", "group_weights_master.csv"))

imf <-
  read_csv(file.path(HERE, "data", "imf_cpi_pull_log.csv"), show_col_types = FALSE) |>
  filter(divisions >= 13) |> pull(code)
cov <- master |> distinct(country_iso2, source) |> count(source)
cat("=== group_weights_master.csv ===\n")
print(as.data.frame(cov), row.names = FALSE)
cat(sprintf("total countries with baskets: %d\n", n_distinct(master$country_iso2)))
cat(sprintf("of which also in IMF price panel (joinable): %d\n",
            n_distinct(intersect(master$country_iso2, imf))))
cat(sprintf("GCD countries flagged noisy_global_higher: %d\n",
            n_distinct(master$country_iso2[master$note == "noisy_global_higher"])))
cat("\nArmenia basket (source, food/transport/recreation low-high):\n")
master |> filter(country_iso2 == "AM", coicop %in% c("01","07","09")) |>
  transmute(division = str_trunc(division, 22), source,
            low = round(low,3), mid = round(mid,3), high = round(high,3)) |>
  as.data.frame() |> print(row.names = FALSE)
cat("\nsaved: data/group_weights_master.csv\n")
