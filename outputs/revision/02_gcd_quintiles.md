# 02 National quintile baskets rebuilt from the GCD

Method: segments ranked by per-capita consumption (ordering verified in every country); bottom 20%, middle 20% (40th to 60th percentile) and top 20% of persons; segment spending pooled by the share of each segment inside the band. Within-segment homogeneity is assumed, which shrinks the measured distance between quintiles.

## How thin is the GCD 'Higher' segment?

Across the 85 GCD countries with a Higher segment: median population share 0.4%, median sample households 67.0; 50 countries below 1% of the population, 39 below 50 sample households.

In the 25-country GCD tier of the paper:

| country | Higher segment % of population | sample households | top quintile made of (Lowest/Low/Middle/Higher, % of persons) |
|---|---|---|---|
| Nigeria | 0.00 | 1.0 | 48.2 / 50.3 / 1.5 / 0.0 |
| Malawi | 0.06 | 16.0 | 55.0 / 39.6 / 5.0 / 0.3 |
| Gambia | 0.07 | 4.0 | 0.0 / 79.1 / 20.6 / 0.3 |
| Rwanda | 0.17 | 25.0 | 57.4 / 32.7 / 9.1 / 0.9 |
| Mauritania | 0.20 | 33.0 | 0.0 / 74.7 / 24.3 / 1.0 |
| Congo | 0.21 | 12.0 | 0.0 / 77.4 / 21.5 / 1.0 |
| Côte d'Ivoire | 0.25 | 58.0 | 0.0 / 73.2 / 25.6 / 1.2 |
| Kenya | 0.26 | 106.0 | 17.9 / 71.6 / 9.2 / 1.3 |
| Egypt | 0.28 | 58.0 | 0.0 / 83.4 / 15.2 / 1.4 |
| Lesotho | 0.38 | 73.0 | 0.0 / 70.2 / 27.9 / 1.9 |
| Fiji | 0.76 | 92.0 | 0.0 / 39.9 / 56.3 / 3.8 |
| Iraq | 1.09 | 132.0 | 0.0 / 18.1 / 76.5 / 5.4 |
| Morocco | 1.09 | 230.0 | 0.0 / 22.2 / 72.3 / 5.5 |
| Gabon | 1.90 | 180.0 | 0.0 / 5.5 / 85.0 / 9.5 |
| Cabo Verde | 2.00 | 145.0 | 0.0 / 11.2 / 78.8 / 10.0 |
| Namibia | 2.33 | 374.0 | 0.0 / 56.3 / 32.1 / 11.6 |
| Jordan | 2.76 | 422.0 | 0.0 / 0.0 / 86.2 / 13.8 |
| Bolivia | 2.83 | 157.0 | 0.0 / 0.0 / 85.8 / 14.2 |
| Mexico | 3.25 | 1316.0 | 0.0 / 0.0 / 83.7 / 16.3 |
| Moldova | 3.75 | 196.0 | 0.0 / 0.0 / 81.3 / 18.7 |
| Malaysia | 5.71 | 1050.0 | 0.0 / 0.0 / 71.5 / 28.5 |
| Colombia | 6.14 | 1017.0 | 0.0 / 0.0 / 69.3 / 30.7 |
| North Macedonia | 9.55 | 523.0 | 0.0 / 0.0 / 52.3 / 47.7 |
| Belarus | 9.90 | 578.0 | 0.0 / 0.0 / 50.5 / 49.5 |
| Bosnia and Herzegovina | 28.70 | 2397.0 | 0.0 / 0.0 / 0.0 / 100.0 |

## Result: ratio % under the two definitions

| set | n | ratio > 0 | median ratio % | IQR |
|---|---|---|---|---|
| paper's 25 GCD countries, global segments | 25 | 24 | 4.10 | 1.62 to 6.60 |
| same 25, rebuilt national quintiles | 25 | 24 | 2.29 | 1.39 to 3.23 |
| all reliable GCD countries, rebuilt quintiles | 42 | 36 | 1.65 | 0.58 to 2.99 |

Spearman, segment ratio vs quintile ratio (25 countries): 0.78. Middle group between low and high: 20 of 25 with segments, 20 of 25 with quintiles.

