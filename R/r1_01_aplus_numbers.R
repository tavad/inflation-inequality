#!/usr/bin/env Rscript
source(here::here("R", "imf_cpi_helpers.R"))
OUT <- file.path(HERE, "outputs")
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
ratio_pct <- function(pl, ph) ((1 + pl / 100) / (1 + ph / 100) - 1) * 100
tidy_name <- function(x) x |>
  str_replace_all("`", "'") |>
  str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
  str_replace(", Republic of$", "") |>
  str_replace(",? Rep\\.?$", "") |>
  str_replace("^Moldova.*", "Moldova")

master <-
  read_csv(file.path(OUT, "group_cpi_divergence_master.csv"), show_col_types = FALSE, na = character()) |>
  mutate(across(c(national, low, mid, high, gap, ratio, divergence), \(x) suppressWarnings(as.numeric(x))),
         reliable = reliable == "TRUE")
rel <-
  master |>
  filter(reliable, wsource != "noisy_global_higher", !is.na(gap)) |>
  mutate(name = tidy_name(name))
stopifnot(nrow(rel) == 51, sum(rel$gap > 0) == 44)
stopifnot(all(abs(rel$ratio - ratio_pct(rel$low, rel$high)) < 1e-9))

lines <- character()
add <- function(...) lines <<- c(lines, paste0(...))
add("# Ratio numbers by weight source\n")

summ <- function(x) tibble(n = nrow(x), pos = sum(x$ratio > 0),
                           med = median(x$ratio), q1 = quantile(x$ratio, .25), q3 = quantile(x$ratio, .75),
                           max = max(x$ratio), med_pp = median(x$gap))
tier_tab <-
  bind_rows(rel |> group_by(tier) |> group_modify(~ summ(.x)) |> ungroup(),
            summ(rel) |> mutate(tier = "pooled (sensitivity only)"))
add("## A. Headline: ratio by weight source (pooled row is a sensitivity check, not a result)\n")
add("| weight source | n | ratio > 0 | median ratio % | IQR % | max % | median pp gap |")
add("|---|---|---|---|---|---|---|")
for (i in seq_len(nrow(tier_tab))) with(tier_tab[i, ],
  add("| ", tier, " | ", n, " | ", pos, " | ", fmt(med), " | ", fmt(q1), " to ", fmt(q3), " | ", fmt(max, 1), " | ", fmt(med_pp), " |"))
add("\nPooled share of countries with the low-income basket more expensive: ", sum(rel$ratio > 0), " / ", nrow(rel),
    " (the sign statement does not depend on the tier definition).")
add("A median difference between the tiers is not interpretable as a developed/developing contrast (different income-group definitions).\n")

rk <- rel |> mutate(rank_pp = rank(-gap, ties.method = "min"), rank_ratio = rank(-ratio, ties.method = "min"))
add("## B. Ranking by ratio (top 10, Türkiye, bottom 6)\n")
add("| country | tier | all-items % | low % | high % | pp gap | ratio % | rank pp | rank ratio |")
add("|---|---|---|---|---|---|---|---|---|")
show <- bind_rows(rk |> arrange(desc(ratio)) |> slice_head(n = 10),
                  rk |> filter(national > 300),
                  rk |> arrange(ratio) |> slice_head(n = 6)) |> distinct(country, .keep_all = TRUE)
for (i in seq_len(nrow(show))) with(show[i, ],
  add("| ", name, " | ", str_extract(tier, "^\\w+"), " | ", fmt(national, 1), " | ", fmt(low, 1), " | ",
      fmt(high, 1), " | ", fmt(gap, 1), " | ", fmt(ratio), " | ", rank_pp, " | ", rank_ratio, " |"))
add("\nSpearman(rank pp, rank ratio) = ", fmt(cor(rk$gap, rk$ratio, method = "spearman")),
    ". Malawi ", fmt(rk$ratio[rk$name == "Malawi"], 1), "%, Bolivia ", fmt(rk$ratio[rk$name == "Bolivia"], 1),
    "%.\n")

wide <- read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE) |>
  mutate(country = coalesce(country, "NA"))
