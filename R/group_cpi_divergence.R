#!/usr/bin/env Rscript
# the core experiment: do income groups face different inflation because their
# baskets differ (low ~60% food, high ~25% food + services)? apply per-country
# (or one hand-set) group baskets to every country's category price paths and
# measure the cumulative low/mid/high gap over a fixed window.
#   monthly factor_g = sum_k w_{g,k} * r_{k,t}   (r = 1 + MoM%/100, Σw = 1)
#   group inflation_g = prod_t(factor_g) - 1     over the window
#   divergence = max(low,mid,high) - min(low,mid,high)   per country, in pp
# usage:  Rscript R/group_cpi_divergence.R [START YYYY-MM] [END YYYY-MM] [MIN_MONTHS] [handset|master]
#   default 2021-01 .. 2024-12 (the inflation surge), require >=42/48 months
source(here::here("R", "imf_cpi_helpers.R"))
suppressPackageStartupMessages(library(ggrepel))

# tidy country names for figures (matches make_tables.R)
clean_name <- function(x) x |>
  str_replace_all("`", "'") |>
  str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
  str_replace(", Republic of$", "") |>
  str_replace(",? Rep\\.?$", "") |>
  str_replace("^Moldova.*", "Moldova")

args       <- commandArgs(trailingOnly = TRUE)
start      <- ym(ifelse(length(args) >= 1, args[1], "2021-01"))
end        <- ym(ifelse(length(args) >= 2, args[2], "2024-12"))
min_months <- as.integer(ifelse(length(args) >= 3, args[3], "42"))
wmode      <- ifelse(length(args) >= 4, args[4], "handset")   # "handset" | "master"
tag        <- ifelse(wmode == "handset", "", paste0("_", wmode))

if (wmode == "master") {
  mpath <- file.path(HERE, "data", "group_weights_master.csv")
  if (!file.exists(mpath)) stop("run R/build_group_weights_master.R first")
  W <-
    read_csv(mpath, show_col_types = FALSE) |>
    transmute(country = country_iso2, coicop, low, mid, high, note)
  cat("weights: per-country master (HBS+GCD)\n")
} else {
  W <- GROUP_WEIGHTS |> mutate(note = "")          # single basket, broadcast in the join
  cat("weights: hand-set single basket (Σw=1)\n")
}

wide_path <- file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv")
if (!file.exists(wide_path)) stop("run R/pull_imf_cpi_all.R first (missing ", wide_path, ")")
wide <- read_csv(wide_path, show_col_types = FALSE)
names <- if (file.exists(file.path(HERE, "data", "imf_cpi_pull_log.csv")))
  read_csv(file.path(HERE, "data", "imf_cpi_pull_log.csv"), show_col_types = FALSE) |>
    select(country = code, name) else tibble(country = character(), name = character())

cat(sprintf("window %s .. %s  (require >= %d months, all 12 divisions present)\n",
            format(start), format(end), min_months))

d <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end) |>
  mutate(r = 1 + mom_pct / 100) |>
  filter(!is.na(r)) |>
  group_by(country, date) |>
  filter(n_distinct(coicop) == 12) |>          # keep only complete-12 months
  ungroup()

gf <-
  (if (wmode == "master")
     inner_join(d, W, by = c("country", "coicop"))
   else
     left_join(d, select(W, -note), by = "coicop")) |>
  group_by(country, date) |>
  summarise(f_low = sum(r * low), f_mid = sum(r * mid), f_high = sum(r * high), .groups = "drop")

grp <-
  gf |>
  group_by(country) |>
  summarise(n_months = n(),
            low  = (prod(f_low)  - 1) * 100,
            mid  = (prod(f_mid)  - 1) * 100,
            high = (prod(f_high) - 1) * 100, .groups = "drop") |>
  filter(n_months >= min_months)

nat <-
  wide |>
  filter(coicop == "00", date >= start, date <= end) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  group_by(country) |>
  summarise(national = (prod(r) - 1) * 100, .groups = "drop")