| country | status | all-items % | ratio %, segments | ratio %, quintiles | mid between? |
|---|---|---|---|---|---|
| Malawi | in the 51 (GCD tier) | 141.0 | 20.14 | 8.53 | yes |
| Egypt | in the 51 (GCD tier) | 113.0 | 21.15 | 7.24 | yes |
| Mozambique | recovered: noisy Higher basket | 30.3 |  | 7.06 | yes |
| Colombia | in the 51 (GCD tier) | 37.4 | 6.60 | 5.46 | yes |
| North Macedonia | in the 51 (GCD tier) | 34.7 | 8.39 | 4.78 | yes |
| Bolivia | in the 51 (GCD tier) | 16.9 | 6.47 | 4.64 | yes |
| Honduras | recovered: noisy Higher basket | 26.4 |  | 4.45 | yes |
| Kenya | in the 51 (GCD tier) | 26.6 | 6.82 | 3.84 | **no** |
| Cabo Verde | in the 51 (GCD tier) | 16.4 | 4.95 | 3.23 | yes |
| Nigeria | in the 51 (GCD tier) | 143.8 | 11.77 | 3.06 | yes |
| Morocco | in the 51 (GCD tier) | 16.4 | 4.83 | 3.02 | yes |
| Fiji | in the 51 (GCD tier) | 13.0 | 4.10 | 2.89 | yes |
| Rwanda | in the 51 (GCD tier) | 45.9 | 5.28 | 2.76 | **no** |
| Gabon | in the 51 (GCD tier) | 10.5 | 3.64 | 2.41 | yes |
| Mexico | in the 51 (GCD tier) | 26.2 | 2.60 | 2.29 | yes |
| Burundi | recovered: no Higher segment | 128.4 |  | 2.23 | yes |
| Nicaragua | recovered: no Higher segment | 29.9 |  | 2.00 | yes |
| Albania | recovered: noisy Higher basket | 18.3 |  | 1.88 | yes |
| Cameroon | recovered: noisy Higher basket | 23.5 |  | 1.86 | yes |
| Sierra Leone | recovered: noisy Higher basket | 179.9 |  | 1.81 | **no** |
| Côte d'Ivoire | in the 51 (GCD tier) | 17.8 | 2.57 | 1.67 | yes |
| Mauritania | in the 51 (GCD tier) | 20.9 | 2.51 | 1.64 | yes |
| Moldova | in the 51 (GCD tier) | 65.4 | 0.58 | 1.56 | yes |
| Namibia | in the 51 (GCD tier) | 21.6 | 1.03 | 1.48 | **no** |
| Lesotho | in the 51 (GCD tier) | 28.3 | 1.57 | 1.42 | **no** |
| Bosnia and Herzegovina | in the 51 (GCD tier) | 27.4 | 4.15 | 1.39 | yes |
| Bhutan | recovered: noisy Higher basket | 19.5 |  | 1.16 | yes |
| Iraq | in the 51 (GCD tier) | 0.2 | 2.86 | 1.04 | yes |
| Gambia | in the 51 (GCD tier) | 58.2 | 9.75 | 1.04 | **no** |
| Ukraine | recovered: noisy Higher basket | 63.9 |  | 0.92 | yes |
| Lao PDR | recovered: noisy Higher basket | 113.1 |  | 0.61 | yes |
| Malaysia | in the 51 (GCD tier) | 10.6 | 1.16 | 0.57 | yes |
| Armenia | recovered: noisy Higher basket | 17.6 |  | 0.55 | yes |
| Pakistan | recovered: noisy Higher basket | 88.6 |  | 0.46 | yes |
| Congo | in the 51 (GCD tier) | 17.7 | 1.62 | 0.37 | yes |
| Jordan | in the 51 (GCD tier) | 10.5 | 0.22 | 0.18 | yes |
| Chad | recovered: noisy Higher basket | 28.0 |  | -0.30 | yes |
| Cambodia | recovered: noisy Higher basket | 10.4 |  | -0.33 | **no** |
| Belarus | in the 51 (GCD tier) | 38.1 | -1.41 | -0.82 | yes |
| Afghanistan | recovered: noisy Higher basket | 5.2 |  | -1.59 | yes |
| Liberia | recovered: no Higher segment | 40.2 |  | -3.11 | yes |
| El Salvador | recovered: noisy Higher basket | 15.6 |  | -3.36 | yes |

## Validation: same-year true quintiles (Eurostat HBS 2010)

Population implied from spending for: CN, FJ, TR.

Countries in both sources with price data: Bulgaria, Latvia, Lithuania, Montenegro, North Macedonia, Türkiye. Mean absolute error of the ratio against the true HBS 2010 quintiles: rebuilt quintiles 0.83 pp of ratio, global segments 3.06.

Mean signed error (rebuilt minus true): 0.52; (segments minus true): 3.06.

| country | reconciles? | ratio %, HBS 2010 quintiles | ratio %, GCD rebuilt quintiles | ratio %, GCD global segments |
|---|---|---|---|---|
| Bulgaria | yes | 1.72 | 1.42 | 3.31 |
| Lithuania | yes | 2.89 | 3.01 | 5.78 |
| Latvia | yes | 3.06 | 4.11 | 7.55 |
| Montenegro | yes | 2.03 | 2.32 | 3.84 |
| North Macedonia | yes | 2.18 | 4.78 | 8.40 |
| Türkiye | yes | 3.89 | 3.28 | 5.26 |

Food share, bottom minus top group (pp of budget):

| country | HBS 2010 quintiles | GCD rebuilt quintiles | GCD global segments |
|---|---|---|---|
| Bulgaria | 16.5 | 17.1 | 31.4 |
| Latvia | 8.4 | 20.5 | 38.4 |
| Lithuania | 11.4 | 19.6 | 38.9 |
| Romania | 15.6 | 19.2 | 51.1 |
| Montenegro | 16.6 | 20.4 | 35.4 |
| North Macedonia | 20.8 | 29.6 | 49.8 |
| Türkiye | 16.6 | 17.6 | 29.6 |

