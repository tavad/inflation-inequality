## Table 1 — Data sources and sample construction

| Input | Source | Coverage | Income groups | Vintage | Role |
|---|---|---|---|---|---|
| Category prices | IMF CPI (via DBnomics) | ~190 countries, 12 COICOP divisions, monthly | national | 2021-01–2024-12 | price paths + official weights for reconciliation |
| Developed-tier baskets | Eurostat HBS (`hbs_str_t223`) | 28 countries (EU + enlargement) | quintiles (QU1/QU3/QU5) | 2020 | per-country low/mid/high weights |
| Developing-tier baskets | World Bank Global Consumption Database | 92 developing countries | income segments | 2010 | per-country low/mid/high weights |

*Sample construction (headline, per-country baskets):* 73 countries have a complete 12-division panel over the window; reconciliation leaves **68 reliable**, dropping noisy GCD baskets leaves **54**, and requiring a complete low/mid/high triple leaves the **51-country headline sample** (73 → 68 → 54 → 51). *Stress test (uniform hand-set basket):* 117 qualifying → **108 reliable**.
*Notes:* reliable = the 12 divisions reweighted by official national weights reconcile to the official all-items CPI (within 5 pp or 15%). *Source:* author's calculations from IMF, Eurostat, and World Bank data; replication files archived at Zenodo (see the Data availability statement).

## Table 2 — Basket composition by income group (mean expenditure share, %)

| COICOP division | Developing: low | Developing: high | Developed: low | Developed: high |
|---|--:|--:|--:|--:|
| Food & non-alcoholic beverages | 51.4 | 18.5 | 21.0 | 15.3 |
| Housing, water, electricity, gas & fuels | 18.1 | 19.5 | 39.4 | 27.9 |
| Transport | 4.2 | 20.0 | 6.8 | 13.7 |
| Recreation & culture | 1.7 | 4.9 | 4.6 | 7.3 |
| Restaurants & hotels | 2.3 | 4.1 | 3.4 | 6.4 |

*Notes:* means over the 51 estimation-sample countries, split by weight source (Developing = GCD 2010, 25 countries; Developed = HBS 2020, 26 countries). The low-vs-high food-share gap is the Engel gradient the paper exploits. *Source:* author's calculations from Eurostat and World Bank income-group weights; replication files archived at Zenodo (see the Data availability statement).

## Table 3 — Cumulative inflation by income group, curated (%, 2021-01–2024-12)

| Country | All-items | Low | Mid | High | Gap (low−high, pp) |
|---|--:|--:|--:|--:|--:|
| Malawi | 141.0 | 153.0 | 115.5 | 110.6 | 42.4 |
| Egypt | 113.0 | 126.9 | 103.7 | 87.3 | 39.6 |
| Nigeria | 143.8 | 141.9 | 125.3 | 116.4 | 25.5 |
| Türkiye | 431.8 | 450.8 | 440.0 | 435.2 | 15.6 |
| Gambia | 58.2 | 65.7 | 62.3 | 51.0 | 14.7 |
| North Macedonia | 34.7 | 42.4 | 34.9 | 31.3 | 11.0 |
| Colombia | 37.4 | 44.2 | 38.7 | 35.3 | 8.9 |
| Kenya | 26.6 | 31.4 | 24.9 | 23.0 | 8.4 |
| Bolivia | 16.9 | 21.0 | 16.4 | 13.7 | 7.4 |
| Rwanda | 45.9 | 43.9 | 38.5 | 36.7 | 7.2 |
| Latvia | 35.5 | 41.4 | 37.6 | 35.2 | 6.2 |
| Cabo Verde | 16.4 | 22.2 | 18.9 | 16.4 | 5.8 |
| Morocco | 16.4 | 19.3 | 16.0 | 13.8 | 5.5 |
| Bosnia and Herzegovina | 27.4 | 29.5 | 25.6 | 24.3 | 5.2 |
| Ireland | 21.1 | 29.4 | 26.9 | 24.6 | 4.8 |
| *(31 more; see App. B)* | | | | | |
| Slovakia | 33.0 | 32.8 | 33.0 | 32.9 | -0.1 |
| Croatia | 29.0 | 28.7 | 29.1 | 29.3 | -0.5 |
| Germany | 20.7 | 20.1 | 20.4 | 20.8 | -0.7 |
| Estonia | 42.6 | 51.6 | 52.5 | 52.6 | -1.0 |
| Belarus | 38.1 | 36.0 | 36.8 | 37.9 | -1.9 |

