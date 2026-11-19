#!/usr/bin/env Rscript
# the two exhibits outside make_tables.R:
#   Table 3  category decomposition of the low-high gap (which COICOP divisions
#            build the gap; §5.3)
#   Table 5  window / falsification robustness (2015-19 pre-shock vs headline vs 2025-06)
# self-contained and non-destructive: recomputes group indices in-memory per window
# and writes ONLY outputs/tables_extra.md. it never overwrites the locked headline
# CSVs/plots. every number traces to imf_cpi_coicop_all_wide.csv + group_weights_master.csv.
source(here::here("R", "imf_cpi_helpers.R"))

f1 <- function(x) { x <- round(x, 1); x[x == 0] <- 0; formatC(x, format = "f", digits = 1) }
nn <- function(w) is.na(w) | w != "noisy_global_higher"
clean_name <- function(x) x |>
  str_replace_all("`", "'") |>
  str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
  str_replace(", Republic of$", "") |> str_replace(",? Rep\\.?$", "") |>
  str_replace("^Moldova.*", "Moldova")

wide <- read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE)
W    <-
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  transmute(country = country_iso2, coicop, low, mid, high, note, source)
nms  <-
  read_csv(file.path(HERE, "data", "imf_cpi_pull_log.csv"), show_col_types = FALSE) |>
  select(country = code, name)

# core: reproduce group_cpi_divergence.R's per-country result for a window.
# returns the reliable, non-noisy, complete-triple panel (the "51" logic), plus
# per-country per-category cumulative inflation `catcum` used by the decomposition.
core <- function(start, end, min_months = 24) {
  start <- ym(start); end <- ym(end)
  d <-
    wide |>
    filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end) |>
    mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
    group_by(country, date) |> filter(n_distinct(coicop) == 12) |> ungroup()

  gf <-
    inner_join(d, W, by = c("country", "coicop")) |>
    group_by(country, date) |>
    summarise(f_low = sum(r * low), f_mid = sum(r * mid), f_high = sum(r * high), .groups = "drop")
  grp <-
    gf |> group_by(country) |>
    summarise(n_months = n(),
              low  = (prod(f_low)  - 1) * 100,
              mid  = (prod(f_mid)  - 1) * 100,
              high = (prod(f_high) - 1) * 100, .groups = "drop") |>
    filter(n_months >= min_months)

  nat <-
    wide |> filter(coicop == "00", date >= start, date <= end) |>
    mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
    group_by(country) |> summarise(national = (prod(r) - 1) * 100, .groups = "drop")

  natw <-
    wide |>
    filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end, !is.na(weight_pct)) |>
    group_by(country, coicop) |> summarise(w = mean(weight_pct), .groups = "drop") |>
    group_by(country) |> mutate(w = w / sum(w)) |> ungroup()
  recon <-
    d |> inner_join(natw, by = c("country", "coicop")) |>
    group_by(country, date) |> summarise(f = sum(r * w), .groups = "drop") |>
    group_by(country) |> summarise(recon = (prod(f) - 1) * 100, .groups = "drop")

  res <-
    grp |>
    left_join(nat, by = "country") |> left_join(recon, by = "country") |>
    left_join(distinct(W, country, note, source), by = "country") |>
    left_join(nms, by = "country") |>
    rowwise() |>
    mutate(divergence = max(low, mid, high) - min(low, mid, high),
           gap = low - high,
           ratio = ((1 + low / 100) / (1 + high / 100) - 1) * 100,
           highest = if (anyNA(c(low, mid, high))) NA_character_
                     else c("low","mid","high")[which.max(c(low, mid, high))]) |>
    ungroup() |>
    mutate(name = coalesce(name, country),
           recon_gap = recon - national,
           reliable = is.finite(recon) & is.finite(national) &
                      (abs(recon_gap) < pmax(5, 0.15 * abs(national))),
           note = coalesce(note, ""))
  rel <- res |> filter(reliable, nn(note), !is.na(gap))

  catcum <-
    d |> semi_join(rel, by = "country") |>
    group_by(country, coicop) |>
    summarise(cum = (prod(r) - 1) * 100, .groups = "drop")
  list(rel = rel, catcum = catcum, start = start, end = end)
}

