#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

P  <- load_prices()
g0 <- headline_panel(P)
W  <- load_master_weights() |> filter(country %in% g0$country)

yr_infl <-
  P$d |>
  mutate(year = year(date)) |>
  group_by(country, year, coicop) |>
  summarise(I = prod(r), n = n(), .groups = "drop")
yr_nat <-
  read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(coicop == "00", date >= START, date <= END, country %in% g0$country) |>
  mutate(year = year(date), r = 1 + mom_pct / 100) |>
  filter(!is.na(r)) |>
  group_by(country, year) |>
  summarise(all = prod(r), .groups = "drop")
yr <-
  yr_infl |>
  inner_join(select(W, country, coicop, low, high), by = c("country", "coicop")) |>
  group_by(country, year) |>
  summarise(months = max(n), AL = sum(low * I), AH = sum(high * I),
            food = I[coicop == "01"], .groups = "drop") |>
  inner_join(yr_nat, by = c("country", "year")) |>
  filter(months >= 9) |>
  mutate(ratio = (AL / AH - 1) * 100,
         rel_food = (food / all - 1) * 100) |>
  left_join(select(g0, country, tier), by = "country")

yr_summ <-
  yr |>
  group_by(year) |>
  summarise(n = n(), pos = sum(ratio > 0), med = median(ratio),
            med_hbs = median(ratio[tier == "HBS national quintiles"]),
            med_gcd = median(ratio[tier == "GCD global segments"]),
            food_up = sum(rel_food > 0), med_rel_food = median(rel_food),
            cor_food = cor(ratio, rel_food), .groups = "drop")
cond <-
  yr |>
  mutate(food = if_else(rel_food > 0, "food dearer than all-items", "food cheaper than all-items")) |>
  group_by(food) |>
  summarise(country_years = n(), ratio_pos = sum(ratio > 0), med = median(ratio), .groups = "drop")
within <-
  yr |>
  group_by(country) |>
  filter(n() >= 3) |>
  mutate(dr = ratio - mean(ratio), df = rel_food - mean(rel_food)) |>
  ungroup()
cor_within <- cor(within$dr, within$df)
slope_within <- coef(lm(dr ~ df - 1, within))[[1]]

GRP <- c(`1` = "low", `5` = "high")
hbs3 <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  filter(year == 2020, quintile %in% c(1, 5))
hbs_tot <-
  hbs3 |>
  group_by(country, quintile) |>
  summarise(tot = sum(permille[nchar(coicop) == 2]) - sum(permille[coicop == "042"]),
            .groups = "drop")
hbs_nrg <-
  hbs3 |>
  filter(coicop %in% c("045", "0722", "072")) |>
  left_join(hbs_tot, by = c("country", "quintile")) |>
  mutate(item = recode(coicop, `045` = "household energy (04.5)", `0722` = "motor fuel (07.2.2)",
                       `072` = "operation of vehicles (07.2, incl. fuel)"),
         share = permille / tot * 100, grp = GRP[as.character(quintile)]) |>
  select(country, item, grp, share) |>
  pivot_wider(names_from = grp, values_from = share) |>
  mutate(source = "HBS 2020 (ex imputed rent)")

fr <- gcd_quintile_fractions()
gcd_nrg <-
  read_csv(file.path(REV_DAT, "gcd_energy.csv"), show_col_types = FALSE) |>
  mutate(country = countrycode(iso3, "iso3c", "iso2c", warn = FALSE),
         country = if_else(iso3 == "NAM", "NA", country)) |>
  inner_join(fr$frac |> mutate(segment = as.character(segment)) |> filter(grp != "mid"),
             by = c("country", "segment"), relationship = "many-to-many") |>
  group_by(country, grp, item) |>
  summarise(e = sum(f * exp_lcu), .groups = "drop") |>
  left_join(fr$seg |>
              mutate(segment = as.character(segment)) |>
              inner_join(fr$frac |> mutate(segment = as.character(segment)),
                         by = c("country", "segment"), relationship = "many-to-many") |>
              group_by(country, grp) |>
              summarise(tot = sum(f * exp_lcu), .groups = "drop"),
            by = c("country", "grp")) |>
  mutate(share = e / tot * 100) |>
  select(country, item, grp, share) |>
  pivot_wider(names_from = grp, values_from = share) |>
  mutate(source = "GCD 2010 rebuilt quintiles")

nrg <-
  bind_rows(hbs_nrg, gcd_nrg) |>
  filter(country %in% c(g0$country, unique(hbs_nrg$country))) |>
  mutate(poor_more = low > high)
nrg_summ <-
  nrg |>
  group_by(source, item) |>
  summarise(n = n(), q1 = median(low), q5 = median(high), poor_more = sum(poor_more),
            .groups = "drop")

