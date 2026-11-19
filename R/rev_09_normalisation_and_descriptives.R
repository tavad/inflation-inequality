#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

P <- load_prices()
reliable <- P$rel |> filter(reliable, n_months >= MIN_MONTHS) |> pull(country)

raw <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(nchar(coicop) == 2, quintile %in% c(1, 5), country %in% reliable) |>
  group_by(country, year, quintile) |>
  filter(n_distinct(coicop) == 12) |>
  mutate(w_raw = permille / 1000, w_norm = permille / sum(permille), S = sum(permille) / 1000) |>
  ungroup()

run <- function(col) {
  raw |>
    mutate(grp = if_else(quintile == 1, "low", "high"), w = .data[[col]]) |>
    select(country, year, coicop, grp, w) |>
    pivot_wider(names_from = grp, values_from = w) |>
    group_split(year) |>
    map(~ group_infl(P$d, select(.x, country, coicop, low, high), c("low", "high")) |>
          mutate(year = .x$year[1])) |>
    list_rbind() |>
    transmute(country, year, n_months, ratio = ratio_pct(low, high))
}
norm <-
  run("w_raw") |>
  rename(ratio_raw = ratio) |>
  inner_join(run("w_norm") |> select(country, year, ratio_norm = ratio), by = c("country", "year")) |>
  inner_join(raw |> distinct(country, year, quintile, S) |>
               pivot_wider(names_from = quintile, values_from = S, names_prefix = "S_q"),
             by = c("country", "year")) |>
  mutate(spurious = ratio_raw - ratio_norm,
         predicted = ((S_q1 / S_q5)^n_months - 1) * 100,
         sign_flip = sign(ratio_raw) != sign(ratio_norm))
write_csv(norm, file.path(REV_OUT, "09_normalisation.csv"))

sums <- raw |> distinct(country, year, quintile, S)

hbs <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(year == 2020, quintile %in% c(1, 3, 5), coicop %in% c(sprintf("%02d", 1:12), "042")) |>
  group_by(country, quintile) |>
  mutate(imp = sum(permille[coicop == "042"]),
         permille = if_else(coicop == "04", permille - imp, permille)) |>
  filter(coicop != "042") |>
  mutate(w = permille / sum(permille)) |>
  ungroup() |>
  mutate(grp = c(`1` = "low", `3` = "mid", `5` = "high")[as.character(quintile)]) |>
  select(country, coicop, grp, w) |>
  pivot_wider(names_from = grp, values_from = w) |>
  mutate(tier = "HBS")
gcd <-
  read_csv(file.path(REV_DAT, "gcd_quintile_weights.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(!country %in% hbs$country) |>
  mutate(tier = "GCD rebuilt")
W <-
  bind_rows(hbs, gcd) |>
  filter(country %in% reliable) |>
  left_join(DIVISIONS |> select(coicop, division), by = "coicop") |>
  left_join(names_lookup(), by = "country")
write_csv(W, file.path(REV_OUT, "09_shares_by_group.csv"))

DI <-
  div_infl(P$d) |>
  filter(country %in% W$country) |>
  left_join(P$nat, by = "country") |>
  mutate(rel = ((1 + infl / 100) / (1 + national / 100) - 1) * 100) |>
  left_join(DIVISIONS |> select(coicop, division), by = "coicop") |>
  left_join(names_lookup(), by = "country") |>
  left_join(distinct(W, country, tier), by = "country")
write_csv(DI, file.path(REV_OUT, "09_division_inflation.csv"))

sh_summ <-
  W |>
  group_by(tier, coicop, division) |>
  summarise(q1 = median(low) * 100, q5 = median(high) * 100, poor_more = sum(low > high),
            n = n(), .groups = "drop")
di_summ <-
  DI |>
  group_by(coicop, division) |>
  summarise(med_rel = median(rel), above = sum(rel > 0), n = n(), .groups = "drop")

f2 <- function(x) sprintf("%.2f", x)
f1 <- function(x) sprintf("%.1f", x)
f3 <- function(x) sprintf("%.3f", x)
md <- c(
  "# 09 Sum-to-one demonstration and descriptive tables",
  "",
  "## A. Published shares do not sum to one",
  "",
  sprintf("Eurostat HBS quintile shares over the 12 divisions, reliable countries, all waves: raw sums range %s to %s (median %s); %d of %d country-wave-quintile sums are off by more than 0.1%%.",
          f3(min(sums$S)), f3(max(sums$S)), f3(median(sums$S)), sum(abs(sums$S - 1) > 0.001), nrow(sums)),
  "",
  sprintf("Using the raw shares in the chained index moves the ratio by a median of %s pp (max %s pp) and flips its sign in %d of %d country-waves. Correlation of the spurious ratio with the analytical drift ((S_L/S_H)^T - 1): %s.",
          f2(median(abs(norm$spurious))), f2(max(abs(norm$spurious))), sum(norm$sign_flip), nrow(norm),
          f3(cor(norm$spurious, norm$predicted))),
  "",
  "Largest cases:",
  "",
  "| country | wave | raw sum Q1 | raw sum Q5 | ratio % normalised | ratio % raw | spurious | predicted drift |",
  "|---|---|---|---|---|---|---|---|",
  norm |>
    arrange(desc(abs(spurious))) |>
    slice_head(n = 10) |>
    left_join(names_lookup(), by = "country") |>
    with(sprintf("| %s | %d | %s | %s | %s | %s | %s | %s |", name, year, f3(S_q1), f3(S_q5),
                 f2(ratio_norm), f2(ratio_raw), f2(spurious), f2(predicted))),
  "",
  "## B1. Budget shares by group (median across countries, %; revised weights)",
  "",
  "| tier | division | Q1 | Q5 | Q1 > Q5 in |",
  "|---|---|---|---|---|",
  sh_summ |> with(sprintf("| %s | %s %s | %s | %s | %d of %d |", tier, coicop, division, f1(q1), f1(q5), poor_more, n)),
  "",
  "## B2. Cumulative division inflation relative to all-items, 2021-24 (median across countries)",
  "",
  "| division | median relative price change % | above all-items in |",
  "|---|---|---|",
  di_summ |> with(sprintf("| %s %s | %s | %d of %d |", coicop, division, f2(med_rel), above, n)),
  "",
  "Country-level tables: `09_shares_by_group.csv`, `09_division_inflation.csv`.",
  ""
)
writeLines(md, file.path(REV_OUT, "09_normalisation_and_descriptives.md"))
cat(md, sep = "\n")
