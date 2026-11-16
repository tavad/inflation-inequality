## Table A1 (Appendix A) — COICOP division to IMF indicator-stem crosswalk

| COICOP | Division | IMF indicator stem |
|:--|:--|:--|
| 00 | All items | `PCPI` |
| 01 | Food & non-alcoholic beverages | `PCPIF` |
| 02 | Alcohol, tobacco & narcotics | `PCPIFBT` |
| 03 | Clothing & footwear | `PCPIA` |
| 04 | Housing, water, electricity, gas & fuels | `PCPIH` |
| 05 | Furnishings & household equipment | `PCPIHO` |
| 06 | Health | `PCPIM` |
| 07 | Transport | `PCPIT` |
| 08 | Communication | `PCPIEC` |
| 09 | Recreation & culture | `PCPIR` |
| 10 | Education | `PCPIED` |
| 11 | Restaurants & hotels | `PCPIRE` |
| 12 | Miscellaneous goods & services | `PCPIO` |

*Notes:* the twelve COICOP-1999 divisions (01–12) plus the all-items aggregate (00), as published monthly in the IMF Consumer Price Index database (accessed via DBnomics). Each division maps one-to-one to a fixed IMF indicator stem, so there is no discretion in the mapping on the price side. Row 00 (all items, stem `PCPI`) is the aggregate the reconciliation filter of Equation (5) reconstructs from the twelve divisions. *Source:* IMF Consumer Price Index database (COICOP divisions), accessed via DBnomics.

## Table A2 (Appendix A) — Countries dropped by the reconciliation filter (%, 2021-01 to 2024-12)

| Country | Official all-items | Reconstructed | Reconstruction gap (pp) | Reason for exclusion |
|---|--:|--:|--:|:--|
| Zambia | 68.8 | 399.8 | 331.0 | Reconstruction diverges from official all-items (rebasing / base-period break) |
| Sri Lanka | 71.1 | 119.4 | 48.3 | Reconstruction diverges from official all-items (rebasing / base-period break) |
| Guinea | 42.1 | 64.7 | 22.6 | Reconstruction diverges from official all-items (rebasing / base-period break) |
| Azerbaijan | 37.3 | NA | NA | No official division weights (cannot reconcile) |
| Paraguay | 24.3 | NA | NA | No official division weights (cannot reconcile) |

*Notes:* the filter reconstructs all-items inflation from the twelve COICOP divisions using each country's own official weights (renormalized to $\sum_k w = 1$) and drops any country whose reconstruction misses the published all-items figure by more than $\max(5\text{ pp}, 15\%)$ (Equation (5)). Of 73 countries with a complete twelve-division panel and a matched income-group basket, these 5 fail, leaving 68. “NA” marks countries that publish no official division weights and so cannot be reconciled even in principle. Zambia's reconstruction is the clearest rebasing/base-period mismatch (near 400% against a published ~69%). *Source:* author's calculations from IMF, Eurostat, and World Bank data.

## Table C1 (Appendix C) — Weight base-period sensitivity, developing tier (%, 2021-01 to 2024-12)

| Developing-tier food-share adjustment | Countries | Median ratio (%) | Median low−high gap (pp) | Low-income highest |
|---|--:|--:|--:|--:|
| None (headline, 2010 basket) | 25 | 4.10 | 4.7 | 24 / 25 |
| −10% relative | 25 | 3.71 | 4.2 | 23 / 25 |
| −20% relative | 25 | 3.31 | 3.8 | 22 / 25 |
| −30% relative | 25 | 2.78 | 3.3 | 22 / 25 |

*Notes:* the developing-tier (GCD 2010) food share is reduced by the stated relative fraction for every income group, with the removed weight redistributed proportionally across the other eleven divisions so each basket still sums to one. The group index is then recomputed by the method of Equations (1)–(3). The sample is the 25 reliable, non-noisy, complete-triple developing-tier countries and is held fixed across rows (reliability uses official, not group, weights). The median low−high gap falls monotonically from 4.7 pp as the assumed food share is cut, but the regressive direction is unbroken, with the low-income basket remaining the highest-inflation basket in every row, so the base-period mismatch bounds the magnitude without reversing the sign. *Source:* author's calculations from IMF, Eurostat, and World Bank data.

