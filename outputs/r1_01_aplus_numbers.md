# Ratio numbers by weight source

## A. Headline: ratio by weight source (pooled row is a sensitivity check, not a result)

| weight source | n | ratio > 0 | median ratio % | IQR % | max % | median pp gap |
|---|---|---|---|---|---|---|
| GCD global segments | 25 | 24 | 4.10 | 1.62 to 6.60 | 21.1 | 4.67 |
| HBS national quintiles | 26 | 20 | 0.74 | 0.11 to 1.99 | 4.6 | 0.89 |
| pooled (sensitivity only) | 51 | 44 | 1.62 | 0.57 to 4.13 | 21.1 | 2.11 |

Pooled share of countries with the low-income basket more expensive: 44 / 51 (the sign statement does not depend on the tier definition).
A median difference between the tiers is not interpretable as a developed/developing contrast (different income-group definitions).

## B. Ranking by ratio (top 10, Türkiye, bottom 6)

| country | tier | all-items % | low % | high % | pp gap | ratio % | rank pp | rank ratio |
|---|---|---|---|---|---|---|---|---|
| Egypt | GCD | 113.0 | 126.9 | 87.3 | 39.6 | 21.15 | 2 | 1 |
| Malawi | GCD | 141.0 | 153.0 | 110.6 | 42.4 | 20.14 | 1 | 2 |
| Nigeria | GCD | 143.8 | 141.9 | 116.4 | 25.5 | 11.77 | 3 | 3 |
| Gambia | GCD | 58.2 | 65.7 | 51.0 | 14.7 | 9.75 | 5 | 4 |
| North Macedonia | GCD | 34.7 | 42.4 | 31.3 | 11.0 | 8.39 | 6 | 5 |
| Kenya | GCD | 26.6 | 31.4 | 23.0 | 8.4 | 6.82 | 8 | 6 |
| Colombia | GCD | 37.4 | 44.2 | 35.3 | 8.9 | 6.60 | 7 | 7 |
| Bolivia | GCD | 16.9 | 21.0 | 13.7 | 7.4 | 6.47 | 9 | 8 |
| Rwanda | GCD | 45.9 | 43.9 | 36.7 | 7.2 | 5.28 | 10 | 9 |
| Cabo Verde | GCD | 16.4 | 22.2 | 16.4 | 5.8 | 4.95 | 12 | 10 |
| Türkiye | HBS | 431.8 | 450.8 | 435.2 | 15.6 | 2.92 | 4 | 19 |
| Belarus | GCD | 38.1 | 36.0 | 37.9 | -1.9 | -1.41 | 51 | 51 |
| Estonia | HBS | 42.6 | 51.6 | 52.6 | -1.0 | -0.66 | 50 | 50 |
| Germany | HBS | 20.7 | 20.1 | 20.8 | -0.7 | -0.57 | 49 | 49 |
| Croatia | HBS | 29.0 | 28.7 | 29.3 | -0.5 | -0.40 | 48 | 48 |
| Slovakia | HBS | 33.0 | 32.8 | 32.9 | -0.1 | -0.10 | 47 | 47 |
| Hungary | HBS | 47.6 | 43.4 | 43.5 | -0.1 | -0.06 | 46 | 46 |

Spearman(rank pp, rank ratio) = 0.99. Malawi 20.1%, Bolivia 6.5%.

## C. Mechanism (Section 5.3 restated): ratio against relative food price (1+food)/(1+all-items)-1

| specification | Pearson | Spearman | n |
|---|---|---|---|
| pp gap ~ food excess (pp), as submitted | 0.71 | 0.46 | 51 |
| ratio ~ relative food price, all | 0.67 | 0.42 | 51 |
| ratio ~ relative food price, excl. Türkiye | 0.69 | 0.41 | 50 |
| ratio ~ relative food price, GCD tier | 0.81 | 0.72 | 25 |
| ratio ~ relative food price, HBS tier | -0.05 | -0.13 | 26 |
| ratio ~ all-items inflation (level), all | 0.33 | 0.23 | 51 |
| pp gap ~ all-items inflation (level), all | 0.53 | 0.30 | 51 |

The food mechanism is a developing-tier result; in the HBS tier the gaps are small and driven by housing/energy (see `outputs/revision/06`, `07`).

## D. Cumulative inflation by COICOP division (median across countries, %), and shares by group