# reconciliation: rebuild all-items from the 12 divisions with each country's OWN
# official weights. if it doesn't match, the division data is broken (rebasing /
# base-period break) and the country is dropped as unreliable below.
natw <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end, !is.na(weight_pct)) |>
  group_by(country, coicop) |> summarise(w = mean(weight_pct), .groups = "drop") |>
  group_by(country) |> mutate(w = w / sum(w)) |> ungroup()           # normalise Σw=1
recon <-
  d |>
  inner_join(natw, by = c("country", "coicop")) |>
  group_by(country, date) |> summarise(f = sum(r * w), .groups = "drop") |>
  group_by(country) |> summarise(recon = (prod(f) - 1) * 100, .groups = "drop")

res <-
  grp |>
  left_join(nat,   by = "country") |>
  left_join(recon, by = "country") |>
  left_join(names, by = "country") |>
  rowwise() |>
  mutate(divergence = max(low, mid, high) - min(low, mid, high),
         gap        = low - high,                                # HEADLINE: signed low-vs-high (pp)
         mean_grp   = mean(c(low, mid, high)),
         rel_div    = divergence / pmax(1, abs(mean_grp)) * 100,   # % of group level
         # direction is undefined if any group basket is missing: which.max/which.min
         # silently skip NA and would pick a "highest" from an incomplete triple. Force NA.
         highest    = if (anyNA(c(low, mid, high))) NA_character_
                      else c("low", "mid", "high")[which.max(c(low, mid, high))],
         lowest     = if (anyNA(c(low, mid, high))) NA_character_
                      else c("low", "mid", "high")[which.min(c(low, mid, high))]) |>
  ungroup() |>
  mutate(name = coalesce(name, country),
         # reliable = reconstruction within 5pp or 15% of official all-items
         recon_gap = recon - national,
         reliable  = is.finite(recon) & is.finite(national) &
                     (abs(recon_gap) < pmax(5, 0.15 * abs(national)))) |>
  left_join(if (wmode == "master") distinct(W, country, note)
            else tibble(country = character(), note = character()), by = "country") |>
  mutate(note = coalesce(note, "")) |>
  arrange(desc(divergence)) |>
  select(country, name, n_months, reliable, national, recon, recon_gap,
         low, mid, high, gap, divergence, rel_div, highest, lowest, wsource = note)

write_csv(res, file.path(HERE, "outputs", paste0("group_cpi_divergence", tag, ".csv")))
rel <- res |> filter(reliable, wsource != "noisy_global_higher", !is.na(divergence))

# --- report ------------------------------------------------------------------
cat(sprintf("\ncountries qualifying: %d   of which RELIABLE (reconcile to all-items): %d\n",
            nrow(res), nrow(rel)))
cat("\n=== divergence (max-min of low/mid/high), pp — RELIABLE countries ===\n")
print(round(summary(rel$divergence), 2))
cat(sprintf("  >3pp: %d   >5pp: %d   >10pp: %d   (of %d reliable)\n",
            sum(rel$divergence > 3), sum(rel$divergence > 5), sum(rel$divergence > 10), nrow(rel)))
cat(sprintf("  RELATIVE divergence (%% of group level): median %.1f%%  mean %.1f%%  max %.1f%%\n",
            median(rel$rel_div), mean(rel$rel_div), max(rel$rel_div)))
cat(sprintf("  which group is highest most often: %s\n",
            paste(names(sort(table(rel$highest), decreasing = TRUE)),
                  sort(table(rel$highest), decreasing = TRUE), sep = "=", collapse = "  ")))

cat("\n=== TOP 15 by ABSOLUTE divergence (reliable only) ===\n")
rel |> arrange(desc(divergence)) |> slice_head(n = 15) |>
  transmute(name = str_trunc(name, 22), national = round(national, 1),
            low = round(low, 1), mid = round(mid, 1), high = round(high, 1),
            div_pp = round(divergence, 1), rel = round(rel_div, 1), highest) |>
  as.data.frame() |> print(row.names = FALSE)