*Summary (all 51):* the low-income basket faces the highest of the three group rates in **44 of 51** countries; median low−high gap **2.1 pp** (dispersion, max−min, 2.6 pp). Full 51-country table in Appendix B. *Source:* author's calculations from IMF, Eurostat, and World Bank data; replication files archived at Zenodo (see the Data availability statement).

## Table 5 — Weights-sensitivity ladder (median max−min divergence, pp)

| Weighting | Countries | Median divergence | Low-income highest |
|---|--:|--:|--:|
| Uniform hand-set basket (poor ≈ 60% food) | 108 | 5.3 | 94 / 108 |
| **Per-country real baskets (HBS + GCD)** | **51** | **2.6** | **44 / 51** |
| Developed EU/HBS baskets only (≈ 18% food) | 26 | 0.9 | 20 / 26 |

*Notes:* all three rows use **max−min divergence** (the metric they share); the headline low−high gap (Table 3) is a strictly smaller quantity. The direction holds across all three; the magnitude tracks food-share × inflation level, so the developed, low-food, low-inflation basket set collapses the gap. *Source:* author's calculations from IMF, Eurostat, and World Bank data; replication files archived at Zenodo (see the Data availability statement).

## Table B1 (Appendix B) — Full 51-country results (%, 2021-01–2024-12)

