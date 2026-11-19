#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

API <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

jsonstat_long <- function(js) {
  ids   <- unlist(js$id)
  cats  <- map(ids, ~ names(sort(unlist(js$dimension[[.x]]$category$index))))
  grid  <- expand_grid(!!!set_names(cats, ids))
  vals  <- rep(NA_real_, prod(unlist(js$size)))
  vals[as.integer(names(js$value)) + 1] <- as.numeric(unlist(js$value))
  mutate(grid, value = vals)
}

geos <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  filter(year == 2020) |>
  distinct(geo) |>
  pull(geo)

pull_geo <- function(g) {
  url <- sprintf("%sprc_hicp_midx?format=JSON&lang=EN&unit=I15&geo=%s&sinceTimePeriod=%s&untilTimePeriod=%s",
                 API, g, format(START %m-% months(1), "%Y-%m"), format(END, "%Y-%m"))
  message("pulling ", g)
  tryCatch(jsonlite::fromJSON(url, simplifyVector = FALSE) |> jsonstat_long(),
           error = function(e) { message("  ! ", g, ": ", conditionMessage(e)); NULL })
}

hicp <-
  map(geos, pull_geo) |>
  list_rbind() |>
  filter(!is.na(value)) |>
  transmute(geo,
            country = recode(geo, EL = "GR", UK = "GB"),
            coicop  = str_remove(coicop, "^CP"),
            date    = ym(time),
            index   = value)

write_csv(hicp, file.path(REV_DAT, "hicp_midx_long.csv"))
hicp |> distinct(country) |> nrow() |> sprintf(fmt = "countries: %d\n") |> cat()
cat("saved: data/revision/hicp_midx_long.csv\n")
