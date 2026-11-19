#!/usr/bin/env Rscript
source(here::here("R", "rev_common.R"))

fr  <- gcd_quintile_fractions()
seg <- fr$seg
shares <- fr$shares
frac <- fr$frac

qw <-
  seg |>
  inner_join(frac, by = c("country", "segment"), relationship = "many-to-many") |>
  group_by(country, grp, coicop) |>
  summarise(e = sum(f * exp_lcu), .groups = "drop") |>
  group_by(country, grp) |>
  mutate(w = e / sum(e)) |>
  ungroup() |>
  select(-e) |>
  pivot_wider(names_from = grp, values_from = w)
write_csv(qw, file.path(REV_DAT, "gcd_quintile_weights.csv"))

comp <-
  frac |>
  inner_join(shares, by = c("country", "segment")) |>
  mutate(pop_share = f * p / 0.2) |>
  filter(grp == "high") |>
  select(country, segment, pop_share) |>
  pivot_wider(names_from = segment, values_from = pop_share, values_fill = 0)
higher_seg <-
  shares |>
  filter(segment == "Higher") |>
  select(country, higher_pop = p, higher_n = hh_sample)

P  <- load_prices()
g0 <- headline_panel(P)
W0 <- load_master_weights()

gq <-
  group_infl(P$d, qw) |>
  filter(n_months >= MIN_MONTHS) |>
  left_join(select(P$rel, country, national, reliable), by = "country") |>
  filter(reliable) |>
  mutate(gap = low - high, ratio = ratio_pct(low, high))

gcd_c <- W0 |> filter(source == "GCD_2010") |> distinct(country, note)
cmp <-
  gq |>
  inner_join(gcd_c, by = "country") |>
  left_join(select(g0, country, ratio_seg = ratio, gap_seg = gap, mid_seg = mid,
                   low_seg = low, high_seg = high), by = "country") |>
  left_join(higher_seg, by = "country") |>
  left_join(names_lookup(), by = "country") |>
  mutate(in_51 = !is.na(ratio_seg),
         status = case_when(in_51 ~ "in the 51 (GCD tier)",
                            note == "noisy_global_higher" ~ "recovered: noisy Higher basket",
                            TRUE ~ "recovered: no Higher segment"),
         mid_between = (mid - low) * (mid - high) <= 0) |>
  arrange(desc(ratio))
write_csv(cmp, file.path(REV_OUT, "02_gcd_quintiles.csv"))

hbs10 <-
  read_csv(file.path(REV_DAT, "hbs_str_t223_long.csv"), show_col_types = FALSE) |>
  fix_na_iso() |>
  filter(year == 2010, nchar(coicop) == 2, quintile %in% c(1, 3, 5)) |>
  group_by(country, quintile) |>
  mutate(w = permille / sum(permille)) |>
  ungroup() |>
  mutate(grp = c(`1` = "low", `3` = "mid", `5` = "high")[as.character(quintile)]) |>
  select(country, coicop, grp, w) |>
  pivot_wider(names_from = grp, values_from = w)
segw <-
  read_csv(file.path(HERE, "data", "gcd_weights_long.csv"), show_col_types = FALSE) |>
  filter(segment %in% c("Lowest", "Middle", "Higher")) |>
  mutate(country = countrycode(iso3, "iso3c", "iso2c", warn = FALSE),
         grp = recode(segment, Lowest = "low", Middle = "mid", Higher = "high")) |>
  select(country, coicop, grp, weight) |>
  pivot_wider(names_from = grp, values_from = weight)
both <- intersect(unique(hbs10$country), unique(qw$country))

val_infl <-
  list(`HBS 2010 true quintiles` = hbs10, `GCD rebuilt quintiles` = qw,
       `GCD global segments` = segw) |>
  map(~ filter(.x, country %in% both)) |>
  map(~ group_infl(P$d, select(.x, country, coicop, low, mid, high))) |>
  list_rbind(names_to = "basket") |>
  mutate(ratio = ratio_pct(low, high)) |>
  select(basket, country, ratio) |>
  pivot_wider(names_from = basket, values_from = ratio) |>
  left_join(names_lookup(), by = "country") |>
  left_join(select(P$rel, country, reliable), by = "country")

food_val <-
  list(`HBS 2010 true quintiles` = hbs10, `GCD rebuilt quintiles` = qw,
       `GCD global segments` = segw) |>
  map(~ filter(.x, country %in% both, coicop == "01")) |>
  list_rbind(names_to = "basket") |>
  transmute(basket, country, food_gap = (low - high) * 100) |>
  pivot_wider(names_from = basket, values_from = food_gap)

mae <- function(a, b) mean(abs(a - b), na.rm = TRUE)
v <- val_infl
err_q <- mae(v$`GCD rebuilt quintiles`, v$`HBS 2010 true quintiles`)
err_s <- mae(v$`GCD global segments`, v$`HBS 2010 true quintiles`)

