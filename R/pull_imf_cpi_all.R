#!/usr/bin/env Rscript
# bulk pull / update IMF CPI by COICOP for ALL countries
# loops every IMF/CPI reference area, pulls monthly COICOP divisions
# (index / YoY% / MoM% / official weight). Re-run any time to update (IMF
# publishes monthly). Source = DBnomics (free, citable to IMF).
# usage:  Rscript R/pull_imf_cpi_all.R
# output: data/imf_cpi_coicop_all_{long,wide}.csv, data/imf_cpi_pull_log.csv
source(here::here("R", "imf_cpi_helpers.R"))

freq <- "M"
cc   <- imf_cpi_countries()
message(sprintf("IMF/CPI reference areas: %d. Pulling monthly COICOP divisions...", nrow(cc)))

acc <- vector("list", nrow(cc))
log <- vector("list", nrow(cc))
for (i in seq_len(nrow(cc))) {
  code <- cc$code[i]; nm <- cc$name[i]
  raw  <- fetch_country(code, freq)
  ti   <- tidy_cpi(raw)
  ndiv <- if (nrow(ti)) n_distinct(ti$coicop) else 0L
  acc[[i]] <- ti
  log[[i]] <- tibble(code = code, name = nm, divisions = ndiv,
                     rows = nrow(ti),
                     span = if (nrow(ti)) sprintf("%s->%s", format(min(ti$date)), format(max(ti$date))) else NA)
  if (i %% 20 == 0 || i == nrow(cc))
    message(sprintf("  [%3d/%3d] %-28s divisions=%d", i, nrow(cc), paste0(code, " ", nm), ndiv))
}

all_long <- bind_rows(acc)
plog     <- bind_rows(log)
stopifnot(nrow(all_long) > 0)

all_wide <-
  all_long |>
  pivot_wider(names_from = measure, values_from = value) |>
  arrange(country, coicop, date)

dir.create(file.path(HERE, "data"), showWarnings = FALSE)
write_csv(all_long, file.path(HERE, "data", "imf_cpi_coicop_all_long.csv"))
write_csv(all_wide, file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"))
write_csv(plog,     file.path(HERE, "data", "imf_cpi_pull_log.csv"))

full12 <- plog |> filter(divisions >= 13)   # all 12 divisions + all-items
cat("\n================ PULL SUMMARY ================\n")
cat(sprintf("reference areas queried : %d\n", nrow(plog)))
cat(sprintf("with monthly COICOP data: %d\n", sum(plog$divisions > 0)))
cat(sprintf("with the FULL 12 divisions: %d\n", nrow(full12)))
cat(sprintf("total rows written      : %d\n", nrow(all_long)))
cat("countries lacking full COICOP (data > 0 but < 13 series):\n  ")
cat(paste(plog |> filter(divisions > 0, divisions < 13) |> pull(code), collapse = " "), "\n")
cat(sprintf("\nsaved: data/imf_cpi_coicop_all_{long,wide}.csv, data/imf_cpi_pull_log.csv\n"))
