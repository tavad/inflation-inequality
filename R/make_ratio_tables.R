#!/usr/bin/env Rscript
source(here::here("R", "imf_cpi_helpers.R"))

fmt <- function(x, d = 2) { x <- round(x, d); x[x == 0] <- 0; formatC(x, format = "f", digits = d) }
ratio_pct <- function(pl, ph) ((1 + pl / 100) / (1 + ph / 100) - 1) * 100
clean_name <- function(x) x |>
  str_replace_all("`", "'") |>
  str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
  str_replace(", Republic of$", "") |>
  str_replace(",? Rep\\.?$", "") |>
  str_replace("^Moldova.*", "Moldova")

master <- read_csv(file.path(HERE, "outputs", "group_cpi_divergence_master.csv"), show_col_types = FALSE, na = character())
rel <-
  master |>
  mutate(across(c(national, low, mid, high, gap, ratio, divergence), \(x) suppressWarnings(as.numeric(x))),
         reliable = reliable == "TRUE") |>
  filter(reliable, wsource != "noisy_global_higher", !is.na(gap)) |>
  mutate(name = clean_name(name), country = coalesce(country, "NA"))
stopifnot(nrow(rel) == 51, sum(rel$gap > 0) == 44)
stopifnot(all(abs(rel$ratio - ratio_pct(rel$low, rel$high)) < 1e-9))

out <- file(file.path(HERE, "outputs", "tables_ratio.md"), open = "w")
w   <- function(...) cat(..., "\n", sep = "", file = out)
SRC <- "*Source:* author's calculations from IMF, Eurostat, and World Bank data.\n"

summ <- function(x) tibble(n = nrow(x), pos = sum(x$ratio > 0), med = median(x$ratio),
                           q1 = quantile(x$ratio, .25), q3 = quantile(x$ratio, .75),
                           max = max(x$ratio), med_pp = median(x$gap))
tier_tab <-
  bind_rows(rel |> group_by(tier) |> group_modify(~ summ(.x)) |> ungroup(),
            summ(rel) |> mutate(tier = "pooled (sensitivity only)"))
w("## Ratio by weight source (%, 2021-01 to 2024-12)\n")
w("| Weight source | n | Ratio > 0 | Median ratio | IQR | Max | Median gap (pp) |")
w("|---|--:|--:|--:|--:|--:|--:|")
for (i in seq_len(nrow(tier_tab))) {
  r <- tier_tab[i, ]
  w("| ", r$tier, " | ", r$n, " | ", r$pos, " | ", fmt(r$med), " | ", fmt(r$q1), " to ", fmt(r$q3),
    " | ", fmt(r$max, 1), " | ", fmt(r$med_pp), " |")
}
w("")
w("*Notes:* ratio = (1 + low-income inflation) / (1 + high-income inflation) − 1. GCD uses global income segments and HBS national quintiles, so the groups are not the same thing in the two rows. The pooled row is a sensitivity check only. ", SRC)

rk <-
  rel |>
  mutate(rank_pp = rank(-gap, ties.method = "min"), rank_ratio = rank(-ratio, ties.method = "min"))
show <-
  bind_rows(rk |> arrange(desc(ratio)) |> slice_head(n = 10),
            rk |> filter(national > 300),
            rk |> arrange(ratio) |> slice_head(n = 6)) |>
  distinct(country, .keep_all = TRUE)
w("## Ranking by ratio (top 10, Türkiye, bottom 6)\n")
w("| Country | Weight source | All-items | Low | High | Gap (pp) | Ratio | Rank (pp) | Rank (ratio) |")
w("|---|:--|--:|--:|--:|--:|--:|--:|--:|")
for (i in seq_len(nrow(show))) {
  r <- show[i, ]
  w("| ", r$name, " | ", str_extract(r$tier, "^\\w+"), " | ", fmt(r$national, 1), " | ", fmt(r$low, 1), " | ",
    fmt(r$high, 1), " | ", fmt(r$gap, 1), " | ", fmt(r$ratio), " | ", r$rank_pp, " | ", r$rank_ratio, " |")
}
w("")
w("*Notes:* Spearman correlation of the two rankings: ", fmt(cor(rk$gap, rk$ratio, method = "spearman")), ". ", SRC)