cat("\n=== TOP 15 by RELATIVE divergence (reliable only) ===\n")
rel |> arrange(desc(rel_div)) |> slice_head(n = 15) |>
  transmute(name = str_trunc(name, 22), national = round(national, 1),
            low = round(low, 1), mid = round(mid, 1), high = round(high, 1),
            div_pp = round(divergence, 1), rel = round(rel_div, 1), highest) |>
  as.data.frame() |> print(row.names = FALSE)

cat("\n=== 12 most CONVERGENT (reliable, smallest relative gap) ===\n")
rel |> arrange(rel_div) |> slice_head(n = 12) |>
  transmute(name = str_trunc(name, 22), national = round(national, 1),
            low = round(low, 1), mid = round(mid, 1), high = round(high, 1),
            div_pp = round(divergence, 2), rel = round(rel_div, 2)) |>
  as.data.frame() |> print(row.names = FALSE)

cat("\n=== DROPPED as unreliable (division data doesn't reconcile to all-items) ===\n")
res |> filter(!reliable) |> arrange(desc(abs(recon_gap))) |> slice_head(n = 12) |>
  transmute(name = str_trunc(name, 22), national = round(national, 1),
            recon = round(recon, 1), recon_gap = round(recon_gap, 1)) |>
  as.data.frame() |> print(row.names = FALSE)

# --- figures (reliable countries only) ---------------------------------------
# headline metric is the absolute low-minus-high gap (pp); the relative metric is
# noisy on low-inflation bases, so it stays in the CSV and out of the figures
gmed <- median(rel$gap)
npos <- sum(rel$gap > 0)
tail3    <- rel |> arrange(desc(gap)) |> slice_head(n = 3)
tail_lbl <- paste0("right tail: ",
                   paste(sprintf("%s (%.0f)", str_trunc(tail3$name, 18), tail3$gap),
                         collapse = ", "))
basket_desc <- if (wmode == "master") "Per-country income baskets" else "Uniform hand-set basket"

SRC <- paste0("Source: IMF category CPI; income-group weights from Eurostat HBS and the World Bank\n",
              "Global Consumption Database. Author's calculations.")

# Fig 1: distribution of the low-minus-high gap across countries
nneg <- sum(rel$gap < 0)
p1 <- ggplot(rel, aes(gap)) +
  geom_histogram(bins = 35, fill = "#1F78B4", alpha = 0.85) +
  geom_vline(xintercept = 0, colour = "grey55") +
  geom_vline(xintercept = gmed, linetype = "dashed") +
  annotate("text", x = gmed, y = Inf,
           label = sprintf("median %.1f pp", gmed), hjust = -0.08, vjust = 1.6, size = 3.1) +
  annotate("text", x = 0, y = Inf, label = "0",
           hjust = 1.3, vjust = 1.6, size = 3.1, colour = "grey45") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  labs(title = sprintf("Low- minus high-income basket inflation gap, %d countries, %s–%s",
                       nrow(rel), format(start, "%Y"), format(end, "%Y")),
       subtitle = sprintf("%s; low-income basket higher in %d of %d countries (%d below zero)",
                          basket_desc, npos, nrow(rel), nneg),
       x = "cumulative low-income minus high-income inflation (pp)", y = "countries",
       caption = paste0("Right tail (off the mass): ",
                        paste(sprintf("%s %.0f pp", clean_name(tail3$name), tail3$gap), collapse = ", "),
                        ".\n", SRC)) +
  theme_minimal() +
  theme(plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))
save_fig(p1, paste0("group_cpi_divergence_hist", tag), width = 8.5, height = 4.5, dpi = 150)