START <- ym("2021-01"); END <- ym("2024-12")
d <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= START, date <= END) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  group_by(country, date) |> filter(n_distinct(coicop) == 12) |> ungroup()
div_cum <- d |> group_by(country, coicop) |> summarise(infl = (prod(r) - 1) * 100, .groups = "drop")
food <- div_cum |> filter(coicop == "01") |> select(country, food = infl)
mech <-
  rel |> mutate(country = coalesce(country, "NA")) |>
  left_join(food, by = "country") |>
  mutate(rel_food = ratio_pct(food, national), food_exc = food - national)
cc <- function(x, y, m = "pearson") fmt(cor(x, y, method = m, use = "complete.obs"))
add("## C. Mechanism (Section 5.3 restated): ratio against relative food price (1+food)/(1+all-items)-1\n")
add("| specification | Pearson | Spearman | n |")
add("|---|---|---|---|")
sp <- list(
  "pp gap ~ food excess (pp), as submitted"          = list(mech$food_exc, mech$gap, mech),
  "ratio ~ relative food price, all"                 = list(mech$rel_food, mech$ratio, mech),
  "ratio ~ relative food price, excl. Türkiye"       = list(NULL, NULL, filter(mech, national <= 300)),
  "ratio ~ relative food price, GCD tier"            = list(NULL, NULL, filter(mech, str_detect(tier, "GCD"))),
  "ratio ~ relative food price, HBS tier"            = list(NULL, NULL, filter(mech, str_detect(tier, "HBS"))),
  "ratio ~ all-items inflation (level), all"         = list(mech$national, mech$ratio, mech),
  "pp gap ~ all-items inflation (level), all"        = list(mech$national, mech$gap, mech))
for (nm in names(sp)) {
  s <- sp[[nm]]; m <- s[[3]]
  x <- if (is.null(s[[1]])) m$rel_food else s[[1]]
  y <- if (is.null(s[[2]])) m$ratio else s[[2]]
  add("| ", nm, " | ", cc(x, y), " | ", cc(x, y, "spearman"), " | ", length(x), " |")
}
add("\nThe food mechanism is a developing-tier result; in the HBS tier the gaps are small and driven by housing/energy (see `outputs/revision/06`, `07`).\n")

divn <- DIVISIONS |> filter(coicop != "00") |> select(coicop, division)
add("## D. Cumulative inflation by COICOP division (median across countries, %), and shares by group\n")
cum_t <-
  div_cum |> semi_join(mech, by = "country") |> left_join(select(mech, country, tier), by = "country") |>
  group_by(tier, coicop) |> summarise(med = median(infl), .groups = "drop") |>
  pivot_wider(names_from = tier, values_from = med)
W <- read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  mutate(country_iso2 = coalesce(country_iso2, "NA")) |>
  semi_join(mech, by = c("country_iso2" = "country")) |>
  left_join(select(mech, country, tier), by = c("country_iso2" = "country")) |>
  group_by(tier, coicop) |> summarise(low = median(low) * 100, high = median(high) * 100, .groups = "drop")
tabD <-
  divn |> left_join(cum_t, by = "coicop") |>
  left_join(W |> filter(str_detect(tier, "GCD")) |> select(coicop, gl = low, gh = high), by = "coicop") |>
  left_join(W |> filter(str_detect(tier, "HBS")) |> select(coicop, hl = low, hh = high), by = "coicop")
add("| division | cum. infl GCD | cum. infl HBS | share low/high GCD | share low/high HBS |")
add("|---|---|---|---|---|")
for (i in seq_len(nrow(tabD))) with(tabD[i, ],
  add("| ", coicop, " ", division, " | ", fmt(`GCD global segments`, 1), " | ", fmt(`HBS national quintiles`, 1),
      " | ", fmt(gl, 1), " / ", fmt(gh, 1), " | ", fmt(hl, 1), " / ", fmt(hh, 1), " |"))
write_csv(tabD, file.path(OUT, "r1_01_division_table.csv"))
add("")

W51 <- read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  mutate(country_iso2 = coalesce(country_iso2, "NA")) |>
  transmute(country = country_iso2, coicop, low, mid, high) |>
  semi_join(mech, by = "country")
yr <-
  d |> mutate(year = year(date)) |>
  inner_join(W51, by = c("country", "coicop")) |>
  group_by(country, year, date) |>
  summarise(fl = sum(r * low), fh = sum(r * high), .groups = "drop") |>
  group_by(country, year) |>
  summarise(n = n(), low = (prod(fl) - 1) * 100, high = (prod(fh) - 1) * 100, .groups = "drop") |>
  filter(n == 12) |>
  mutate(ratio = ratio_pct(low, high))
