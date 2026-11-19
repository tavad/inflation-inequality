#!/usr/bin/env Rscript
# build the manuscript tables that need only the locked CSVs (markdown, drop-in).
# every number traces to a CSV.
#   Table 1  basket composition by income group (Engel gradient)
#   Table 2  headline results, curated ~20 (from master CSV)
#   Table 4  weights-sensitivity ladder (§5.4; max−min divergence)
#   Table B1 full 51-country results (Appendix B)
# Table 3 (category decomposition, §5.3) needs the raw price CSV, in make_tables_extra.R.
# output: outputs/tables_1_4.md  (holds Tables 1, 2, 4, B1)
source(here::here("R", "imf_cpi_helpers.R"))
nn  <- function(w) is.na(w) | w != "noisy_global_higher"
f1  <- function(x) { x <- round(x, 1); x[x == 0] <- 0; formatC(x, format = "f", digits = 1) }  # kill -0.0

master  <- read_csv(file.path(HERE, "outputs", "group_cpi_divergence_master.csv"), show_col_types = FALSE)
handset <- read_csv(file.path(HERE, "outputs", "group_cpi_divergence.csv"),        show_col_types = FALSE)
W       <- read_csv(file.path(HERE, "data", "group_weights_master.csv"),           show_col_types = FALSE)

# tidy country names: kill the stray backtick, drop ", Republic of", fix Côte d'Ivoire
clean_name <- function(x) x |>
  str_replace_all("`", "'") |>
  str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
  str_replace(", Republic of$", "") |>
  str_replace("^Moldova.*", "Moldova")

rel <-
  master |>
  filter(reliable, nn(wsource), !is.na(gap)) |>
  mutate(name = clean_name(name))                # 51 estimation-sample countries
hnd <-
  handset |>
  filter(reliable, nn(wsource), !is.na(gap))     # 108
src <- W |> distinct(country = country_iso2, source)

out <- file(file.path(HERE, "outputs", "tables_1_4.md"), open = "w")
w   <- function(...) cat(..., "\n", sep = "", file = out)

# ---- Table 1 : basket composition (Engel gradient) -------------------------
key <- tibble(coicop = c("01","04","07","09","11"),
              label  = c("Food & non-alcoholic beverages","Housing, water, electricity, gas & fuels",
                         "Transport","Recreation & culture","Restaurants & hotels"))
# average over the 51 estimation-sample countries (all have a complete triple),
# split by data source -> a clean Engel gradient with no missing high baskets
tiers <-
  W |> semi_join(rel, by = c("country_iso2" = "country")) |>
  mutate(tier = if_else(source == "HBS_2020", "developed", "dev"))
n_dev  <- tiers |> filter(tier == "dev")       |> distinct(country_iso2) |> nrow()
n_developed <- tiers |> filter(tier == "developed") |> distinct(country_iso2) |> nrow()
comp <-
  tiers |> inner_join(key, by = "coicop") |>
  group_by(tier, coicop, label) |>
  summarise(low = mean(low) * 100, high = mean(high) * 100, .groups = "drop")
g <- function(t, cc, grp) { v <- comp |> filter(tier == t, coicop == cc) |> pull({{grp}}); if (length(v)) f1(v) else "–" }
w("## Table 1 — Basket composition by income group (mean expenditure share, %)\n")
w("| COICOP division | Global segments: low | Global segments: high | National quintiles: low | National quintiles: high |")
w("|---|--:|--:|--:|--:|")
for (i in seq_len(nrow(key))) {
  cc <- key$coicop[i]
  w("| ", key$label[i], " | ", g("dev",cc,low), " | ", g("dev",cc,high), " | ", g("developed",cc,low), " | ", g("developed",cc,high), " |")
}
w("")
w("*Notes:* means over the ", nrow(rel), " estimation-sample countries, split by weight source (Global segments = GCD 2010, ",
  n_dev, " countries; National quintiles = HBS 2020, ", n_developed,
  " countries). The low-vs-high food-share gap is the Engel gradient the paper exploits. *Source:* author's calculations from Eurostat and World Bank income-group weights.\n")

# ---- Table 2 : headline results (curated) ----------------------------------
f2 <- function(x) { x <- round(x, 2); x[x == 0] <- 0; formatC(x, format = "f", digits = 2) }
mkrow <- function(r) w("| ", str_trunc(r$name, 24), " | ", f1(r$national), " | ",
                       f1(r$low), " | ", f1(r$mid), " | ", f1(r$high), " | ", f2(r$ratio), " | ", f1(r$gap), " |")