wide <-
  read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE) |>
  mutate(country = coalesce(country, "NA"))
START <- ym("2021-01")
END   <- ym("2024-12")
d <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= START, date <= END) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  group_by(country, date) |> filter(n_distinct(coicop) == 12) |> ungroup()
div_cum <- d |> group_by(country, coicop) |> summarise(infl = (prod(r) - 1) * 100, .groups = "drop")
food <- div_cum |> filter(coicop == "01") |> select(country, food = infl)
mech <-
  rel |>
  left_join(food, by = "country") |>
  mutate(rel_food = ratio_pct(food, national), food_exc = food - national)

cc <- function(x, y, m = "pearson") fmt(cor(x, y, method = m, use = "complete.obs"))
specs <- list(
  list("Gap (pp) on food excess (pp)", "food_exc", "gap", mech),
  list("Ratio on relative food price, all", "rel_food", "ratio", mech),
  list("Ratio on relative food price, excluding Türkiye", "rel_food", "ratio", filter(mech, national <= 300)),
  list("Ratio on relative food price, GCD", "rel_food", "ratio", filter(mech, str_detect(tier, "GCD"))),
  list("Ratio on relative food price, HBS", "rel_food", "ratio", filter(mech, str_detect(tier, "HBS"))),
  list("Ratio on all-items inflation", "national", "ratio", mech),
  list("Gap (pp) on all-items inflation", "national", "gap", mech)
)
w("## Ratio and the relative price of food\n")
w("| Specification | Pearson | Spearman | n |")
w("|---|--:|--:|--:|")
for (s in specs) {
  m <- s[[4]]
  w("| ", s[[1]], " | ", cc(m[[s[[2]]]], m[[s[[3]]]]), " | ", cc(m[[s[[2]]]], m[[s[[3]]]], "spearman"), " | ", nrow(m), " |")
}
w("")
w("*Notes:* relative food price = (1 + food inflation) / (1 + all-items inflation) − 1. ", SRC)

divn <- DIVISIONS |> filter(coicop != "00") |> select(coicop, division)
cum_t <-
  div_cum |>
  inner_join(select(mech, country, tier), by = "country") |>
  group_by(tier, coicop) |> summarise(med = median(infl), .groups = "drop") |>
  pivot_wider(names_from = tier, values_from = med)
W <-
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  mutate(country_iso2 = coalesce(country_iso2, "NA")) |>
  inner_join(select(mech, country, tier), by = c("country_iso2" = "country")) |>
  group_by(tier, coicop) |> summarise(low = median(low) * 100, high = median(high) * 100, .groups = "drop")
tab_div <-
  divn |>
  left_join(cum_t, by = "coicop") |>
  left_join(W |> filter(str_detect(tier, "GCD")) |> select(coicop, gcd_low = low, gcd_high = high), by = "coicop") |>
  left_join(W |> filter(str_detect(tier, "HBS")) |> select(coicop, hbs_low = low, hbs_high = high), by = "coicop")
w("## Cumulative inflation and expenditure shares by COICOP division (medians, %)\n")
w("| Division | Inflation, GCD | Inflation, HBS | Share low / high, GCD | Share low / high, HBS |")
w("|---|--:|--:|--:|--:|")
for (i in seq_len(nrow(tab_div))) {
  r <- tab_div[i, ]
  w("| ", r$coicop, " ", r$division, " | ", fmt(r$`GCD global segments`, 1), " | ", fmt(r$`HBS national quintiles`, 1), " | ",
    fmt(r$gcd_low, 1), " / ", fmt(r$gcd_high, 1), " | ", fmt(r$hbs_low, 1), " / ", fmt(r$hbs_high, 1), " |")
}
w("")
w("*Notes:* medians over the countries in each weight source. ", SRC)
write_csv(tab_div, file.path(HERE, "outputs", "ratio_divisions.csv"))

W51 <-
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  mutate(country_iso2 = coalesce(country_iso2, "NA")) |>
  transmute(country = country_iso2, coicop, low, high) |>
  semi_join(mech, by = "country")