| division | cum. infl GCD | cum. infl HBS | share low/high GCD | share low/high HBS |
|---|---|---|---|---|
| 01 Food & non-alcoholic beverages | 36.9 | 32.4 | 50.3 / 16.9 | 18.9 / 14.5 |
| 02 Alcohol, tobacco & narcotics | 23.6 | 21.6 | 1.4 / 1.1 | 2.8 / 2.1 |
| 03 Clothing & footwear | 12.5 | 12.4 | 5.6 / 4.0 | 3.4 / 4.5 |
| 04 Housing, water, electricity, gas & fuels | 20.2 | 29.0 | 17.5 / 20.6 | 39.4 / 27.4 |
| 05 Furnishings & household equipment | 21.9 | 20.5 | 3.6 / 7.7 | 3.6 / 5.7 |
| 06 Health | 13.2 | 15.9 | 1.9 / 2.2 | 4.0 / 3.3 |
| 07 Transport | 27.1 | 26.2 | 4.2 / 18.0 | 7.2 / 13.2 |
| 08 Communication | 1.9 | 5.1 | 1.8 / 4.1 | 3.7 / 3.4 |
| 09 Recreation & culture | 17.0 | 19.0 | 1.4 / 4.5 | 4.1 / 7.3 |
| 10 Education | 10.4 | 14.6 | 1.4 / 2.1 | 0.4 / 1.2 |
| 11 Restaurants & hotels | 17.3 | 32.0 | 1.5 / 3.5 | 3.6 / 6.7 |
| 12 Miscellaneous goods & services | 20.8 | 19.0 | 3.8 / 5.4 | 5.6 / 8.1 |

## E. Sub-periods (calendar years; 51-country panel)

| year | country-years | median ratio % | ratio > 0 |
|---|---|---|---|
| 2021 | 50 | 0.21 | 30 |
| 2022 | 51 | 1.19 | 44 |
| 2023 | 51 | 0.12 | 29 |
| 2024 | 50 | 0.07 | 28 |

By whether food rose faster or slower than all-items in that country-year:

| food relative to all-items | country-years | median ratio % | ratio > 0 |
|---|---|---|---|
| food rose faster | 150 | 0.68 | 113 |
| food rose slower | 52 | -0.16 | 18 |

Within-country correlation of ratio with relative food price across years: 0.65 (pooled over country-years).

## F. Middle group outside [low, high]

9 of 51 countries: Moldova, Lesotho, Namibia, Malaysia, Netherlands, Jordan, Hungary, Slovakia, Luxembourg.
Median |ratio| for these: 0.34% against 2.59% for the other 42 (Wilcoxon p = 0.001).

## G. Tier tables (Table 2a / 2b; full lists for Appendix B)

### GCD global segments (n = 25)

| Country | All-items | Low | Mid | High | Ratio % | pp gap |
|---|--:|--:|--:|--:|--:|--:|
| Egypt | 113.0 | 126.9 | 103.7 | 87.3 | 21.15 | 39.6 |
| Malawi | 141.0 | 153.0 | 115.5 | 110.6 | 20.14 | 42.4 |
| Nigeria | 143.8 | 141.9 | 125.3 | 116.4 | 11.77 | 25.5 |
| Gambia | 58.2 | 65.7 | 62.3 | 51.0 | 9.75 | 14.7 |
| North Macedonia | 34.7 | 42.4 | 34.9 | 31.3 | 8.39 | 11.0 |
| Kenya | 26.6 | 31.4 | 24.9 | 23.0 | 6.82 | 8.4 |
| Colombia | 37.4 | 44.2 | 38.7 | 35.3 | 6.60 | 8.9 |
| Bolivia | 16.9 | 21.0 | 16.4 | 13.7 | 6.47 | 7.4 |
| Rwanda | 45.9 | 43.9 | 38.5 | 36.7 | 5.28 | 7.2 |
| Cabo Verde | 16.4 | 22.2 | 18.9 | 16.4 | 4.95 | 5.8 |
| Morocco | 16.4 | 19.3 | 16.0 | 13.8 | 4.83 | 5.5 |
| Bosnia and Herzegovina | 27.4 | 29.5 | 25.6 | 24.3 | 4.15 | 5.2 |
| Fiji | 13.0 | 18.5 | 14.9 | 13.8 | 4.10 | 4.7 |
| Gabon | 10.5 | 11.1 | 8.9 | 7.2 | 3.64 | 3.9 |
| Iraq | 0.2 | 4.0 | 2.2 | 1.1 | 2.86 | 2.9 |
| Mexico | 26.2 | 21.4 | 18.9 | 18.3 | 2.60 | 3.1 |
| Côte d'Ivoire | 17.8 | 20.7 | 18.0 | 17.7 | 2.57 | 3.0 |
| Mauritania | 20.9 | 23.3 | 20.3 | 20.3 | 2.51 | 3.0 |
| Congo | 17.7 | 18.2 | 17.4 | 16.3 | 1.62 | 1.9 |
| Lesotho | 28.3 | 33.4 | 30.8 | 31.3 | 1.57 | 2.1 |
| Malaysia | 10.6 | 11.9 | 10.4 | 10.6 | 1.16 | 1.3 |
| Namibia | 21.6 | 22.7 | 20.4 | 21.5 | 1.03 | 1.2 |
| Moldova | 65.4 | 63.2 | 59.8 | 62.3 | 0.58 | 0.9 |
| Jordan | 10.5 | 10.4 | 9.8 | 10.1 | 0.22 | 0.2 |
| Belarus | 38.1 | 36.0 | 36.8 | 37.9 | -1.41 | -1.9 |

