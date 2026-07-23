#!/usr/bin/env Rscript
# IMF CPI by COICOP division for a chosen country set
# (for ALL countries + updates, use pull_imf_cpi_all.R)
# usage:  Rscript R/pull_imf_cpi.R AM GE US DE TR   # ISO-2 DBnomics codes
# output: data/imf_cpi_coicop_{long,wide}.csv
source(here::here("R", "imf_cpi_helpers.R"))

args      <- commandArgs(trailingOnly = TRUE)
countries <- if (length(args)) args else c("AM", "GE", "US", "DE", "TR")

message("Pulling IMF/CPI (COICOP divisions) for: ", paste(countries, collapse = ", "))
long <- map_dfr(countries, function(cc) { message(" - ", cc); tidy_cpi(fetch_country(cc)) })
stopifnot(nrow(long) > 0)

wide <-
  long |>
  pivot_wider(names_from = measure, values_from = value) |>
  arrange(country, coicop, date)

dir.create(file.path(HERE, "data"), showWarnings = FALSE)
write_csv(long, file.path(HERE, "data", "imf_cpi_coicop_long.csv"))
write_csv(wide, file.path(HERE, "data", "imf_cpi_coicop_wide.csv"))

cat("\n=== coverage ===\n")
long |>
  group_by(country) |>
  summarise(divisions = n_distinct(coicop), measures = n_distinct(measure),
            span = sprintf("%s -> %s", format(min(date)), format(max(date))), .groups = "drop") |>
  as.data.frame() |> print(row.names = FALSE)
cat(sprintf("\nsaved: data/imf_cpi_coicop_{long,wide}.csv (%d rows)\n", nrow(long)))