fy <-
  d |> mutate(year = year(date)) |>
  group_by(country, year, coicop) |> filter(n() == 12) |> summarise(I = prod(r), .groups = "drop") |>
  inner_join(select(mech, country) |> mutate(x = 1), by = "country")
nat_y <-
  wide |> filter(coicop == "00", date >= START, date <= END) |>
  mutate(year = year(date), r = 1 + mom_pct / 100, country = coalesce(country, "NA")) |>
  filter(!is.na(r)) |> group_by(country, year) |> filter(n() == 12) |>
  summarise(nat = (prod(r) - 1) * 100, .groups = "drop")
food_y <-
  fy |> filter(coicop == "01") |> transmute(country, year, food = (I - 1) * 100)
yr <- yr |> left_join(nat_y, by = c("country", "year")) |> left_join(food_y, by = c("country", "year")) |>
  mutate(rel_food = ratio_pct(food, nat), food_dearer = rel_food > 0)
add("## E. Sub-periods (calendar years; 51-country panel)\n")
add("| year | country-years | median ratio % | ratio > 0 |")
add("|---|---|---|---|")
for (y in 2021:2024) { z <- filter(yr, year == y)
  add("| ", y, " | ", nrow(z), " | ", fmt(median(z$ratio)), " | ", sum(z$ratio > 0), " |") }
add("\nBy whether food rose faster or slower than all-items in that country-year:\n")
add("| food relative to all-items | country-years | median ratio % | ratio > 0 |")
add("|---|---|---|---|")
for (b in c(TRUE, FALSE)) { z <- filter(yr, food_dearer == b, !is.na(food_dearer))
  add("| ", if (b) "food rose faster" else "food rose slower", " | ", nrow(z), " | ", fmt(median(z$ratio)), " | ", sum(z$ratio > 0), " |") }
add("\nWithin-country correlation of ratio with relative food price across years: ",
    fmt(cor(yr$ratio, yr$rel_food, use = "complete.obs")), " (pooled over country-years).\n")
write_csv(yr, file.path(OUT, "r1_01_subperiods_country_year.csv"))

out_mid <- rel |> filter(mid > pmax(low, high) | mid < pmin(low, high))
add("## F. Middle group outside [low, high]\n")
add(nrow(out_mid), " of ", nrow(rel), " countries: ", paste(out_mid$name, collapse = ", "), ".")
add("Median |ratio| for these: ", fmt(median(abs(out_mid$ratio))), "% against ", fmt(median(abs(rel$ratio[!rel$country %in% out_mid$country]))),
    "% for the other ", nrow(rel) - nrow(out_mid), " (Wilcoxon p = ",
    fmt(wilcox.test(abs(out_mid$ratio), abs(rel$ratio[!rel$country %in% out_mid$country]), exact = FALSE)$p.value, 3), ").\n")

mk <- function(df, title) {
  add("### ", title, "\n")
  add("| Country | All-items | Low | Mid | High | Ratio % | pp gap |")
  add("|---|--:|--:|--:|--:|--:|--:|")
  df <- arrange(df, desc(ratio))
  for (i in seq_len(nrow(df))) with(df[i, ],
    add("| ", name, " | ", fmt(national, 1), " | ", fmt(low, 1), " | ", fmt(mid, 1), " | ", fmt(high, 1),
        " | ", fmt(ratio), " | ", fmt(gap, 1), " |"))
  add("")
}
add("## G. Tier tables (Table 2a / 2b; full lists for Appendix B)\n")
mk(filter(rel, str_detect(tier, "GCD")), sprintf("GCD global segments (n = %d)", sum(str_detect(rel$tier, "GCD"))))
mk(filter(rel, str_detect(tier, "HBS")), sprintf("HBS national quintiles (n = %d)", sum(str_detect(rel$tier, "HBS"))))

writeLines(lines, file.path(OUT, "r1_01_aplus_numbers.md"))
write_csv(rk, file.path(OUT, "r1_01_panel_ratio.csv"))
cat("wrote outputs/r1_01_aplus_numbers.md\n")
