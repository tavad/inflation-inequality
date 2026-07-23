#!/usr/bin/env Rscript
# Appendix D: repo-native demonstration of the Σw = 1 normalization hazard.
# draw N random baskets, each summing exactly to one over the 12 divisions, and
# chain them over one representative country's monthly price relatives (2021-01..
# 2024-12). valid baskets give a tightly-bounded cumulative inflation; rescaling
# every basket to Σw = 1.002 injects a compounding (Σw)^T drift. the artefact is
# pure index arithmetic and country-independent; illustrated on the country whose
# all-items cumulative is the sample median (read from the locked results).
# outputs: plots/normalization_demo{,_spread}
source(here::here("R", "imf_cpi_helpers.R"))
suppressPackageStartupMessages(library(ggplot2))
set.seed(2026)

NDRAW <- 200L                       # random baskets
DRIFT <- 1.002                      # 0.2% off-normalization (Σw = 1.002)
WIN_S <- ym("2021-01"); WIN_E <- ym("2024-12")
V_LAB <- "Σw = 1 (valid)"; D_LAB <- "Σw = 1.002 (mis-normalized)"

wide   <- read_csv(file.path(HERE, "data", "imf_cpi_coicop_all_wide.csv"), show_col_types = FALSE)
master <- read_csv(file.path(HERE, "outputs", "group_cpi_divergence_master.csv"), show_col_types = FALSE)
Wm     <- read_csv(file.path(HERE, "data", "group_weights_master.csv"), show_col_types = FALSE)

# representative country: reliable, non-noisy, all-items cumulative closest to the median
rel <- master |> filter(reliable, is.na(wsource) | wsource != "noisy_global_higher", !is.na(gap))
med_nat <- median(rel$national)
pick <- rel |> mutate(d = abs(national - med_nat)) |> arrange(d) |> slice(1)
cc <- pick$country
cname <- pick$name |> str_replace_all("`", "'") |> str_replace(", Republic of$", "")

R <-
  wide |>
  filter(country == cc, coicop %in% sprintf("%02d", 1:12), date >= WIN_S, date <= WIN_E) |>
  mutate(r = 1 + mom_pct / 100) |> filter(!is.na(r)) |>
  select(date, coicop, r) |>
  pivot_wider(names_from = coicop, values_from = r) |> arrange(date)
Rmat <- as.matrix(R[, -1]); Tn <- nrow(Rmat); div <- colnames(Rmat)
stopifnot(ncol(Rmat) == 12)

# realistic baskets: Dirichlet draws centred on the country's own middle-income
# basket, so valid draws span the real between-group variation (a few pp) that the
# mis-normalization drift is measured against.
centroid <-
  Wm |> filter(country_iso2 == cc) |> arrange(coicop) |>
  transmute(coicop, mid) |> filter(coicop %in% div)
centroid <- setNames(centroid$mid, centroid$coicop)[div]
centroid <- centroid / sum(centroid)
KAPPA <- 250                                    # concentration; higher = tighter, more realistic
rdir <- function(n, alpha) {
  k <- length(alpha)
  m <- matrix(rgamma(n * k, shape = rep(alpha, each = n)), n, k)
  m / rowSums(m)
}
W <- rdir(NDRAW, KAPPA * centroid)

cum_path <- function(w) cumprod(as.numeric(Rmat %*% w))   # length-Tn cumulative growth factor
valid <- apply(W,          1, cum_path)                   # Tn x NDRAW
drift <- apply(W * DRIFT,   1, cum_path)
valid_fin <- (valid[Tn, ] - 1) * 100
drift_fin <- (drift[Tn, ] - 1) * 100
theo_drift <- (DRIFT^Tn - 1) * 100                        # closed-form spurious add-on

cat(sprintf("representative country: %s (%s), %d months, official all-items %.1f%%\n",
            cname, cc, Tn, pick$national))
cat(sprintf("valid cumulative inflation: [%.1f, %.1f] pp (range %.1f); drift shifts by ~%.1f pp\n",
            min(valid_fin), max(valid_fin), max(valid_fin) - min(valid_fin), theo_drift))

# --- Figure D1: distribution of cumulative inflation, valid vs drift ----------
# precompute the KDE so the tails taper to ~0 past the data extremes; geom_density
# clips the curve to [min, max], leaving a vertical drop at the drift shoulder.
dist <- tibble(infl = c(valid_fin, drift_fin),
               scheme = rep(c(V_LAB, D_LAB), each = NDRAW))
dens <-
  dist |>
  group_by(scheme) |>
  reframe({ d <- density(infl, n = 512); tibble(x = d$x, y = d$y) })
p1 <- ggplot(dens, aes(x, y, fill = scheme, colour = scheme)) +
  geom_area(alpha = 0.35, position = "identity", colour = NA) +
  geom_line(linewidth = 0.4) +
  geom_vline(xintercept = pick$national, linetype = "dashed", colour = "grey30") +
  annotate("text", x = pick$national, y = Inf, label = " official all-items",
           hjust = 0, vjust = 1.6, size = 3, colour = "grey30") +
  scale_fill_manual(values = c("#2c7fb8", "#d95f0e")) +
  scale_colour_manual(values = c("#2c7fb8", "#d95f0e")) +
  labs(title = "A 0.2% mis-normalization manufactures inflation divergence from nothing",
       subtitle = sprintf("%d realistic baskets on %s's 2021–24 category price paths; valid versus a 0.2%% mis-normalization",
                          NDRAW, cname),
       x = "cumulative group inflation over 2021–24 (%)", y = "density",
       fill = NULL, colour = NULL,
       caption = sprintf(paste0("Illustrated on %s (all-items %.0f%%), the country nearest the 51-country median; the artefact is arithmetic and country-independent.\n",
                                "Source: illustrative calculation on IMF category CPI paths. Author's calculations."),
                         cname, pick$national)) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))
save_fig(p1, "normalization_demo", width = 8.5, height = 4.3, dpi = 150)

# --- Figure D2: cross-basket SD of the cumulative index, by month -------------
spread <- tibble(
  month  = rep(R$date, 2),
  scheme = rep(c(V_LAB, D_LAB), each = Tn),
  sd     = c(apply((valid - 1) * 100, 1, sd), apply((drift - 1) * 100, 1, sd)))
p2 <- ggplot(spread, aes(month, sd, colour = scheme)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = c("#2c7fb8", "#d95f0e")) +
  labs(title = "The mis-normalization drift compounds with the length of the chain",
       subtitle = "Cross-basket standard deviation of the cumulative index, by month",
       x = NULL, y = "s.d. across baskets (pp)", colour = NULL,
       caption = "Source: illustrative calculation on IMF category CPI paths. Author's calculations.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", plot.caption = element_text(colour = "grey35", hjust = 0, size = 8))
save_fig(p2, "normalization_demo_spread", width = 8.5, height = 4.3, dpi = 150)

cat("wrote plots/{png,tiff}/normalization_demo{,_spread}\n")
