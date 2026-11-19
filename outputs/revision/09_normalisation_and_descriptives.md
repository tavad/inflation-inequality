# 09 Sum-to-one demonstration and descriptive tables

## A. Published shares do not sum to one

Eurostat HBS quintile shares over the 12 divisions, reliable countries, all waves: raw sums range 0.943 to 1.013 (median 1.000); 74 of 222 country-wave-quintile sums are off by more than 0.1%.

Using the raw shares in the chained index moves the ratio by a median of 4.77 pp (max 97.76 pp) and flips its sign in 31 of 111 country-waves. Correlation of the spurious ratio with the analytical drift ((S_L/S_H)^T - 1): 1.000.

Largest cases:

| country | wave | raw sum Q1 | raw sum Q5 | ratio % normalised | ratio % raw | spurious | predicted drift |
|---|---|---|---|---|---|---|---|
| Slovenia | 2005 | 0.943 | 1.013 | 1.01 | -96.75 | -97.76 | -96.78 |
| Poland | 2005 | 1.003 | 1.012 | 3.95 | -32.30 | -36.25 | -34.87 |
| Netherlands | 2015 | 1.002 | 0.998 | 0.02 | 20.70 | 20.69 | 20.68 |
| Ireland | 2015 | 1.002 | 0.999 | 3.69 | 19.75 | 16.05 | 15.48 |
| Greece | 2005 | 1.001 | 0.998 | 0.99 | 16.64 | 15.65 | 15.50 |
| Austria | 2015 | 1.002 | 0.999 | 0.52 | 16.08 | 15.56 | 15.48 |
| Portugal | 2015 | 1.002 | 0.999 | 0.44 | 15.98 | 15.55 | 15.48 |
| France | 2010 | 1.000 | 0.997 | 0.12 | 15.66 | 15.53 | 15.51 |
| Germany | 2005 | 1.000 | 0.997 | 0.05 | 15.58 | 15.52 | 15.51 |
| Türkiye | 2015 | 0.998 | 1.001 | 3.38 | -10.49 | -13.87 | -13.42 |

## B1. Budget shares by group (median across countries, %; revised weights)

| tier | division | Q1 | Q5 | Q1 > Q5 in |
|---|---|---|---|---|
| GCD rebuilt | 01 Food & non-alcoholic beverages | 52.9 | 35.4 | 41 of 42 |
| GCD rebuilt | 02 Alcohol, tobacco & narcotics | 1.6 | 1.5 | 24 of 42 |
| GCD rebuilt | 03 Clothing & footwear | 4.9 | 5.2 | 20 of 42 |
| GCD rebuilt | 04 Housing, water, electricity, gas & fuels | 12.6 | 16.7 | 16 of 42 |
| GCD rebuilt | 05 Furnishings & household equipment | 3.9 | 5.1 | 7 of 42 |
| GCD rebuilt | 06 Health | 2.7 | 3.0 | 15 of 42 |
| GCD rebuilt | 07 Transport | 4.2 | 9.8 | 1 of 42 |
| GCD rebuilt | 08 Communication | 1.8 | 3.7 | 3 of 42 |
| GCD rebuilt | 09 Recreation & culture | 1.3 | 2.5 | 1 of 42 |
| GCD rebuilt | 10 Education | 1.1 | 1.6 | 3 of 42 |
| GCD rebuilt | 11 Restaurants & hotels | 1.6 | 3.5 | 1 of 42 |
| GCD rebuilt | 12 Miscellaneous goods & services | 3.1 | 4.4 | 7 of 42 |
| HBS | 01 Food & non-alcoholic beverages | 26.0 | 17.7 | 22 of 26 |
| HBS | 02 Alcohol, tobacco & narcotics | 3.5 | 2.5 | 23 of 26 |
| HBS | 03 Clothing & footwear | 3.8 | 5.4 | 0 of 26 |
| HBS | 04 Housing, water, electricity, gas & fuels | 26.6 | 12.1 | 26 of 26 |
| HBS | 05 Furnishings & household equipment | 4.3 | 6.5 | 2 of 26 |
| HBS | 06 Health | 4.6 | 3.8 | 16 of 26 |
| HBS | 07 Transport | 7.6 | 15.8 | 0 of 26 |
| HBS | 08 Communication | 4.6 | 4.0 | 19 of 26 |
| HBS | 09 Recreation & culture | 5.1 | 9.0 | 0 of 26 |
| HBS | 10 Education | 0.5 | 1.5 | 3 of 26 |
| HBS | 11 Restaurants & hotels | 4.0 | 7.7 | 0 of 26 |
| HBS | 12 Miscellaneous goods & services | 6.5 | 10.0 | 1 of 26 |

## B2. Cumulative division inflation relative to all-items, 2021-24 (median across countries)

| division | median relative price change % | above all-items in |
|---|---|---|
| 01 Food & non-alcoholic beverages | 9.07 | 65 of 68 |
| 02 Alcohol, tobacco & narcotics | -4.04 | 19 of 68 |
| 03 Clothing & footwear | -10.29 | 7 of 68 |
| 04 Housing, water, electricity, gas & fuels | -3.14 | 26 of 68 |
| 05 Furnishings & household equipment | -3.94 | 16 of 68 |
| 06 Health | -7.60 | 8 of 68 |
| 07 Transport | 0.63 | 38 of 68 |
| 08 Communication | -18.57 | 0 of 68 |
| 09 Recreation & culture | -5.06 | 12 of 68 |
| 10 Education | -7.76 | 10 of 68 |
| 11 Restaurants & hotels | 2.95 | 47 of 68 |
| 12 Miscellaneous goods & services | -4.18 | 12 of 68 |

Country-level tables: `09_shares_by_group.csv`, `09_division_inflation.csv`.