top  <- rel |> arrange(desc(ratio)) |> slice_head(n = 15)
conv <- rel |> arrange(ratio)       |> slice_head(n = 5) |> arrange(desc(ratio))
w("## Table 2 — Cumulative inflation by income group, curated (%, 2021-01 to 2024-12)\n")
w("| Country | All-items | Low | Mid | High | Ratio (%) | Gap (low−high, pp) |")
w("|---|--:|--:|--:|--:|--:|--:|")
for (i in seq_len(nrow(top)))  mkrow(top[i, ])
w("| *(", nrow(rel) - nrow(top) - nrow(conv), " more; see App. B)* | | | | | | |")
for (i in seq_len(nrow(conv))) mkrow(conv[i, ])
w("")
w("*Summary (all ", nrow(rel), "):* the low-income basket faces the highest of the three group rates in ",
  sum(rel$highest == "low"), " of ", nrow(rel),
  " countries. Median ratio ", f2(median(rel$ratio)), "% pooled (GCD segments ", f2(median(rel$ratio[str_detect(rel$tier, "GCD")])),
  "%, HBS quintiles ", f2(median(rel$ratio[str_detect(rel$tier, "HBS")])), "%); the pooled figure mixes two income-group definitions and is a sensitivity check only. Median low−high gap ",
  f1(median(rel$gap)), " pp (dispersion, max−min, ", f1(median(rel$divergence)), " pp). Full ", nrow(rel),
  "-country table in Appendix B. *Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

# ---- Table 4 : weights-sensitivity ladder (max−min divergence) -------------
dratio <- function(df) median(((1 + pmax(df$low, df$mid, df$high) / 100) / (1 + pmin(df$low, df$mid, df$high) / 100) - 1) * 100)
mm  <- rel |> left_join(src, by = "country")
hbs <- mm |> filter(source == "HBS_2020")
w("## Table 4 — Weights-sensitivity ladder (median max−min divergence, pp)\n")
w("| Weighting | Countries | Median divergence (pp) | Median max/min ratio (%) | Low-income highest |")
w("|---|--:|--:|--:|--:|")
w("| Uniform hand-set basket (poor ≈ 60% food) | ", nrow(hnd), " | ", f1(median(hnd$divergence)),
  " | ", f2(dratio(hnd)), " | ", sum(hnd$highest=="low"), " / ", nrow(hnd), " |")
w("| **Per-country real baskets (HBS + GCD)** | **", nrow(rel), "** | **", f1(median(rel$divergence)),
  "** | **", f2(dratio(rel)), "** | **", sum(rel$highest=="low"), " / ", nrow(rel), "** |")
w("| Eurostat (national-quintile) countries, own baskets (≈ 18% food) | ", nrow(hbs), " | ", f1(median(hbs$divergence)),
  " | ", f2(dratio(hbs)), " | ", sum(hbs$highest=="low"), " / ", nrow(hbs), " |")
w("")
w("*Notes:* all three rows use max−min divergence (the metric they share); the low−high gap in Table 2 is a strictly smaller quantity. The direction holds across all three; the magnitude tracks food-share × inflation level, so the developed, low-food, low-inflation basket set collapses the gap. *Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

# ---- Table B1 (Appendix B) : full 51-country results -----------------------
full <-
  rel |> left_join(src, by = "country") |>
  mutate(tier = if_else(source == "HBS_2020", "HBS", "GCD")) |>
  arrange(desc(ratio))
w("## Table B1 (Appendix B) — Full ", nrow(full), "-country results (%, 2021-01 to 2024-12)\n")
w("| Country | Source | All-items | Low | Mid | High | Ratio (%) | Gap (low−high, pp) |")
w("|---|:--|--:|--:|--:|--:|--:|--:|")
for (i in seq_len(nrow(full))) {
  r <- full[i, ]
  w("| ", str_trunc(r$name, 26), " | ", r$tier, " | ", f1(r$national), " | ",
    f1(r$low), " | ", f1(r$mid), " | ", f1(r$high), " | ", f2(r$ratio), " | ", f1(r$gap), " |")
}
w("")
w("*Notes:* all ", nrow(full), " reliable countries, sorted by the ratio; Source = weight origin (HBS = Eurostat quintiles, GCD = World Bank segments). Armenia is excluded from the ", nrow(full), ": its World Bank Global Consumption Database \"higher\"-income basket fails the noise filter (it places an implausible share of spending on recreation), so its low/mid/high triple is untrustworthy and non-monotone (§6.3). *Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

close(out)
cat("wrote outputs/tables_1_4.md\n")