# Fig 2: dumbbell, top-20 by absolute gap, low vs mid vs high cumulative inflation.
# hyperinflation outliers (all-items > 300%, e.g. Türkiye 432%) are dropped from the
# plot, or a single 450% level crushes every other dumbbell into a clump; they still
# appear in the caption and Table 3 / B1.
OUTLIER_CUT <- 300
outl  <- rel |> filter(national > OUTLIER_CUT) |> arrange(desc(gap))
topn <- rel |> filter(national <= OUTLIER_CUT) |> arrange(desc(gap)) |> slice_head(n = 20) |>
  mutate(name = fct_reorder(clean_name(name), gap))
topl <-
  topn |>
  select(name, gap, Low = low, Middle = mid, High = high) |>
  pivot_longer(c(Low, Middle, High), names_to = "grp", values_to = "infl") |>
  mutate(grp = factor(grp, levels = c("Low", "Middle", "High")))
grp_cols <- c(Low = "#E31A1C", Middle = "#1F78B4", High = "#33A02C")
outl_note <- if (nrow(outl))
  sprintf("Excluded for scale: %s. See Table 3 / B1.",
          paste(sprintf("%s (%.0f%% cumulative, %.1f pp gap)",
                        clean_name(outl$name), outl$national, outl$gap), collapse = "; ")) else NULL
p2 <- ggplot(topn, aes(y = name)) +
  geom_segment(aes(x = high, xend = low, yend = name), colour = "grey70", linewidth = 0.9) +
  geom_point(data = topl, aes(x = infl, colour = grp, shape = grp), size = 2.6) +
  geom_text(aes(x = low, label = sprintf("+%.0f", gap)), hjust = -0.35, size = 2.7, colour = "grey30") +
  scale_colour_manual(values = grp_cols, name = "Income group") +
  scale_shape_manual(values = c(Low = 16, Middle = 17, High = 16), name = "Income group") +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.10))) +
  labs(title = "The twenty largest basket gaps: low vs middle vs high cumulative inflation",
       subtitle = sprintf("%s, %s–%s; label = low−high gap (pp)",
                          basket_desc, format(start, "%Y"), format(end, "%Y")),
       x = "cumulative group inflation (%)", y = NULL,
       caption = paste(c(outl_note, SRC), collapse = "\n")) +
  theme_minimal() +
  theme(legend.position = "top", plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))
save_fig(p2, paste0("group_cpi_divergence_top20", tag), width = 8.5, height = 6, dpi = 150)

# Fig 3: food-price excess vs the group gap (the r≈0.85 mechanism)
food <-
  d |> filter(coicop == "01") |>
  group_by(country) |> summarise(food = (prod(r) - 1) * 100, .groups = "drop")
mech <-
  rel |> left_join(food, by = "country") |>
  mutate(food_excess = food - national) |> filter(is.finite(food_excess))
rmech   <- cor(mech$food_excess, mech$gap, use = "complete.obs")
mech_in <- mech |> filter(national <= OUTLIER_CUT)               # ex-hyperinflation outlier(s)
rmech_x <- cor(mech_in$food_excess, mech_in$gap, use = "complete.obs")
drop_nm <- mech |> filter(national > OUTLIER_CUT) |> arrange(desc(national)) |> pull(name) |> clean_name()
drop_lbl <- if (length(drop_nm)) paste(drop_nm, collapse = ", ") else "none"
# only label the points the prose names: big movers, Türkiye, the reversals
lab_hi  <- mech |> arrange(desc(gap)) |> slice_head(n = 3)
lab_neg <- mech |> filter(gap < -0.5) |> arrange(gap) |> slice_head(n = 2)
lab_tr  <- mech |> filter(national > 300)
labs_df <-
  bind_rows(lab_hi, lab_neg, lab_tr) |> distinct(country, .keep_all = TRUE) |>
  mutate(name = clean_name(name))
