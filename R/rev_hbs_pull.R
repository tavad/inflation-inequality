#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

API <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

jsonstat_long <- function(js) {
  ids   <- unlist(js$id)
  sizes <- unlist(js$size)
  cats  <- map(ids, ~ names(sort(unlist(js$dimension[[.x]]$category$index))))
  grid  <- expand_grid(!!!set_names(cats, ids))
  vals  <- rep(NA_real_, prod(sizes))
  vals[as.integer(names(js$value)) + 1] <- as.numeric(unlist(js$value))
  mutate(grid, value = vals)
}

pull_year <- function(yr) {
  url <- sprintf("%shbs_str_t223?format=JSON&lang=EN&unit=PM&time=%s%s", API, yr,
                 paste0("&quant_inc=QU", 1:5, collapse = ""))
  message("pulling ", yr)
  jsonlite::fromJSON(url, simplifyVector = FALSE) |>
    jsonstat_long() |>
    filter(!is.na(value))
}

years <- c(2005, 2010, 2015, 2020)
hbs <-
  map(years, pull_year) |>
  list_rbind() |>
  filter(!str_detect(geo, "^(EU|EA)")) |>
  transmute(geo,
            country  = recode(geo, EL = "GR", UK = "GB"),
            year     = as.integer(time),
            quintile = as.integer(str_sub(quant_inc, 3)),
            coicop   = str_remove(coicop, "^CP"),
            permille = value)

write_csv(hbs, file.path(REV_DAT, "hbs_str_t223_long.csv"))
hbs |>
  filter(nchar(coicop) == 2) |>
  distinct(year, country) |>
  count(year, name = "countries") |>
  print()
cat("saved: data/revision/hbs_str_t223_long.csv\n")
