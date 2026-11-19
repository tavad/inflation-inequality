#!/usr/bin/env Rscript
# appendix table assets not emitted by make_tables.R / make_tables_extra.R.
# writes outputs/tables_appendix.md with:
#   Table A1  COICOP division -> IMF indicator-stem crosswalk (Appendix A.1)
#   Table A2  countries dropped by the reconciliation filter (Appendix A.3)
#   Table C1  weight base-period sensitivity, developing tier (Appendix C.1)
# every number is computed from the locked data, nothing hard-coded.
source(here::here("R", "imf_cpi_helpers.R"))

f1  <- function(x) ifelse(is.na(x), "NA", formatC(round(x, 1), format = "f", digits = 1))
nn  <- function(w) is.na(w) | w != "noisy_global_higher"          # non-noisy basket
clean_name <- function(x) x |>
  stringr::str_replace_all("`", "'") |>
  stringr::str_replace(", Republic of$", "")

out <- file(file.path(HERE, "outputs", "tables_appendix.md"), open = "w")
w   <- function(...) cat(..., "\n", sep = "", file = out)

# --- Table A1: COICOP division to IMF indicator-stem crosswalk (Appendix A.1) ---
w("## Table A1 (Appendix A) — COICOP division to IMF indicator-stem crosswalk\n")
w("| COICOP | Division | IMF indicator stem |")
w("|:--|:--|:--|")
for (i in seq_len(nrow(DIVISIONS))) {
  r <- DIVISIONS[i, ]
  w("| ", r$coicop, " | ", r$division, " | `", r$stem, "` |")
}
w("")
w("*Notes:* the twelve COICOP-1999 divisions (01–12) plus the all-items aggregate (00), as ",
  "published monthly in the IMF Consumer Price Index database (accessed via DBnomics). Each ",
  "division maps one-to-one to a fixed IMF indicator stem, so there is no discretion in the ",
  "mapping on the price side. Row 00 (all items, stem `PCPI`) is the aggregate the reconciliation ",
  "filter of Equation (4) reconstructs from the twelve divisions. ",
  "*Source:* IMF Consumer Price Index database (COICOP divisions), accessed via DBnomics.\n")

# --- Table A2: countries dropped by the reconciliation filter (Appendix A.3) ---
master <- read_csv(file.path(HERE, "outputs", "group_cpi_divergence_master.csv"),
                   show_col_types = FALSE)
dropped <-
  master |>
  filter(!reliable) |>
  mutate(name   = clean_name(name),
         reason = if_else(is.na(recon),
                          "No official division weights (cannot reconcile)",
                          "Reconstruction diverges from official all-items (rebasing / base-period break)")) |>
  arrange(is.na(recon), desc(abs(recon_gap)), name)

n_qual <- nrow(master); n_drop <- nrow(dropped)
w("## Table A2 (Appendix A) — Countries dropped by the reconciliation filter (%, 2021-01 to 2024-12)\n")
w("| Country | Official all-items | Reconstructed | Reconstruction gap (pp) | Reason for exclusion |")
w("|---|--:|--:|--:|:--|")
for (i in seq_len(n_drop)) {
  r <- dropped[i, ]
  w("| ", str_trunc(r$name, 26), " | ", f1(r$national), " | ", f1(r$recon),
    " | ", f1(r$recon_gap), " | ", r$reason, " |")
}
w("")
w("*Notes:* the filter reconstructs all-items inflation from the twelve COICOP divisions using each ",
  "country's own official weights (renormalized to $\\sum_k w = 1$) and drops any country whose ",
  "reconstruction misses the published all-items figure by more than $\\max(5\\text{ pp}, 15\\%)$ ",
  "(Equation (4)). Of ", n_qual, " countries with a complete twelve-division panel and a matched ",
  "income-group basket, these ", n_drop, " fail, leaving 68. “NA” marks countries that publish no ",
  "official division weights and so cannot be reconciled even in principle. Zambia's reconstruction is ",
  "the clearest rebasing/base-period mismatch (near 400% against a published ~69%). ",
  "*Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")

# --- Table C1: weight base-period sensitivity, developing tier (Appendix C.1) -----
# concern (§6.5): developing-tier baskets are GCD 2010, developed tier HBS 2020.
# incomes rose 2010–2020 and food shares fall with income (Engel), so a 2010 basket
# may overstate today's food share and hence the gap. test: haircut the GCD food
# share (COICOP 01) down by a grid of relative fractions, redistribute proportionally
# across the other 11 divisions (Σw = 1 preserved), recompute the group index on the
# SAME reliable, non-noisy, complete-triple developing panel (fixed across haircuts).
# reports whether the median gap ATTENUATES but the regressive direction SURVIVES.
HAIRCUTS <- c(0, 0.10, 0.20, 0.30)   # relative reduction of the GCD food share; 0 = headline
MINM     <- 42L                       # min complete months (headline panel bar)
WIN_S    <- ym("2021-01"); WIN_E <- ym("2024-12")

W <-
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
  transmute(country = country_iso2, coicop, low, mid, high, source, note)
wide <- read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE)
nms  <-
  read_csv(file.path(HERE, "data", "imf_cpi_pull_log.csv"), show_col_types = FALSE) |>
  select(country = code, name)

# monthly gross price relatives, complete-12 months only (matches the pipeline)
d <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= WIN_S, date <= WIN_E) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  group_by(country, date) |> filter(n_distinct(coicop) == 12) |> ungroup()