f2 <- function(x) sprintf("%.2f", x)
f1 <- function(x) sprintf("%.1f", x)
tier51 <- cmp |> filter(in_51)
allq   <- cmp
sumrow <- function(df, lab, col) sprintf("| %s | %d | %d | %s | %s to %s |", lab, nrow(df),
                                         sum(df[[col]] > 0), f2(median(df[[col]])),
                                         f2(quantile(df[[col]], 0.25)), f2(quantile(df[[col]], 0.75)))
md <- c(
  "# 02 National quintile baskets rebuilt from the GCD",
  "",
  "Method: segments ranked by per-capita consumption (ordering verified in every country); bottom 20%, middle 20% (40th to 60th percentile) and top 20% of persons; segment spending pooled by the share of each segment inside the band. Within-segment homogeneity is assumed, which shrinks the measured distance between quintiles.",
  "",
  "## How thin is the GCD 'Higher' segment?",
  "",
  sprintf("Across the %d GCD countries with a Higher segment: median population share %s%%, median sample households %s; %d countries below 1%% of the population, %d below 50 sample households.",
          nrow(higher_seg), f1(100 * median(higher_seg$higher_pop)),
          f1(median(higher_seg$higher_n)), sum(higher_seg$higher_pop < 0.01),
          sum(higher_seg$higher_n < 50)),
  "",
  "In the 25-country GCD tier of the paper:",
  "",
  "| country | Higher segment % of population | sample households | top quintile made of (Lowest/Low/Middle/Higher, % of persons) |",
  "|---|---|---|---|",
  tier51 |>
    left_join(comp, by = "country") |>
    arrange(higher_pop) |>
    with(sprintf("| %s | %s | %s | %s / %s / %s / %s |", name, f2(100 * higher_pop),
                 f1(higher_n), f1(100 * Lowest), f1(100 * Low), f1(100 * Middle),
                 f1(100 * coalesce(Higher, 0)))),
  "",
  "## Result: ratio % under the two definitions",
  "",
  "| set | n | ratio > 0 | median ratio % | IQR |",
  "|---|---|---|---|---|",
  sumrow(tier51, "paper's 25 GCD countries, global segments", "ratio_seg"),
  sumrow(tier51, "same 25, rebuilt national quintiles", "ratio"),
  sumrow(allq, "all reliable GCD countries, rebuilt quintiles", "ratio"),
  "",
  sprintf("Spearman, segment ratio vs quintile ratio (25 countries): %s. Middle group between low and high: %d of %d with segments, %d of %d with quintiles.",
          f2(cor(tier51$ratio_seg, tier51$ratio, method = "spearman")),
          sum((tier51$mid_seg - tier51$low_seg) * (tier51$mid_seg - tier51$high_seg) <= 0), nrow(tier51),
          sum(tier51$mid_between), nrow(tier51)),
  "",
  "| country | status | all-items % | ratio %, segments | ratio %, quintiles | mid between? |",
  "|---|---|---|---|---|---|",
  allq |>
    with(sprintf("| %s | %s | %s | %s | %s | %s |", name, status, f1(national),
                 ifelse(is.na(ratio_seg), "", f2(ratio_seg)), f2(ratio),
                 ifelse(mid_between, "yes", "**no**"))),
  "",
  "## Validation: same-year true quintiles (Eurostat HBS 2010)",
  "",
  sprintf("Population implied from spending for: %s.",
          paste(unique(shares$country[shares$pop_from == "implied"]), collapse = ", ")),
  "",
  sprintf("Countries in both sources with price data: %s. Mean absolute error of the ratio against the true HBS 2010 quintiles: rebuilt quintiles %s pp of ratio, global segments %s.",
          paste(sort(v$name), collapse = ", "), f2(err_q), f2(err_s)),
  "",
  sprintf("Mean signed error (rebuilt minus true): %s; (segments minus true): %s.",
          f2(mean(v$`GCD rebuilt quintiles` - v$`HBS 2010 true quintiles`)),
          f2(mean(v$`GCD global segments` - v$`HBS 2010 true quintiles`))),
  "",
  "| country | reconciles? | ratio %, HBS 2010 quintiles | ratio %, GCD rebuilt quintiles | ratio %, GCD global segments |",
  "|---|---|---|---|---|",
  v |>
    with(sprintf("| %s | %s | %s | %s | %s |", name, ifelse(reliable, "yes", "no"),
                 f2(`HBS 2010 true quintiles`), f2(`GCD rebuilt quintiles`),
                 f2(`GCD global segments`))),
  "",
  "Food share, bottom minus top group (pp of budget):",
  "",
  "| country | HBS 2010 quintiles | GCD rebuilt quintiles | GCD global segments |",
  "|---|---|---|---|",
  food_val |>
    left_join(names_lookup(), by = "country") |>
    with(sprintf("| %s | %s | %s | %s |", name, f1(`HBS 2010 true quintiles`),
                 f1(`GCD rebuilt quintiles`), f1(`GCD global segments`))),
  ""
)
writeLines(md, file.path(REV_OUT, "02_gcd_quintiles.md"))
cat(md, sep = "\n")
