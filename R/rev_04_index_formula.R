#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

GRID <- c(0.25, 0.5, 0.75, 1.5)

P  <- load_prices()
g0 <- headline_panel(P)
W  <-
  load_master_weights() |>
  filter(country %in% g0$country) |>
  select(country, coicop, low, high) |>
  pivot_longer(c(low, high), names_to = "grp", values_to = "w")

I <- div_infl(P$d) |> select(country, coicop, I)

ces <- function(w, I, s) if (abs(s - 1) < 1e-9) exp(sum(w * log(I))) else
  sum(w * I^(1 - s))^(1 / (1 - s))
torn <- function(w, I, s) {
  sT <- w * I^(1 - s) / sum(w * I^(1 - s))
  exp(sum((w + sT) / 2 * log(I)))
}

chained <-
  P$d |>
  inner_join(W, by = c("country", "coicop"), relationship = "many-to-many") |>
  group_by(country, grp, date) |>
  summarise(f = sum(w * r), .groups = "drop") |>
  group_by(country, grp) |>
  summarise(`chained fixed-share (paper)` = prod(f), .groups = "drop")

alt <-
  W |>
  inner_join(I, by = c("country", "coicop")) |>
  group_by(country, grp) |>
  summarise(`fixed-quantity Laspeyres (s=0)` = sum(w * I),
            `geometric (s=1)` = ces(w, I, 1),
            !!!set_names(map(GRID, \(s) expr(ces(w, I, !!s))), sprintf("CES s=%.2f", GRID)),
            !!!set_names(map(GRID, \(s) expr(torn(w, I, !!s))), sprintf("Tornqvist s=%.2f", GRID)),
            .groups = "drop")

idx <-
  chained |>
  inner_join(alt, by = c("country", "grp")) |>
  pivot_longer(-c(country, grp), names_to = "formula", values_to = "P") |>
  pivot_wider(names_from = grp, values_from = P) |>
  mutate(ratio = (low / high - 1) * 100) |>
  left_join(select(g0, country, tier), by = "country")
write_csv(idx, file.path(REV_OUT, "04_index_formula.csv"))

base <- idx |> filter(formula == "chained fixed-share (paper)") |> select(country, ratio0 = ratio)
summ <-
  idx |>
  left_join(base, by = "country") |>
  mutate(d = ratio - ratio0) |>
  group_by(formula) |>
  summarise(pos = sum(ratio > 0),
            med_ratio = median(ratio),
            med_hbs = median(ratio[tier == "HBS national quintiles"]),
            med_gcd = median(ratio[tier == "GCD global segments"]),
            up = sum(d > 1e-9), down = sum(d < -1e-9),
            med_d = median(d), max_abs_d = max(abs(d)), .groups = "drop") |>
  arrange(match(formula, c("chained fixed-share (paper)", "fixed-quantity Laspeyres (s=0)",
                           sprintf("CES s=%.2f", GRID[GRID < 1]), "geometric (s=1)",
                           sprintf("CES s=%.2f", GRID[GRID > 1]),
                           sprintf("Tornqvist s=%.2f", GRID))))

f2 <- function(x) sprintf("%.2f", x)
md <- c(
  "# 04 Index formula",
  "",
  "| formula | ratio > 0 | median ratio % | median HBS | median GCD | up | down | median change | max abs change |",
  "|---|---|---|---|---|---|---|---|---|",
  summ |> with(sprintf("| %s | %d | %s | %s | %s | %d | %d | %s | %s |", formula, pos, f2(med_ratio),
                       f2(med_hbs), f2(med_gcd), up, down, f2(med_d), f2(max_abs_d))),
  ""
)
writeLines(md, file.path(REV_OUT, "04_index_formula.md"))
cat(md, sep = "\n")