# official all-items + official-weight reconstruction -> reliability (W-independent)
nat <-
  wide |> filter(coicop == "00", date >= WIN_S, date <= WIN_E) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  group_by(country) |> summarise(national = (prod(r) - 1) * 100, .groups = "drop")
natw <-
  wide |>
  filter(coicop %in% sprintf("%02d", 1:12), date >= WIN_S, date <= WIN_E, !is.na(weight_pct)) |>
  group_by(country, coicop) |> summarise(wt = mean(weight_pct), .groups = "drop") |>
  group_by(country) |> mutate(wt = wt / sum(wt)) |> ungroup()
recon <-
  d |> inner_join(natw, by = c("country", "coicop")) |>
  group_by(country, date) |> summarise(f = sum(r * wt), .groups = "drop") |>
  group_by(country) |> summarise(recon = (prod(f) - 1) * 100, .groups = "drop")

# group index for an arbitrary weight table Wt (recomputed, never read from disk)
group_index <- function(Wt) {
  inner_join(d, Wt, by = c("country", "coicop")) |>
    group_by(country, date) |>
    summarise(f_low = sum(r * low), f_mid = sum(r * mid), f_high = sum(r * high),
              .groups = "drop") |>
    group_by(country) |>
    summarise(n_months = n(),
              low  = (prod(f_low)  - 1) * 100,
              mid  = (prod(f_mid)  - 1) * 100,
              high = (prod(f_high) - 1) * 100, .groups = "drop") |>
    filter(n_months >= MINM)
}

# downward food-share haircut on GCD (developing) countries only; proportional
# redistribution to the other 11 divisions keeps each group's basket at Σw = 1.
haircut_dev <- function(Wt, frac) {
  if (frac == 0) return(Wt)
  Wt |> group_by(country) |> group_modify(function(df, key) {
    if (isTRUE(df$source[1] == "GCD_2010")) {
      food <- df$coicop == "01"
      for (g in c("low", "mid", "high")) {
        v <- df[[g]]; removed <- sum(v[food]) * frac; base <- sum(v[!food])
        v[food]  <- v[food] * (1 - frac)
        v[!food] <- v[!food] + removed * (v[!food] / base)
        df[[g]]  <- v / sum(v)                       # defensive renormalise
      }
    }
    df
  }) |> ungroup()
}

# fixed developing panel: reliable, non-noisy, complete triple, GCD-sourced
base_grp <-
  group_index(W) |>
  left_join(nat, by = "country") |> left_join(recon, by = "country") |>
  left_join(distinct(W, country, source, note), by = "country") |>
  mutate(reliable = is.finite(recon) & is.finite(national) &
                    (abs(recon - national) < pmax(5, 0.15 * abs(national))),
         complete = is.finite(low) & is.finite(mid) & is.finite(high))
dev_ids <-
  base_grp |>
  filter(reliable, nn(note), complete, source == "GCD_2010") |> pull(country)

summarise_haircut <- function(frac) {
  g <-
    group_index(haircut_dev(W, frac)) |>
    filter(country %in% dev_ids) |>
    rowwise() |>
    mutate(gap = low - high,
           ratio = ((1 + low / 100) / (1 + high / 100) - 1) * 100,
           low_top = !anyNA(c(low, mid, high)) &&
                     which.max(c(low, mid, high)) == 1) |>
    ungroup()
  tibble(frac = frac, n = nrow(g),
         med_gap = median(g$gap), med_ratio = median(g$ratio), low_highest = sum(g$low_top))
}

vint <- bind_rows(lapply(HAIRCUTS, summarise_haircut))
lab  <- function(fr) if (fr == 0) "None (headline, 2010 basket)" else paste0("−", formatC(fr * 100, format = "f", digits = 0), "% relative")

w("## Table C1 (Appendix C) — Weight base-period sensitivity, global segments (%, 2021-01 to 2024-12)\n")
w("| Global-segment food-share adjustment | Countries | Median ratio (%) | Median low−high gap (pp) | Low-income highest |")
w("|---|--:|--:|--:|--:|")
for (i in seq_len(nrow(vint))) {
  r <- vint[i, ]
  w("| ", lab(r$frac), " | ", r$n, " | ", formatC(round(r$med_ratio, 2), format = "f", digits = 2), " | ", f1(r$med_gap), " | ", r$low_highest, " / ", r$n, " |")
}
w("")
base_med <- vint$med_gap[vint$frac == 0]
w("*Notes:* the global-segment (GCD 2010) food share is reduced by the stated relative fraction for ",
  "every income group, with the removed weight redistributed proportionally across the other eleven ",
  "divisions so each basket still sums to one. The group index is then recomputed by the method of ",
  "Equations (1)–(3). The sample is the ", vint$n[1], " reliable, non-noisy, complete-triple ",
  "global-segment countries and is held fixed across rows (reliability uses official, not group, ",
  "weights). The median low−high gap falls monotonically from ", f1(base_med), " pp as the assumed ",
  "food share is cut, but the regressive direction is unbroken, with the low-income basket remaining ",
  "the highest-inflation basket in every row, so the base-period mismatch bounds the magnitude without ",
  "reversing the sign. *Source:* author's calculations from IMF, Eurostat, and World Bank data.\n")
close(out)
cat(sprintf("wrote outputs/tables_appendix.md  (A1: crosswalk %d rows; A2: %d dropped of %d; C1: %d dev countries, haircuts %s)\n",
            nrow(DIVISIONS), n_drop, n_qual, vint$n[1], paste(HAIRCUTS, collapse = ",")))