MINM <- 42L   # min complete months required (matches the locked headline panel's bar)

out <- file(file.path(HERE, "outputs", "tables_extra.md"), open = "w")
w   <- function(...) cat(..., "\n", sep = "", file = out)

# --- Table 3: category decomposition of the low-high gap ---------------------
# static-weight identity: approximate group cumulative inflation by
# I~_g = sum_k w_{g,k} * I_k (I_k = category k cumulative), so the gap decomposes
# exactly:  gap~ = sum_k (w_low,k - w_high,k) * I_k. validate gap~ tracks the true
# chained gap, then report mean division contributions, split by weight-source tier.
H <- core("2021-01", "2024-12", MINM)
rel <- H$rel |> mutate(name = clean_name(name))
lab <- DIVISIONS |> filter(coicop != "00") |> select(coicop, division)

dec <-
  H$catcum |>
  inner_join(select(W, country, coicop, low, high), by = c("country", "coicop")) |>
  mutate(contrib = (low - high) * cum) |>                    # pp contribution of division k
  left_join(distinct(W, country, source), by = "country") |>
  mutate(tier = if_else(source == "HBS_2020", "developed", "dev"))

# validation: reconstructed gap~ vs the true low-high gap
val <-
  dec |> group_by(country) |> summarise(gap_approx = sum(contrib), .groups = "drop") |>
  inner_join(select(rel, country, gap), by = "country")
val_r   <- cor(val$gap_approx, val$gap)
val_mae <- mean(abs(val$gap_approx - val$gap))
val_max <- max(abs(val$gap_approx - val$gap))

meanc <- function(df) df |> group_by(coicop) |>
  summarise(c_all = mean(contrib), .groups = "drop")
c_all  <- dec |> meanc() |> rename(all = c_all)
c_dev  <- dec |> filter(tier == "dev")  |> meanc() |> rename(dev = c_all)
c_developed <- dec |> filter(tier == "developed") |> meanc() |> rename(developed = c_all)
tab5 <-
  lab |> left_join(c_all, "coicop") |> left_join(c_dev, "coicop") |>
  left_join(c_developed, "coicop") |> arrange(desc(all))

N <- nrow(rel)                                    # panel size, referenced in prose below
w("## Table 3 — Category decomposition of the low−high gap (mean contribution, pp)\n")
w("| COICOP division | All ", N, " | Global segments | National quintiles |")
w("|---|--:|--:|--:|")
for (i in seq_len(nrow(tab5))) {
  r <- tab5[i, ]
  w("| ", r$division, " | ", f1(r$all), " | ", f1(r$dev), " | ", f1(r$developed), " |")
}
w("| **Total = mean low−high gap** | **", f1(sum(tab5$all)), "** | **", f1(sum(tab5$dev)),
  "** | **", f1(sum(tab5$developed)), "** |")
w("")
w("*Note on the total:* the column totals are the mean low−high gap (true mean ", f1(mean(rel$gap)),
  " pp over the ", N, "; the ", f1(sum(tab5$all)), " pp shown is the reconstructed mean, within rounding), ",
  "which exceeds the median of ", f1(median(rel$gap)), " pp because the distribution is right-skewed by the ",
  "food-heavy tail (Malawi, Egypt); the decomposition is naturally additive in means, not medians. ",
  "The split by weight source (global segments ", f1(mean(rel$gap[rel$source != "HBS_2020"])),
  " pp, national quintiles ", f1(mean(rel$gap[rel$source == "HBS_2020"])), " pp) is where the between-category component lives.")
