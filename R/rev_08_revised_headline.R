#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

P  <- load_prices()
g0 <- headline_panel(P)

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
  mutate(tier = "HBS national quintiles")
gcd <-
  read_csv(file.path(REV_DAT, "gcd_quintile_weights.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(!country %in% hbs$country) |>
  mutate(tier = "GCD rebuilt national quintiles")
W <- bind_rows(hbs, gcd)

I <- div_infl(P$d) |> select(country, coicop, I)
lasp <-
  W |>
  inner_join(I, by = c("country", "coicop")) |>
  group_by(country, tier) |>
  summarise(low = sum(low * I), mid = sum(mid * I), high = sum(high * I),
            dist = sum(abs(low - high)) / 2, .groups = "drop")
dist <-
  W |>
  group_by(country) |>
  summarise(dist = sum(abs(low - high)) / 2, food_gap = (low[coicop == "01"] - high[coicop == "01"]) * 100,
            .groups = "drop")
chain <-
  group_infl(P$d, select(W, country, coicop, low, mid, high)) |>
  transmute(country, n_months, ratio_chain = ratio_pct(low, high))

res <-
  lasp |>
  select(-dist) |>
  mutate(ratio = (low / high - 1) * 100,
         mid_between = (mid - low) * (mid - high) <= 0,
         mid_excess = pmax(0, pmax(mid - pmax(low, high), pmin(low, high) - mid)) / abs(low - high)) |>
  inner_join(chain, by = "country") |>
  left_join(dist, by = "country") |>
  left_join(select(P$rel, country, national, reliable), by = "country") |>
  filter(reliable, n_months >= MIN_MONTHS) |>
  left_join(names_lookup(), by = "country") |>
  left_join(select(g0, country, ratio_paper = ratio, gap_paper = gap), by = "country") |>
  mutate(in_51 = !is.na(ratio_paper)) |>
  arrange(desc(ratio))
write_csv(res, file.path(REV_OUT, "08_revised_headline.csv"))

row <- function(df, lab, col = "ratio") {
  x <- df[[col]]
  tibble(set = lab, n = length(x), pos = sum(x > 0), med = median(x),
         p25 = quantile(x, 0.25), p75 = quantile(x, 0.75),
         mid_ok = sum(df$mid_between))
}
summ <- bind_rows(
  row(filter(g0, tier == "HBS national quintiles") |> mutate(mid_between = (mid - low) * (mid - high) <= 0),
      "paper, HBS national quintiles (chained, with imputed rent)"),
  row(filter(g0, tier == "GCD global segments") |> mutate(mid_between = (mid - low) * (mid - high) <= 0),
      "paper, GCD global segments (chained)"),
  row(filter(res, tier == "HBS national quintiles"), "revised, HBS national quintiles"),
  row(filter(res, tier == "GCD rebuilt national quintiles", in_51), "revised, GCD rebuilt quintiles, the paper's 25"),
  row(filter(res, tier == "GCD rebuilt national quintiles"), "revised, GCD rebuilt quintiles, all"),
  row(res, "revised, pooled (sensitivity only)"),
  row(filter(res, in_51), "revised, the paper's 51 only"),
  row(res |> mutate(ratio = ratio_chain), "revised weights, chained index, pooled", "ratio"))

nm <- res |> filter(!mid_between)
mono_test <-
  res |>
  mutate(grp = if_else(mid_between, "middle between", "middle outside")) |>
  group_by(grp) |>
  summarise(n = n(), med_dist = median(dist), med_abs_ratio = median(abs(ratio)),
            med_food_gap = median(food_gap), .groups = "drop")
wt <- function(v) wilcox.test(v[res$mid_between], v[!res$mid_between])$p.value

f2 <- function(x) sprintf("%.2f", x)
f1 <- function(x) sprintf("%.1f", x)
md <- c(
  "# 08 Candidate revised headline (all corrections together)",
  "",
  "| set | n | ratio > 0 | median ratio % | IQR | middle between low and high |",
  "|---|---|---|---|---|---|",
  summ |> with(sprintf("| %s | %d | %d | %s | %s to %s | %d |", set, n, pos, f2(med), f2(p25), f2(p75), mid_ok)),
  "",
  "## Middle group outside [low, high]",
  "",
  sprintf("Revised spec: %d of %d countries. Basket distance = half the sum of |w_low - w_high| over the 12 divisions.",
          nrow(nm), nrow(res)),
  "",
  "| group | n | median basket distance | median abs ratio % | median food-share gap (pp) |",
  "|---|---|---|---|---|",
  mono_test |> with(sprintf("| %s | %d | %s | %s | %s |", grp, n, f2(med_dist), f2(med_abs_ratio), f1(med_food_gap))),
  "",
  sprintf("Wilcoxon p (between vs outside): basket distance %s, abs ratio %s.", f2(wt(res$dist)), f2(wt(abs(res$ratio)))),
  "",
  "| country | tier | low % | mid % | high % | ratio % | middle outside by (share of low-high distance) |",
  "|---|---|---|---|---|---|---|",
  nm |> with(sprintf("| %s | %s | %s | %s | %s | %s | %s |", name, str_extract(tier, "^\\w+"),
                     f1((low - 1) * 100), f1((mid - 1) * 100), f1((high - 1) * 100), f2(ratio), f2(mid_excess))),
  "",
  "## All countries, revised spec",
  "",
  "| country | tier | in the 51? | all-items % | ratio % revised | ratio % paper | pp gap paper |",
  "|---|---|---|---|---|---|---|",
  res |> with(sprintf("| %s | %s | %s | %s | %s | %s | %s |", name, str_extract(tier, "^\\w+"),
                      ifelse(in_51, "yes", "new"), f1(national), f2(ratio),
                      ifelse(is.na(ratio_paper), "", f2(ratio_paper)),
                      ifelse(is.na(gap_paper), "", f1(gap_paper)))),
  ""
)
writeLines(md, file.path(REV_OUT, "08_revised_headline.md"))
cat(md, sep = "\n")
