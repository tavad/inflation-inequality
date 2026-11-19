#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

GRP <- c(`1` = "low", `3` = "mid", `5` = "high")

hbs_all <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  filter(year == 2020, quintile %in% c(1, 3, 5)) |>
  mutate(grp = GRP[as.character(quintile)]) |>
  select(country, grp, coicop, permille)
imp <-
  hbs_all |>
  filter(coicop == "042") |>
  select(country, grp, imputed = permille)
hbs <-
  hbs_all |>
  filter(!str_starts(coicop, "042")) |>
  left_join(imp, by = c("country", "grp")) |>
  mutate(permille = if_else(coicop == "04", permille - coalesce(imputed, 0), permille)) |>
  select(-imputed)

n_need <- length(seq(START %m-% months(1), END, by = "month"))
hicp <-
  read_csv(file.path(REV_DAT, "hicp_midx_long.csv"), show_col_types = FALSE) |>
  filter(str_detect(coicop, "^[0-9]+$"), date >= START %m-% months(1), date <= END) |>
  select(country, coicop, date, index) |>
  group_by(country, coicop) |>
  filter(n() == n_need, all(index > 0)) |>
  ungroup()

refine <- function(sh, all_codes, to) {
  kids <-
    all_codes |>
    filter(nchar(coicop) == to) |>
    mutate(parent = str_sub(coicop, 1, to - 1))
  sh |>
    left_join(kids |> group_by(country, grp, parent) |>
                summarise(kid_sum = sum(permille), .groups = "drop"),
              by = c("country", "grp", "coicop" = "parent")) |>
    mutate(kid_sum = coalesce(kid_sum, 0),
           scale = if_else(kid_sum > permille, permille / kid_sum, 1),
           resid = pmax(permille - kid_sum, 0)) |>
    (\(p) bind_rows(
      p |> filter(resid > 0) |> transmute(country, grp, coicop, permille = resid),
      kids |>
        inner_join(select(p, country, grp, coicop, scale),
                   by = c("country", "grp", "parent" = "coicop")) |>
        transmute(country, grp, coicop, permille = permille * scale)))()
}

l2 <- hbs |> filter(nchar(coicop) == 2)
l3 <- refine(l2, hbs, 3)
levels <- list(`12 divisions` = l2, `COICOP 3-digit` = l3)

price_code <- function(codes, cty) {
  have <- unique(hicp$coicop[hicp$country == cty])
  map_chr(codes, \(k) { while (nchar(k) > 2 && !k %in% have) k <- str_sub(k, 1, -2)
                        if (k %in% have) k else NA_character_ })
}

rel <-
  hicp |>
  arrange(country, coicop, date) |>
  group_by(country, coicop) |>
  mutate(r = index / lag(index)) |>
  ungroup() |>
  filter(date >= START, date <= END, !is.na(r))
cum <-
  hicp |>
  group_by(country, coicop) |>
  summarise(I = index[date == END] / index[date == START %m-% months(1)], .groups = "drop") |>
  filter(is.finite(I))

price_level <- function(sh, lab) {
  sh <-
    sh |>
    group_by(country, grp) |>
    mutate(w = permille / sum(permille)) |>
    ungroup() |>
    group_by(country) |>
    mutate(pcode = price_code(coicop, first(country))) |>
    ungroup()
  miss <- sh |> filter(is.na(pcode)) |> summarise(w = sum(w)) |> pull(w)
  sh <- sh |> filter(!is.na(pcode))
  lasp <-
    sh |>
    inner_join(cum, by = c("country", "pcode" = "coicop")) |>
    group_by(country, grp) |>
    summarise(P = sum(w * I) / sum(w), .groups = "drop") |>
    mutate(formula = "fixed-base Laspeyres")
  chain <-
    sh |>
    inner_join(rel, by = c("country", "pcode" = "coicop"), relationship = "many-to-many") |>
    group_by(country, grp, date) |>
    summarise(f = sum(w * r) / sum(w), .groups = "drop") |>
    group_by(country, grp) |>
    summarise(P = prod(f), .groups = "drop") |>
    mutate(formula = "chained fixed-share")
  n_codes <- sh |> count(country, grp) |> group_by(country) |> summarise(n_codes = max(n))
  bind_rows(lasp, chain) |>
    mutate(level = lab) |>
    left_join(n_codes, by = "country") |>
    mutate(unpriced_share = miss)
}

P0 <- load_prices()
g0 <- headline_panel(P0)

res <-
  imap(levels, price_level) |>
  list_rbind() |>
  pivot_wider(names_from = grp, values_from = P) |>
  mutate(ratio = (low / high - 1) * 100,
         mid_between = (mid - low) * (mid - high) <= 0) |>
  left_join(names_lookup(), by = "country") |>
  left_join(select(g0, country, ratio_paper = ratio), by = "country")
