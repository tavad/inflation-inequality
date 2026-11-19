#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

hbs <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(nchar(coicop) == 2, quintile %in% c(1, 3, 5))

W <-
  hbs |>
  group_by(country, year, quintile) |>
  filter(n_distinct(coicop) == 12) |>
  mutate(w = permille / sum(permille)) |>
  ungroup() |>
  mutate(grp = c(`1` = "low", `3` = "mid", `5` = "high")[as.character(quintile)]) |>
  select(country, year, coicop, grp, w) |>
  pivot_wider(names_from = grp, values_from = w) |>
  filter(!is.na(low), !is.na(mid), !is.na(high))

P  <- load_prices()
g0 <- headline_panel(P)

res <-
  W |>
  group_split(year) |>
  map(~ group_infl(P$d, select(.x, country, coicop, low, mid, high)) |>
        mutate(year = .x$year[1])) |>
  list_rbind() |>
  filter(n_months >= MIN_MONTHS) |>
  left_join(select(P$rel, country, national, reliable), by = "country") |>
  filter(reliable) |>
  mutate(ratio = ratio_pct(low, high)) |>
  left_join(W |> filter(coicop == "01") |>
              transmute(country, year, food_low = low, food_high = high), by = c("country", "year")) |>
  left_join(names_lookup(), by = "country") |>
  mutate(in_51_hbs = country %in% g0$country[g0$tier == "HBS national quintiles"])
write_csv(res, file.path(REV_OUT, "03_weight_waves.csv"))

wide <-
  res |>
  select(country, name, year, ratio) |>
  pivot_wider(names_from = year, values_from = ratio, names_prefix = "r")

pair <- function(a, b) {
  x <- wide |> filter(!is.na(.data[[a]]), !is.na(.data[[b]]))
  d <- x[[b]] - x[[a]]
  tibble(change = sprintf("%s -> %s", str_sub(a, 2), str_sub(b, 2)), n = nrow(x),
         up = sum(d > 0), down = sum(d < 0), mean_d = mean(d), median_d = median(d),
         sign_p = if (nrow(x)) binom.test(sum(d > 0), sum(d != 0))$p.value else NA_real_,
         med_from = median(x[[a]]), med_to = median(x[[b]]))
}
chg <- bind_rows(pair("r2015", "r2020"), pair("r2010", "r2020"), pair("r2010", "r2015"),
                 pair("r2005", "r2010"), pair("r2005", "r2020"))

bal <- wide |> filter(if_all(starts_with("r"), ~ !is.na(.x)))
bal_trend <-
  res |>
  filter(country %in% bal$country) |>
  group_by(year) |>
  summarise(n = n(), median_ratio = median(ratio), mean_ratio = mean(ratio),
            food_gap_pp = median((food_low - food_high) * 100), .groups = "drop")

paper <- wide |> filter(country %in% g0$country[g0$tier == "HBS national quintiles"])
d51 <- paper |> filter(!is.na(r2015), !is.na(r2020)) |> mutate(d = r2020 - r2015)

f2 <- function(x) if_else(is.na(x), "", sprintf("%.2f", x))
f3 <- function(x) sprintf("%.3f", x)
md <- c(
  "# 03 Weight waves",
  "",
  "## Change in the ratio when the weights are moved forward",
  "",
  "| weights moved | n | ratio up | ratio down | mean change (pp of ratio) | median change | sign-test p | median ratio before | after |",
  "|---|---|---|---|---|---|---|---|---|",
  chg |> with(sprintf("| %s | %d | %d | %d | %s | %s | %s | %s | %s |", change, n, up, down,
                      f2(mean_d), f2(median_d), f3(sign_p), f2(med_from), f2(med_to))),
  "",
  sprintf("## Balanced panel (%d countries present in all four waves)", nrow(bal)),
  "",
  "| wave | median ratio % | mean ratio % | median food-share gap Q1-Q5 (pp) |",
  "|---|---|---|---|",
  bal_trend |> with(sprintf("| %d | %s | %s | %s |", year, f2(median_ratio), f2(mean_ratio), f2(food_gap_pp))),
  "",
  sprintf("## The paper's HBS tier: 2015 vs 2020 weights (%d countries with both)", nrow(d51)),
  "",
  sprintf("Ratio higher with 2020 weights in %d, lower in %d; median change %s, mean %s.",
          sum(d51$d > 0), sum(d51$d < 0), f2(median(d51$d)), f2(mean(d51$d))),
  "",
  "| country | 2005 | 2010 | 2015 | 2020 |",
  "|---|---|---|---|---|",
  wide |>
    arrange(name) |>
    with(sprintf("| %s%s | %s | %s | %s | %s |", name,
                 ifelse(country %in% paper$country, "", " (not in 51)"),
                 f2(r2005), f2(r2010), f2(r2015), f2(r2020))),
  ""
)
writeLines(md, file.path(REV_OUT, "03_weight_waves.md"))
cat(md, sep = "\n")