| Country | Source | All-items | Low | Mid | High | Gap (low−high, pp) |
|---|:--|--:|--:|--:|--:|--:|
| Malawi | GCD | 141.0 | 153.0 | 115.5 | 110.6 | 42.4 |
| Egypt | GCD | 113.0 | 126.9 | 103.7 | 87.3 | 39.6 |
| Nigeria | GCD | 143.8 | 141.9 | 125.3 | 116.4 | 25.5 |
| Türkiye | HBS | 431.8 | 450.8 | 440.0 | 435.2 | 15.6 |
| Gambia | GCD | 58.2 | 65.7 | 62.3 | 51.0 | 14.7 |
| North Macedonia | GCD | 34.7 | 42.4 | 34.9 | 31.3 | 11.0 |
| Colombia | GCD | 37.4 | 44.2 | 38.7 | 35.3 | 8.9 |
| Kenya | GCD | 26.6 | 31.4 | 24.9 | 23.0 | 8.4 |
| Bolivia | GCD | 16.9 | 21.0 | 16.4 | 13.7 | 7.4 |
| Rwanda | GCD | 45.9 | 43.9 | 38.5 | 36.7 | 7.2 |
| Latvia | HBS | 35.5 | 41.4 | 37.6 | 35.2 | 6.2 |
| Cabo Verde | GCD | 16.4 | 22.2 | 18.9 | 16.4 | 5.8 |
| Morocco | GCD | 16.4 | 19.3 | 16.0 | 13.8 | 5.5 |
| Bosnia and Herzegovina | GCD | 27.4 | 29.5 | 25.6 | 24.3 | 5.2 |
| Ireland | HBS | 21.1 | 29.4 | 26.9 | 24.6 | 4.8 |
| Fiji | GCD | 13.0 | 18.5 | 14.9 | 13.8 | 4.7 |
| Poland | HBS | 41.2 | 47.3 | 45.3 | 42.7 | 4.6 |
| Serbia | HBS | 39.4 | 44.7 | 42.1 | 40.1 | 4.6 |
| Gabon | GCD | 10.5 | 11.1 | 8.9 | 7.2 | 3.9 |
| Lithuania | HBS | 39.0 | 47.5 | 46.0 | 43.8 | 3.7 |
| Mexico | GCD | 26.2 | 21.4 | 18.9 | 18.3 | 3.1 |
| Côte d'Ivoire | GCD | 17.8 | 20.7 | 18.0 | 17.7 | 3.0 |
| Mauritania | GCD | 20.9 | 23.3 | 20.3 | 20.3 | 3.0 |
| Iraq | GCD | 0.2 | 4.0 | 2.2 | 1.1 | 2.9 |
| Cyprus | HBS | 18.0 | 23.9 | 21.9 | 21.3 | 2.6 |
| Bulgaria | HBS | 34.8 | 37.5 | 36.3 | 35.3 | 2.1 |
| Lesotho | GCD | 28.3 | 33.4 | 30.8 | 31.3 | 2.1 |
| Congo | GCD | 17.7 | 18.2 | 17.4 | 16.3 | 1.9 |
| Montenegro | HBS | 30.6 | 31.9 | 30.6 | 30.2 | 1.7 |
| Slovenia | HBS | 22.7 | 25.2 | 24.0 | 23.9 | 1.3 |
| Malaysia | GCD | 10.6 | 11.9 | 10.4 | 10.6 | 1.3 |
| Namibia | GCD | 21.6 | 22.7 | 20.4 | 21.5 | 1.2 |
| Belgium | HBS | 22.0 | 24.4 | 24.1 | 23.3 | 1.1 |
| Moldova | GCD | 65.4 | 63.2 | 59.8 | 62.3 | 0.9 |
| Austria | HBS | 23.7 | 24.8 | 24.1 | 23.8 | 0.9 |
| Portugal | HBS | 17.6 | 21.3 | 20.7 | 20.4 | 0.9 |
| Spain | HBS | 19.4 | 20.4 | 19.9 | 19.5 | 0.9 |
| Finland | HBS | 17.8 | 19.0 | 18.5 | 18.1 | 0.8 |
| Greece | HBS | 19.7 | 24.7 | 24.5 | 23.9 | 0.7 |
| France | HBS | 14.3 | 18.0 | 18.0 | 17.5 | 0.5 |
| Netherlands | HBS | 22.0 | 23.3 | 22.5 | 22.9 | 0.4 |
| Norway | HBS | 19.4 | 20.6 | 20.3 | 20.2 | 0.4 |
| Jordan | GCD | 10.5 | 10.4 | 9.8 | 10.1 | 0.2 |
| Denmark | HBS | 15.0 | 15.3 | 15.2 | 15.2 | 0.1 |
| Luxembourg | HBS | 14.8 | 15.4 | 15.4 | 15.4 | 0.0 |
| Hungary | HBS | 47.6 | 43.4 | 43.7 | 43.5 | -0.1 |
| Slovakia | HBS | 33.0 | 32.8 | 33.0 | 32.9 | -0.1 |
| Croatia | HBS | 29.0 | 28.7 | 29.1 | 29.3 | -0.5 |
| Germany | HBS | 20.7 | 20.1 | 20.4 | 20.8 | -0.7 |
| Estonia | HBS | 42.6 | 51.6 | 52.5 | 52.6 | -1.0 |
| Belarus | GCD | 38.1 | 36.0 | 36.8 | 37.9 | -1.9 |

*Notes:* all 51 reliable countries, sorted by the low−high gap; Source = weight origin (HBS = Eurostat quintiles, GCD = World Bank segments). Armenia is excluded from the 51: its World Bank Global Consumption Database "higher"-income basket fails the noise filter (it places an implausible share of spending on recreation), so its low/mid/high triple is untrustworthy and non-monotone (§6.3). *Source:* author's calculations from IMF, Eurostat, and World Bank data; replication files archived at Zenodo (see the Data availability statement).

