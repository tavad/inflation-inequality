#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

P <- load_prices()
g <- headline_panel(P)

food <-
  div_infl(P$d) |>
  filter(coicop == "01") |>
  select(country, food = infl)

res <-
  g |>
  left_join(food, by = "country") |>
  left_join(names_lookup(), by = "country") |>
  mutate(rel_food  = ratio_pct(food, national),
         food_exc  = food - national,
         rank_gap  = min_rank(desc(gap)),
         rank_ratio = min_rank(desc(ratio)),
         mid_between = (mid - low) * (mid - high) <= 0) |>
  arrange(desc(ratio))

write_csv(res, file.path(REV_OUT, "01_ratio_measure.csv"))

by_tier <-
  res |>
  group_by(tier) |>
  summarise(n = n(),
            ratio_pos = sum(ratio > 0),
            ratio_med = median(ratio),
            ratio_p25 = quantile(ratio, 0.25),
            ratio_p75 = quantile(ratio, 0.75),
            gap_med   = median(gap),
            .groups = "drop")
pooled <-
  res |>
  summarise(tier = "pooled (sensitivity only)", n = n(), ratio_pos = sum(ratio > 0),
            ratio_med = median(ratio), ratio_p25 = quantile(ratio, 0.25),
            ratio_p75 = quantile(ratio, 0.75), gap_med = median(gap))

ct <- function(x, y, m = "pearson") cor(x, y, method = m)
outl <- res |> filter(national == max(national))
mech <- tibble(
  spec = c("pp gap ~ food excess (pp), as in the paper",
           "ratio ~ relative food price (ratio form)",
           sprintf("ratio ~ relative food price, excluding %s", outl$name),
           "ratio ~ relative food price, HBS tier",
           "ratio ~ relative food price, GCD tier",
           "ratio ~ all-items inflation (level)",
           "pp gap ~ all-items inflation (level)"),
  pearson = c(ct(res$gap, res$food_exc), ct(res$ratio, res$rel_food),
              with(filter(res, country != outl$country), ct(ratio, rel_food)),
              with(filter(res, tier == "HBS national quintiles"), ct(ratio, rel_food)),
              with(filter(res, tier == "GCD global segments"), ct(ratio, rel_food)),
              ct(res$ratio, res$national), ct(res$gap, res$national)),
  spearman = c(ct(res$gap, res$food_exc, "spearman"), ct(res$ratio, res$rel_food, "spearman"),
               with(filter(res, country != outl$country), ct(ratio, rel_food, "spearman")),
               with(filter(res, tier == "HBS national quintiles"), ct(ratio, rel_food, "spearman")),
               with(filter(res, tier == "GCD global segments"), ct(ratio, rel_food, "spearman")),
               ct(res$ratio, res$national, "spearman"), ct(res$gap, res$national, "spearman")))

movers <-
  res |>
  mutate(shift = rank_gap - rank_ratio) |>
  filter(abs(shift) >= 8) |>
  arrange(desc(abs(shift)))

f1 <- function(x) sprintf("%.1f", x)
f2 <- function(x) sprintf("%.2f", x)
md <- c(
  "# 01 Ratio measure",
  "",
  "ratio = (1 + Pi_L)/(1 + Pi_H) - 1, in %.",
  "",
  "## Direction",
  sprintf("- ratio > 0 in %d of %d countries (pp gap > 0 in %d). The sign cannot change between the two measures; this is a check.",
          sum(res$ratio > 0), nrow(res), sum(res$gap > 0)),
  sprintf("- Spearman rank correlation, ratio vs pp gap: %s.", f2(ct(res$ratio, res$gap, "spearman"))),
  "",
  "## Level by weight source (do not pool as a headline)",
  "",
  "| tier | n | ratio > 0 | median ratio % | IQR ratio % | median pp gap |",
  "|---|---|---|---|---|---|",
  bind_rows(by_tier, pooled) |>
    with(sprintf("| %s | %d | %d | %s | %s to %s | %s |", tier, n, ratio_pos, f2(ratio_med),
                 f2(ratio_p25), f2(ratio_p75), f2(gap_med))),
  "",
  "## Top and bottom 8 by ratio",
  "",
  "| country | tier | all-items % | low % | high % | pp gap | ratio % | rank pp | rank ratio |",
  "|---|---|---|---|---|---|---|---|---|",
  bind_rows(slice_head(res, n = 8), slice_tail(res, n = 8)) |>
    with(sprintf("| %s | %s | %s | %s | %s | %s | %s | %d | %d |", name, str_extract(tier, "^\\w+"),
                 f1(national), f1(low), f1(high), f1(gap), f2(ratio), rank_gap, rank_ratio)),
  "",
  "## Large rank movers (|rank pp - rank ratio| >= 8)",
  "",
  if (nrow(movers)) movers |>
    with(sprintf("- %s: rank %d by pp, %d by ratio (all-items %s%%)", name, rank_gap, rank_ratio,
                 f1(national))) else "- none",
  "",
  "## Mechanism (Section 5.3) restated",
  "",
  "| specification | Pearson | Spearman |",
  "|---|---|---|",
  mech |> with(sprintf("| %s | %s | %s |", spec, f2(pearson), f2(spearman))),
  "",
  sprintf("Highest all-items inflation in the panel: %s (%s%%).", outl$name, f1(outl$national)),
  ""
)
writeLines(md, file.path(REV_OUT, "01_ratio_measure.md"))
cat(md, sep = "\n")