p3 <- ggplot(mech, aes(food_excess, gap)) +
  geom_hline(yintercept = 0, colour = "grey80") +
  geom_smooth(method = "lm", se = FALSE, colour = "grey45", linewidth = 0.6) +
  geom_smooth(data = mech_in, method = "lm", se = FALSE, colour = "#E31A1C",
              linetype = "dashed", linewidth = 0.6) +
  geom_point(alpha = 0.6, colour = "#1F78B4") +
  geom_text_repel(data = labs_df, aes(label = name), size = 2.9, colour = "grey25",
                  min.segment.length = 0, box.padding = 0.5, max.overlaps = Inf, seed = 1) +
  labs(title = "Low−high inflation gap versus food-price excess",
       subtitle = sprintf("Pearson r = %.2f across all %d; %.2f excluding %s (grey = all-%d fit, red dashed = ex-%s)",
                          rmech, nrow(mech), rmech_x, drop_lbl, nrow(mech), drop_lbl),
       x = "food inflation minus national all-items (pp)",
       y = "low-income minus high-income gap (pp)", caption = SRC) +
  theme_minimal() +
  theme(plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))
save_fig(p3, paste0("group_cpi_divergence_mechanism", tag), width = 8.5, height = 5, dpi = 150)

# (Fig 3b vs_level dropped 2026-07-19: on the low−high metric it shows r≈0.53, i.e.
#  absolute pp gaps mechanically scale with the inflation level, no longer the ≈0 null
#  it was on relative divergence. Fig 3's food-excess 0.71 vs level 0.53 makes the
#  "it's the basket, not just the level" point, so the level scatter lost its slot.)

# Fig 4: world choropleth of the gap (optional; needs sf + rnaturalearth[data])
have_map <- all(vapply(c("sf", "rnaturalearth", "rnaturalearthdata", "countrycode"),
                       requireNamespace, logical(1), quietly = TRUE))
if (have_map) {
  world <-
    rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") |>
    dplyr::filter(continent != "Antarctica")            # tighter frame
  # ISO-3 with a name fallback: Namibia's ISO-2 is literally "NA" -> parsed as
  # missing, so iso2c->iso3c yields NA; recover it (and any other) from the name.
  mapd  <-
    rel |>
    mutate(iso_a3 = dplyr::coalesce(
             countrycode::countrycode(country, "iso2c",        "iso3c", warn = FALSE),
             countrycode::countrycode(name,    "country.name", "iso3c", warn = FALSE))) |>
    filter(!is.na(iso_a3)) |> select(iso_a3, gap)
  # iso_a3_eh is the completeness-fixed ISO-3 (France/Norway/etc. carry -99 in iso_a3)
  wm <- dplyr::left_join(world, mapd, by = c("iso_a3_eh" = "iso_a3"))
  p4 <- ggplot(wm) +
    geom_sf(aes(fill = gap), colour = "white", linewidth = 0.1) +
    # blue = high-income basket hit harder (gap<0); red = low-income hit harder (gap>0);
    # near-white = in-sample ~0; distinct muted grey = country not in the sample.
    scale_fill_gradient2(low = "#2166AC", mid = "#f7f7f7", high = "#B2182B",
                         midpoint = 0, na.value = "grey78", name = "low−high\ngap (pp)") +
    coord_sf(crs = "+proj=robin") +
    labs(title = sprintf("Low- minus high-income inflation gap by country, %s–%s",
                         format(start, "%Y"), format(end, "%Y")),
         subtitle = sprintf("low-income minus high-income cumulative inflation (pp), %d countries; grey = not in sample", nrow(mapd))) +
    theme_void()
  save_fig(p4, paste0("group_cpi_divergence_map", tag), width = 8.5, height = 5, dpi = 150)
}

cat("\nsaved: outputs/group_cpi_divergence", tag, ".csv, plots/{png,tiff}/group_cpi_divergence_{hist,top20,mechanism",
    if (have_map) ",map" else "", "}", tag, ".{png,tif}\n", sep = "")
if (!have_map) cat("map skipped — install.packages(c('sf','rnaturalearth','rnaturalearthdata'))\n")