hicp <-
  read_csv(file.path(REV_DAT, "hicp_midx_long.csv"), show_col_types = FALSE) |>
  filter(coicop %in% c("00", "045", "072", "01", "041"))
dec <- function(y) ym(sprintf("%d-12", y))
yr_I <-
  map(year(START):year(END), \(y)
      hicp |>
        filter(date %in% c(dec(y - 1), dec(y))) |>
        group_by(country, coicop) |>
        filter(n() == 2) |>
        summarise(I = index[date == dec(y)] / index[date == dec(y - 1)], .groups = "drop") |>
        mutate(year = y)) |>
  list_rbind() |>
  bind_rows(hicp |>
              filter(date %in% c(START %m-% months(1), END)) |>
              group_by(country, coicop) |>
              filter(n() == 2) |>
              summarise(I = index[date == END] / index[date == START %m-% months(1)],
                        .groups = "drop") |>
              mutate(year = 0L))
hbs_all <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  filter(year == 2020, quintile %in% c(1, 5), coicop %in% c("045", "072", "01", "041")) |>
  left_join(hbs_tot, by = c("country", "quintile")) |>
  mutate(w = permille / tot, grp = GRP[as.character(quintile)]) |>
  select(country, coicop, grp, w) |>
  pivot_wider(names_from = grp, values_from = w, names_prefix = "w_")
contrib <-
  yr_I |>
  filter(coicop != "00") |>
  inner_join(yr_I |> filter(coicop == "00") |> select(country, year, A = I), by = c("country", "year")) |>
  inner_join(hbs_all, by = c("country", "coicop")) |>
  mutate(c = (w_low - w_high) * (I - A) / A * 100,
         item = recode(coicop, `045` = "household energy (04.5)",
                       `072` = "operation of vehicles (07.2, mostly fuel)",
                       `01` = "food (01)", `041` = "actual rent (04.1)"),
         period = if_else(year == 0L, sprintf("%d-%d", year(START), year(END)), as.character(year)))
c_summ <-
  contrib |>
  group_by(item, period) |>
  summarise(n = n(), med_price_rel = median((I / A - 1) * 100), med_c = median(c),
            pos = sum(c > 0), .groups = "drop") |>
  arrange(item, period)

write_csv(yr, file.path(REV_OUT, "07_subperiods_country_year.csv"))
write_csv(nrg, file.path(REV_OUT, "07_energy_shares.csv"))
write_csv(contrib, file.path(REV_OUT, "07_energy_contrib.csv"))

f2 <- function(x) sprintf("%.2f", x)
f1 <- function(x) sprintf("%.1f", x)
md <- c(
  "# 07 Energy and sub-periods",
  "",
  "## A. Calendar years, 51 countries (IMF prices, fixed-base within each year)",
  "",
  "| year | countries | ratio > 0 | median ratio % | median HBS | median GCD | food dearer than all-items (countries) | median relative food price % | corr(ratio, relative food) |",
  "|---|---|---|---|---|---|---|---|---|",
  yr_summ |> with(sprintf("| %d | %d | %d | %s | %s | %s | %d | %s | %s |", year, n, pos, f2(med),
                         f2(med_hbs), f2(med_gcd), food_up, f2(med_rel_food), f2(cor_food))),
  "",
  "| country-years where | n | ratio > 0 | median ratio % |",
  "|---|---|---|---|",
  cond |> with(sprintf("| %s | %d | %d | %s |", food, country_years, ratio_pos, f2(med))),
  "",
  sprintf("Within countries (deviations from each country's own mean over the years): corr(ratio, relative food price) = %s; slope %s pp of ratio per pp of relative food price.",
          f2(cor_within), f2(slope_within)),
  "",
  "## B. Two kinds of energy: budget shares, bottom vs top quintile (median across countries, % of budget)",
  "",
  "| source | item | countries | Q1 | Q5 | Q1 share > Q5 share in |",
  "|---|---|---|---|---|---|",
  nrg_summ |> with(sprintf("| %s | %s | %d | %s | %s | %d |", source, item, n, f1(q1), f1(q5), poor_more)),
  "",
  "## C. Contribution to the ratio by year, Eurostat countries (HICP prices, HBS 2020 shares ex imputed rent)",
  "",
  "Contribution = (w_Q1 - w_Q5) x (item price change relative to all-items). Positive = widens the gap against the poor.",
  "",
  "| item | period | countries | median item price relative to all-items % | median contribution (pp of ratio) | countries > 0 |",
  "|---|---|---|---|---|---|",
  c_summ |> with(sprintf("| %s | %s | %d | %s | %s | %d |", item, period, n, f2(med_price_rel), f2(med_c), pos)),
  ""
)
writeLines(md, file.path(REV_OUT, "07_energy_subperiods.md"))
cat(md, sep = "\n")