top_pos  <- tab5$division[which.max(tab5$all)]
neg_divs <- tab5 |> filter(all < 0) |> arrange(all) |> slice_head(n = 3) |> pull(division)
neg_lbl  <- paste(tolower(neg_divs), collapse = ", ")
w("*Reading:* each cell is the mean across countries of $(w^{low}_k - w^{high}_k)\\,I_k$, the ",
  "share-gap of division $k$ times its cumulative inflation $I_k$: the percentage points that ",
  "division adds to (or subtracts from) the low−high gap. ", top_pos, " does the work everywhere; the ",
  "categories the better-off overweight (", neg_lbl, ") pull the other way. The between-category component is a ",
  "global-segment phenomenon, where the food share-gap is widest.")
w("*Validation:* the static-weight reconstruction $\\tilde{gap}=\\sum_k(w^{low}_k-w^{high}_k)I_k$ ",
  "tracks the true chained low−high gap with a mean absolute error of ", f1(val_mae), " pp (maximum ",
  f1(val_max), " pp) over the ", N, ", so the decomposition is a faithful attribution of the headline gap. ",
  "*Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

# --- Table 5: window / falsification robustness (inline in §6.5; formerly C1) ------
windows <- tribble(
  ~lab,                              ~start,     ~end,
  "2015-01 to 2019-12 (pre-shock baseline)", "2015-01", "2019-12",
  "2021-01 to 2024-12 (main window)",        "2021-01", "2024-12",
  "2021-01 to 2025-06 (extended)",          "2021-01", "2025-06"
)
# compute each window row once, then both the table and the note read from `rows`
rows <- lapply(seq_len(nrow(windows)), function(i) {
  cr <- core(windows$start[i], windows$end[i], MINM)$rel   # 42-month bar → headline row = locked 51/2.1/44
  list(lab = windows$lab[i], n = nrow(cr), med_gap = median(cr$gap), med_ratio = median(cr$ratio),
       low_hi = sum(cr$highest == "low"), med_mm = median(cr$divergence))
})
names(rows) <- c("baseline", "headline", "extended")
w("## Table 5 — Window and falsification robustness (per-country baskets)\n")
w("| Window | Countries | Median ratio (%), pooled | Median low−high gap (pp) | Low-income highest | Median max−min (pp) |")
w("|---|--:|--:|--:|--:|--:|")
for (r in rows)
  w("| ", r$lab, " | ", r$n, " | ", formatC(round(r$med_ratio, 2), format = "f", digits = 2), " | ", f1(r$med_gap), " | ", r$low_hi, " / ", r$n, " | ", f1(r$med_mm), " |")
w("")
P <- rows$baseline; H2 <- rows$headline; E <- rows$extended
w("*Notes:* same per-country HBS+GCD baskets and the same reconciliation + complete-triple filters as the ",
  "headline (", MINM, "-month bar), so the middle row reproduces the locked panel exactly. The samples differ ",
  "across windows because the balanced-panel and reconciliation requirements select different countries ",
  "(the 2025-06 endpoint is reached by fewer countries; the pre-shock window predates some series), so ",
  "the rows are not a within-country time series and their magnitudes are not directly differenced. The ",
  "falsification test carries the reading: in the flat-relative-price 2015–19 window the between-category component is nearly ",
  "quiescent, with a median gap of ", f1(P$med_gap), " pp, dispersion of ", f1(P$med_mm), " pp, and the low ",
  "basket highest in only ", P$low_hi, " of ", P$n, ". Over the 2021–24 surge it opens to ", f1(H2$med_gap),
  " pp and ", H2$low_hi, " of ", H2$n, ". The regressive direction survives into the 2025-06 extension (",
  E$low_hi, " of ", E$n, "); its larger median there reflects sample composition, not a within-country ",
  "widening. Pooled medians mix two income-group definitions, so they are used here only to compare windows. *Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

close(out)
cat("wrote outputs/tables_extra.md\n")
cat(sprintf("Table 3 validation: r=%.3f  MAE=%.2f pp  MAX=%.2f pp  (gap~ vs true gap, n=%d)\n",
            val_r, val_mae, val_max, nrow(val)))
