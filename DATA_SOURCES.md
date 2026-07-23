# Data sources and provenance

Every dataset here comes from a free, public source. The MIT license covers the
code only; each dataset keeps its own terms, listed below. "Bundled" files ship in
this repo; the rest are rebuilt from the source by the script named.

## 1. Category prices: IMF Consumer Price Index (by COICOP division)

- Source: IMF CPI database, accessed via DBnomics (dataset `IMF/CPI`).
- Link: https://db.nomics.world/IMF/CPI
- Coverage: ~190 reference areas, 12 COICOP-1999 divisions plus all-items,
  monthly, each with index / YoY% / MoM% / official weight.
- Pull script: `R/pull_imf_cpi_all.R` (all areas), `R/pull_imf_cpi.R` (a country subset).
- Bundled: `data/imf_cpi_coicop_all_wide.csv` (the panel every analysis script reads),
  `data/imf_cpi_pull_log.csv` (code-to-name map and per-area coverage).
- Not bundled: `imf_cpi_coicop_all_long.csv` (165 MB, long form of the same data,
  not read by the analysis). Regenerate with `pull_imf_cpi_all.R`.
- Terms: IMF data, free to use and redistribute with attribution. Cite the IMF CPI database.

## 2. Developed-tier weights: Eurostat Household Budget Survey

- Source: Eurostat, table `hbs_str_t223`, "Structure of consumption expenditure by
  income quintile and COICOP", 2020 wave, per-mille of total expenditure.
- Link: https://ec.europa.eu/eurostat/databrowser/product/view/hbs_str_t223
- Pull script: `R/pull_hbs_weights.R` (Eurostat dissemination API, JSON-stat).
- Bundled: `data/hbs_weights_by_country.csv` (per-country low/mid/high),
  `data/hbs_weights.csv` (EU27 reference basket).
- Terms: Eurostat open data, reuse permitted with attribution.

## 3. Developing-tier weights: World Bank Global Consumption Database 2010

- Source: World Bank Global Consumption Database 2010 (version 2014-03),
  World Bank Microdata Library, catalog 4424.
- Link: https://microdata.worldbank.org/index.php/catalog/4424
- DOI: https://doi.org/10.48529/0s8s-xk76
- Producer: World Bank Development Data Group (Dupriez, Bekele, Dikhanov).
- Raw file: `WB_GCD_2010_v2014-03_data.xlsx` (56 MB). NOT redistributed here, for two
  reasons: its size, and the WB Microdata Library terms on raw microdata. To
  regenerate the derived file: download the XLSX from the catalog above, place it
  under `data/gcd_raw/`, and run `R/pull_gcd_weights.py`.
- Compile script: `R/pull_gcd_weights.py` (needs `openpyxl`) -> `data/gcd_weights_long.csv`.
- Bundled: `data/gcd_weights_long.csv` (the derived, aggregated expenditure shares only).
- Terms: World Bank Microdata Library terms of use. Only the aggregated shares are
  shipped; the raw microdata are downloaded by the user from the catalog.

## 4. Merged group baskets

- `R/build_group_weights_master.R` merges the HBS and GCD weights (preferring HBS
  where both exist) into `data/group_weights_master.csv` (bundled). This is the
  weight table `R/group_cpi_divergence.R` joins onto the price panel.