write_csv(res, file.path(REV_OUT, "06_finer_categories.csv"))

w <-
  res |>
  select(country, name, formula, level, ratio) |>
  pivot_wider(names_from = level, values_from = ratio)
summ <-
  res |>
  group_by(formula, level) |>
  summarise(n = n(), codes = median(n_codes), pos = sum(ratio > 0), med = median(ratio),
            mean = mean(ratio), mid_ok = sum(mid_between), .groups = "drop")
chg <-
  w |>
  mutate(d3 = `COICOP 3-digit` - `12 divisions`) |>
  group_by(formula) |>
  summarise(up3 = sum(d3 > 0), down3 = sum(d3 < 0), med_d3 = median(d3), mean_d3 = mean(d3),
            .groups = "drop")
chk <- res |> filter(level == "12 divisions", formula == "chained fixed-share", !is.na(ratio_paper))

div_contrib <- function(sh, lab) {
  sh |>
    group_by(country, grp) |>
    mutate(w = permille / sum(permille)) |>
    ungroup() |>
    group_by(country) |>
    mutate(pcode = price_code(coicop, first(country))) |>
    ungroup() |>
    inner_join(cum, by = c("country", "pcode" = "coicop")) |>
    group_by(country, grp, div = str_sub(coicop, 1, 2)) |>
    summarise(A = sum(w * I), .groups = "drop") |>
    mutate(level = lab)
}
dc <-
  bind_rows(div_contrib(l2, "L2"), div_contrib(l3, "L3")) |>
  filter(grp != "mid") |>
  pivot_wider(names_from = c(grp, level), values_from = A, values_fill = 0) |>
  group_by(country) |>
  mutate(AL2 = sum(low_L2), AH2 = sum(high_L2), AL3 = sum(low_L3), AH3 = sum(high_L3),
         contrib = ((low_L3 - low_L2) - (AL3 / AH3) * (high_L3 - high_L2)) / AH2 * 100) |>
  ungroup()
stopifnot(dc |> group_by(country) |>
            summarise(e = abs(sum(contrib) - ((first(AL3) / first(AH3)) - (first(AL2) / first(AH2))) * 100)) |>
            pull(e) |> max() < 1e-8)
dc_summ <-
  dc |>
  left_join(DIVISIONS |> select(div = coicop, division), by = "div") |>
  group_by(div, division) |>
  summarise(median = median(contrib), mean = mean(contrib), neg = sum(contrib < -0.05),
            pos = sum(contrib > 0.05), .groups = "drop") |>
  arrange(mean)

f2 <- function(x) sprintf("%.2f", x)
md <- c(
  "# 06 Finer categories",
  "",
  sprintf("Sanity check, 12 divisions with HICP prices vs the paper's IMF-based ratio (%d countries in both): correlation %s, median absolute difference %s.",
          nrow(chk), f2(cor(chk$ratio, chk$ratio_paper)), f2(median(abs(chk$ratio - chk$ratio_paper)))),
  "",
  "| formula | level | countries | median priced codes | ratio > 0 | median ratio % | mean ratio % | middle between |",
  "|---|---|---|---|---|---|---|---|",
  summ |> with(sprintf("| %s | %s | %d | %d | %d | %s | %s | %d |", formula, level, n, as.integer(codes),
                       pos, f2(med), f2(mean), mid_ok)),
  "",
  "Change in the ratio from 12 divisions to finer detail (pp of ratio):",
  "",
  "| formula | up / down | median change | mean change |",
  "|---|---|---|---|",
  chg |> with(sprintf("| %s | %d / %d | %s | %s |", formula, up3, down3, f2(med_d3), f2(mean_d3))),
  "",
  "Which division's split moves the ratio (fixed-base Laspeyres; exact decomposition, contributions sum to each country's change):",
  "",
  "| division | mean contribution | median | countries < -0.05 | countries > +0.05 |",
  "|---|---|---|---|---|",
  dc_summ |> with(sprintf("| %s %s | %s | %s | %d | %d |", div, division, f2(mean), f2(median), neg, pos)),
  "",
  "By country, fixed-base Laspeyres:",
  "",
  "| country | 12 divisions | 3-digit | change |",
  "|---|---|---|---|",
  w |>
    filter(formula == "fixed-base Laspeyres") |>
    arrange(desc(`COICOP 3-digit`)) |>
    with(sprintf("| %s | %s | %s | %s |", name, f2(`12 divisions`), f2(`COICOP 3-digit`),
                 f2(`COICOP 3-digit` - `12 divisions`))),
  ""
)
writeLines(md, file.path(REV_OUT, "06_finer_categories.md"))
cat(md, sep = "\n")