nat_y <-
  wide |>
  filter(coicop == "00", date >= START, date <= END) |>
  mutate(year = year(date), r = 1 + mom_pct / 100) |>
  filter(!is.na(r)) |> group_by(country, year) |> filter(n() == 12) |>
  summarise(nat = (prod(r) - 1) * 100, .groups = "drop")
food_y <-
  d |>
  mutate(year = year(date)) |>
  filter(coicop == "01") |> group_by(country, year) |> filter(n() == 12) |>
  summarise(food = (prod(r) - 1) * 100, .groups = "drop")
yr <-
  d |>
  mutate(year = year(date)) |>
  inner_join(W51, by = c("country", "coicop")) |>
  group_by(country, year, date) |>
  summarise(fl = sum(r * low), fh = sum(r * high), .groups = "drop") |>
  group_by(country, year) |>
  summarise(n = n(), low = (prod(fl) - 1) * 100, high = (prod(fh) - 1) * 100, .groups = "drop") |>
  filter(n == 12) |>
  mutate(ratio = ratio_pct(low, high)) |>
  left_join(nat_y, by = c("country", "year")) |>
  left_join(food_y, by = c("country", "year")) |>
  mutate(rel_food = ratio_pct(food, nat), food_dearer = rel_food > 0)
w("## Ratio by calendar year (51 countries)\n")
w("| Year | Country-years | Median ratio | Ratio > 0 |")
w("|---|--:|--:|--:|")
for (y in 2021:2024) {
  z <- filter(yr, year == y)
  w("| ", y, " | ", nrow(z), " | ", fmt(median(z$ratio)), " | ", sum(z$ratio > 0), " |")
}
w("")
w("| Food relative to all-items | Country-years | Median ratio | Ratio > 0 |")
w("|---|--:|--:|--:|")
for (b in c(TRUE, FALSE)) {
  z <- filter(yr, food_dearer == b)
  w("| ", if (b) "dearer" else "cheaper", " | ", nrow(z), " | ", fmt(median(z$ratio)), " | ", sum(z$ratio > 0), " |")
}
w("")
w("*Notes:* group inflation is chained within the calendar year, and a country-year needs all 12 months. Correlation of the ratio with the relative price of food over country-years: ",
  fmt(cor(yr$ratio, yr$rel_food, use = "complete.obs")), ". ", SRC)
write_csv(yr, file.path(HERE, "outputs", "ratio_subperiods.csv"))

out_mid <- rel |> filter(mid > pmax(low, high) | mid < pmin(low, high))
rest    <- rel |> filter(!country %in% out_mid$country)
w("## Middle group outside the low-high range\n")
w(nrow(out_mid), " of ", nrow(rel), " countries: ", paste(out_mid$name, collapse = ", "), ". Their median absolute ratio is ",
  fmt(median(abs(out_mid$ratio))), "%, against ", fmt(median(abs(rest$ratio))), "% for the other ", nrow(rest),
  " (Wilcoxon p = ", fmt(wilcox.test(abs(out_mid$ratio), abs(rest$ratio), exact = FALSE)$p.value, 3), ").\n")

mk <- function(df, title) {
  df <- arrange(df, desc(ratio))
  w("### ", title, "\n")
  w("| Country | All-items | Low | Mid | High | Ratio | Gap (pp) |")
  w("|---|--:|--:|--:|--:|--:|--:|")
  for (i in seq_len(nrow(df))) {
    r <- df[i, ]
    w("| ", r$name, " | ", fmt(r$national, 1), " | ", fmt(r$low, 1), " | ", fmt(r$mid, 1), " | ", fmt(r$high, 1),
      " | ", fmt(r$ratio), " | ", fmt(r$gap, 1), " |")
  }
  w("")
}
w("## Country results by weight source (%, 2021-01 to 2024-12)\n")
mk(filter(rel, str_detect(tier, "GCD")), sprintf("GCD global segments (n = %d)", sum(str_detect(rel$tier, "GCD"))))
mk(filter(rel, str_detect(tier, "HBS")), sprintf("HBS national quintiles (n = %d)", sum(str_detect(rel$tier, "HBS"))))
w(SRC)

close(out)
write_csv(rk, file.path(HERE, "outputs", "ratio_panel.csv"))
cat("wrote outputs/tables_ratio.md\n")
