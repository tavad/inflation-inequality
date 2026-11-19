#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -I R/rev_gcd_segments.py
Rscript R/rev_hbs_pull.R
Rscript R/rev_hicp_pull.R
for s in rev_01_ratio_measure rev_02_gcd_quintiles rev_03_weight_waves rev_04_index_formula \
         rev_05_imputed_rent rev_06_finer_categories rev_07_energy_subperiods \
         rev_08_revised_headline rev_09_normalisation_and_descriptives; do
  echo "== $s"
  Rscript "R/$s.R" > /dev/null
done
echo "done: outputs/revision/"
