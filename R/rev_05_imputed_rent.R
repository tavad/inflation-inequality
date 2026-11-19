#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

P  <- load_prices()
g0 <- headline_panel(P)
hbs_c <- g0$country[g0$tier == "HBS national quintiles"]

h <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  filter(year == 2020, country %in% hbs_c, coicop %in% c(sprintf("%02d", 1:12), "042"))

imp_share <-
  h |>
  group_by(country, quintile) |>
  summarise(tot = sum(permille[nchar(coicop) == 2]),
            h04 = permille[coicop == "04"],
            imp = sum(permille[coicop == "042"]), .groups = "drop") |>
  mutate(h04_in = h04 / tot, h04_ex = (h04 - imp) / (tot - imp), imp = imp / tot)

scope <-
  imp_share |>
  group_by(country) |>
  summarise(hbs04_with = mean(h04_in), hbs04_without = mean(h04_ex),
            imp_q1 = imp[quintile == 1], imp_q5 = imp[quintile == 5], .groups = "drop") |>
  left_join(P$natw |> filter(coicop == "04") |> select(country, cpi04 = w), by = "country") |>
  mutate(cpi_scope = if_else(abs(cpi04 - hbs04_with) < abs(cpi04 - hbs04_without),
                             "closer to WITH imputed rent", "closer to WITHOUT imputed rent"))

ex <-
  h |>
  filter(quintile %in% c(1, 3, 5)) |>
  group_by(country, quintile) |>
  mutate(imp = sum(permille[coicop == "042"]),
         permille = if_else(coicop == "04", permille - imp, permille)) |>
  filter(coicop != "042") |>
  mutate(w = permille / sum(permille)) |>
  ungroup() |>
  mutate(grp = c(`1` = "low", `3` = "mid", `5` = "high")[as.character(quintile)]) |>
  select(country, coicop, grp, w) |>
  pivot_wider(names_from = grp, values_from = w)

alt <-
  group_infl(P$d, ex) |>
  mutate(ratio_ex = ratio_pct(low, high),
         mid_between_ex = (mid - low) * (mid - high) <= 0) |>
  select(country, ratio_ex, mid_between_ex)

res <-
  g0 |>
  filter(tier == "HBS national quintiles") |>
  select(country, ratio, low, mid, high) |>
  mutate(mid_between = (mid - low) * (mid - high) <= 0) |>
  inner_join(alt, by = "country") |>
  inner_join(scope, by = "country") |>
  left_join(names_lookup(), by = "country") |>
  mutate(d = ratio_ex - ratio) |>
  arrange(desc(abs(d)))
write_csv(res, file.path(REV_OUT, "05_imputed_rent.csv"))

f2 <- function(x) sprintf("%.2f", x)
f1 <- function(x) sprintf("%.1f", x)
by_scope <-
  res |>
  group_by(cpi_scope) |>
  summarise(n = n(), med_paper = median(ratio), med_ex = median(ratio_ex),
            pos_paper = sum(ratio > 0), pos_ex = sum(ratio_ex > 0), .groups = "drop")
md <- c(
  "# 05 Imputed rent in the HBS baskets",
  "",
  sprintf("Imputed rent is a larger share of the top-quintile budget than of the bottom in %d of %d countries (median Q1 %s%%, Q5 %s%%).",
          sum(res$imp_q5 > res$imp_q1), nrow(res), f1(100 * median(res$imp_q1)), f1(100 * median(res$imp_q5))),
  "",
  "| CPI division-04 weight is | n | median ratio %, paper | median ratio %, ex imputed rent | ratio > 0, paper | ratio > 0, ex |",
  "|---|---|---|---|---|---|",
  by_scope |> with(sprintf("| %s | %d | %s | %s | %d | %d |", cpi_scope, n, f2(med_paper), f2(med_ex), pos_paper, pos_ex)),
  "",
  sprintf("All 26: median ratio %s -> %s; ratio > 0 in %d -> %d; middle group between low and high %d -> %d.",
          f2(median(res$ratio)), f2(median(res$ratio_ex)), sum(res$ratio > 0), sum(res$ratio_ex > 0),
          sum(res$mid_between), sum(res$mid_between_ex)),
  "",
  "| country | IMF CPI 04 weight % | HBS 04 % with / without imputed rent | imputed rent Q1 / Q5 % | ratio % paper | ratio % ex | change |",
  "|---|---|---|---|---|---|---|",
  res |> with(sprintf("| %s | %s | %s / %s | %s / %s | %s | %s | %s |", name, f1(100 * cpi04),
                      f1(100 * hbs04_with), f1(100 * hbs04_without), f1(100 * imp_q1), f1(100 * imp_q5),
                      f2(ratio), f2(ratio_ex), f2(d))),
  ""
)
writeLines(md, file.path(REV_OUT, "05_imputed_rent.md"))
cat(md, sep = "\n")