### HBS national quintiles (n = 26)

| Country | All-items | Low | Mid | High | Ratio % | pp gap |
|---|--:|--:|--:|--:|--:|--:|
| Latvia | 35.5 | 41.4 | 37.6 | 35.2 | 4.58 | 6.2 |
| Ireland | 21.1 | 29.4 | 26.9 | 24.6 | 3.87 | 4.8 |
| Serbia | 39.4 | 44.7 | 42.1 | 40.1 | 3.26 | 4.6 |
| Poland | 41.2 | 47.3 | 45.3 | 42.7 | 3.25 | 4.6 |
| Türkiye | 431.8 | 450.8 | 440.0 | 435.2 | 2.92 | 15.6 |
| Lithuania | 39.0 | 47.5 | 46.0 | 43.8 | 2.58 | 3.7 |
| Cyprus | 18.0 | 23.9 | 21.9 | 21.3 | 2.14 | 2.6 |
| Bulgaria | 34.8 | 37.5 | 36.3 | 35.3 | 1.56 | 2.1 |
| Montenegro | 30.6 | 31.9 | 30.6 | 30.2 | 1.33 | 1.7 |
| Slovenia | 22.7 | 25.2 | 24.0 | 23.9 | 1.05 | 1.3 |
| Belgium | 22.0 | 24.4 | 24.1 | 23.3 | 0.89 | 1.1 |
| Portugal | 17.6 | 21.3 | 20.7 | 20.4 | 0.75 | 0.9 |
| Austria | 23.7 | 24.8 | 24.1 | 23.8 | 0.74 | 0.9 |
| Spain | 19.4 | 20.4 | 19.9 | 19.5 | 0.73 | 0.9 |
| Finland | 17.8 | 19.0 | 18.5 | 18.1 | 0.70 | 0.8 |
| Greece | 19.7 | 24.7 | 24.5 | 23.9 | 0.57 | 0.7 |
| France | 14.3 | 18.0 | 18.0 | 17.5 | 0.43 | 0.5 |
| Netherlands | 22.0 | 23.3 | 22.5 | 22.9 | 0.34 | 0.4 |
| Norway | 19.4 | 20.6 | 20.3 | 20.2 | 0.30 | 0.4 |
| Denmark | 15.0 | 15.3 | 15.2 | 15.2 | 0.05 | 0.1 |
| Luxembourg | 14.8 | 15.4 | 15.4 | 15.4 | -0.00 | -0.0 |
| Hungary | 47.6 | 43.4 | 43.7 | 43.5 | -0.06 | -0.1 |
| Slovakia | 33.0 | 32.8 | 33.0 | 32.9 | -0.10 | -0.1 |
| Croatia | 29.0 | 28.7 | 29.1 | 29.3 | -0.40 | -0.5 |
| Germany | 20.7 | 20.1 | 20.4 | 20.8 | -0.57 | -0.7 |
| Estonia | 42.6 | 51.6 | 52.5 | 52.6 | -0.66 | -1.0 |

