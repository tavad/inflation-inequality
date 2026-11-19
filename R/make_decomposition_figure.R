#!/usr/bin/env Rscript
# candidate for BODY Figure 4: same category decomposition as Table 4 in
# make_tables_extra.R, i.e. each COICOP division's mean contribution (pp) to the
# low-high gap, (w_low,k - w_high,k) * I_k, split by tier (Developing = GCD,
# Developed = HBS_2020). recomputes in-memory and writes ONLY plots/gap_decomposition;
# reuses make_tables_extra.R's core so the figure and Table 4 can't drift apart.
source(here::here("R", "imf_cpi_helpers.R"))
suppressPackageStartupMessages(library(ggplot2))

f1  <- function(x) formatC(round(x, 1), format = "f", digits = 1)
nn  <- function(w) is.na(w) | w != "noisy_global_higher"

wide <- read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE)
W    <-
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  transmute(country = country_iso2, coicop, low, mid, high, note, source)

# core: reproduce the "51" reliable panel + per-category cumulative inflation
core <- function(start, end, min_months = 42L) {
  start <- ym(start); end <- ym(end)
  d <-
    wide |>
    filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end) |>
    mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
    group_by(country, date) |> filter(n_distinct(coicop) == 12) |> ungroup()
  gf <-
    inner_join(d, W, by = c("country", "coicop")) |>
    group_by(country, date) |>
    summarise(f_low = sum(r * low), f_high = sum(r * high), .groups = "drop")
  grp <-
    gf |> group_by(country) |>
    summarise(n_months = n(),
              low  = (prod(f_low)  - 1) * 100,
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
    mutate(gap = low - high, recon_gap = recon - national,
           reliable = is.finite(recon) & is.finite(national) &
                      (abs(recon_gap) < pmax(5, 0.15 * abs(national))),
           note = coalesce(note, ""))
  rel <- res |> filter(reliable, nn(note), !is.na(gap))
  catcum <-
    d |> semi_join(rel, by = "country") |>
    group_by(country, coicop) |> summarise(cum = (prod(r) - 1) * 100, .groups = "drop")
  list(rel = rel, catcum = catcum)
}

H   <- core("2021-01", "2024-12", 42L)
rel <- H$rel
lab <- DIVISIONS |> filter(coicop != "00") |> select(coicop, division)

dec <-
  H$catcum |>
  inner_join(select(W, country, coicop, low, high), by = c("country", "coicop")) |>
  mutate(contrib = (low - high) * cum) |>
  left_join(distinct(W, country, source), by = "country") |>
  mutate(tier = if_else(source == "HBS_2020", "National quintiles", "Global segments"))

# validation (same as Table 4)
val <-
  dec |> group_by(country) |> summarise(gap_approx = sum(contrib), .groups = "drop") |>
  inner_join(select(rel, country, gap), by = "country")
val_mae <- mean(abs(val$gap_approx - val$gap))
val_max <- max(abs(val$gap_approx - val$gap))
N       <- nrow(rel)

c_all <- dec |> group_by(coicop) |> summarise(all = mean(contrib), .groups = "drop")   # for ordering
c_by  <- dec |> group_by(coicop, tier) |> summarise(mean_c = mean(contrib), .groups = "drop")

plotdat <-
  c_by |>
  inner_join(lab, by = "coicop") |>
  inner_join(c_all, by = "coicop") |>
  mutate(dlab = paste0(coicop, " ", str_trunc(division, 34)),
         dlab = fct_reorder(dlab, all),
         tier = factor(tier, levels = c("Global segments", "National quintiles")))
TIER_COLS <- c("Global segments" = "#E6550D", "National quintiles" = "#1F78B4")

p <- ggplot(plotdat, aes(mean_c, dlab, fill = tier)) +
  geom_col(position = position_dodge(width = 0.68), width = 0.62, alpha = 0.9) +
  geom_vline(xintercept = 0, colour = "grey55") +
  scale_fill_manual(values = TIER_COLS, name = NULL) +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  labs(title = "Which categories build the low−high inflation gap",
       subtitle = sprintf("Mean contribution per COICOP division, %d countries, 2021–2024", N),
       x = "contribution to the low−high cumulative gap (pp)", y = NULL,
       caption = paste0(
         "Each bar is the mean of (w_low − w_high) × cumulative inflation for that division. Food (01) does the\n",
         "work, especially among the global-segment countries; transport, restaurants and recreation, which the better-off\n",
         sprintf("overweight, pull the other way. Static-weight reconstruction tracks the chained gap within %s pp on average (%s pp at most).\n", f1(val_mae), f1(val_max)),
         "Source: IMF category CPI; income-group weights from Eurostat HBS and the World Bank Global\n",
         "Consumption Database. Author's calculations.")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        panel.grid.major.y = element_blank(),
        plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))

save_fig(p, "gap_decomposition", width = 8.5, height = 5.9, dpi = 150)
cat(sprintf("wrote plots/{png,tiff}/gap_decomposition  (panel N=%d, MAE=%.2f pp, max=%.2f pp)\n", N, val_mae, val_max))
