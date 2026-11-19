source(here::here("R", "imf_cpi_helpers.R"))
suppressPackageStartupMessages(library(countrycode))

REV_OUT <- file.path(HERE, "outputs", "revision")
REV_DAT <- file.path(HERE, "data", "revision")
dir.create(REV_OUT, showWarnings = FALSE, recursive = TRUE)
dir.create(REV_DAT, showWarnings = FALSE, recursive = TRUE)

START      <- ym("2021-01")
END        <- ym("2024-12")
MIN_MONTHS <- 42L

fix_na_iso <- function(df, col = country) mutate(df, {{ col }} := coalesce({{ col }}, "NA"))

ratio_pct <- function(pl, ph) ((1 + pl / 100) / (1 + ph / 100) - 1) * 100

load_prices <- function(start = START, end = END) {
  wide <-
    read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE) |>
    fix_na_iso()
  d <-
    wide |>
    filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end) |>
    mutate(r = 1 + mom_pct / 100) |>
    filter(!is.na(r)) |>
    group_by(country, date) |>
    filter(n_distinct(coicop) == 12) |>
    ungroup() |>
    select(country, coicop, date, r)
  nat <-
    wide |>
    filter(coicop == "00", date >= start, date <= end) |>
    mutate(r = 1 + mom_pct / 100) |>
    filter(!is.na(r)) |>
    group_by(country) |>
    summarise(national = (prod(r) - 1) * 100, .groups = "drop")
  natw <-
    wide |>
    filter(coicop %in% sprintf("%02d", 1:12), date >= start, date <= end, !is.na(weight_pct)) |>
    group_by(country, coicop) |>
    summarise(w = mean(weight_pct), .groups = "drop") |>
    group_by(country) |>
    mutate(w = w / sum(w)) |>
    ungroup()
  recon <-
    d |>
    inner_join(natw, by = c("country", "coicop")) |>
    group_by(country, date) |>
    summarise(f = sum(r * w), .groups = "drop") |>
    group_by(country) |>
    summarise(recon = (prod(f) - 1) * 100, .groups = "drop")
  rel <-
    d |>
    count(country, date) |>
    count(country, name = "n_months") |>
    left_join(nat, by = "country") |>
    left_join(recon, by = "country") |>
    mutate(recon_gap = recon - national,
           reliable  = is.finite(recon) & is.finite(national) &
                       abs(recon_gap) < pmax(5, 0.15 * abs(national)))
  list(d = d, nat = nat, natw = natw, rel = rel)
}

group_infl <- function(d, W, groups = c("low", "mid", "high")) {
  d |>
    inner_join(W, by = c("country", "coicop")) |>
    group_by(country, date) |>
    summarise(across(all_of(groups), ~ sum(r * .x)), .groups = "drop") |>
    group_by(country) |>
    summarise(n_months = n(), across(all_of(groups), ~ (prod(.x) - 1) * 100), .groups = "drop")
}

div_infl <- function(d) {
  d |>
    group_by(country, coicop) |>
    summarise(I = prod(r), .groups = "drop") |>
    mutate(infl = (I - 1) * 100)
}

load_master_weights <- function() {
  read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE) |>
    fix_na_iso(country_iso2) |>
    transmute(country = country_iso2, coicop, low, mid, high, source,
              note = coalesce(note, ""))
}

headline_panel <- function(P = load_prices()) {
  W <- load_master_weights()
  g <-
    group_infl(P$d, select(W, country, coicop, low, mid, high)) |>
    filter(n_months >= MIN_MONTHS) |>
    left_join(select(P$rel, country, national, reliable), by = "country") |>
    left_join(distinct(W, country, source, note), by = "country") |>
    filter(reliable, note != "noisy_global_higher", !is.na(low), !is.na(mid), !is.na(high)) |>
    mutate(tier  = if_else(source == "HBS_2020", "HBS national quintiles", "GCD global segments"),
           gap   = low - high,
           ratio = ratio_pct(low, high))
  frozen <-
    read_csv(file.path(HERE, "outputs", "group_cpi_divergence_master.csv"),
             show_col_types = FALSE) |>
    fix_na_iso() |>
    filter(reliable, coalesce(wsource, "") != "noisy_global_higher", !is.na(divergence))
  chk <- inner_join(g, frozen, by = "country", suffix = c("", ".f"))
  stopifnot(nrow(g) == nrow(frozen), nrow(chk) == nrow(g),
            max(abs(chk$gap - chk$gap.f)) < 1e-8)
  g
}

names_lookup <- function() {
  read_csv(file.path(HERE, "data", "imf_cpi_pull_log.csv"), show_col_types = FALSE) |>
    fix_na_iso(code) |>
    transmute(country = code,
              name = name |>
                str_replace_all("`", "'") |>
                str_replace("^Cote d'Ivoire$", "Côte d'Ivoire") |>
                str_replace("^Lao People's Democratic Republic$", "Lao PDR") |>
                str_replace(", Republic of$", "") |>
                str_replace(",? Rep\\.?$", "") |>
                str_replace("^Moldova.*", "Moldova"))
}

gcd_quintile_fractions <- function() {
  seg_order <- c("Lowest", "Low", "Middle", "Higher")
  bands <- tribble(
    ~grp,   ~lo, ~hi,
    "low",  0.0, 0.2,
    "mid",  0.4, 0.6,
    "high", 0.8, 1.0)
  seg <-
    read_csv(file.path(REV_DAT, "gcd_segments.csv"), show_col_types = FALSE) |>
    mutate(segment = factor(segment, seg_order),
           country = countrycode(iso3, "iso3c", "iso2c", warn = FALSE),
           country = if_else(iso3 == "NAM", "NA", country)) |>
    filter(!is.na(country))
  shares <-
    seg |>
    group_by(country, segment, pc_exp_lcu, hh_sample) |>
    summarise(pop = first(pop), pop_implied = sum(exp_lcu) / first(pc_exp_lcu), .groups = "drop") |>
    mutate(pop_from = if_else(coalesce(pop, 0) > 0, "count", "implied"),
           pop = if_else(pop_from == "count", pop, pop_implied)) |>
    filter(is.finite(pop), pop > 0) |>
    arrange(country, segment) |>
    group_by(country) |>
    mutate(p = pop / sum(pop), cum_hi = cumsum(p), cum_lo = cum_hi - p) |>
    ungroup()
  ord_ok <-
    shares |>
    group_by(country) |>
    summarise(ordered = !is.unsorted(pc_exp_lcu), .groups = "drop")
  stopifnot(all(ord_ok$ordered))
  frac <-
    shares |>
    cross_join(bands) |>
    mutate(f = pmax(0, pmin(cum_hi, hi) - pmax(cum_lo, lo)) / p) |>
    select(country, segment, grp, f)
  list(seg = seg, shares = shares, frac = frac)
}
