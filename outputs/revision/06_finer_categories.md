# 06 Finer categories

Sanity check, 12 divisions with HICP prices vs the paper's IMF-based ratio (26 countries in both): correlation 0.61, median absolute difference 0.65.

| formula | level | countries | median priced codes | ratio > 0 | median ratio % | mean ratio % | middle between |
|---|---|---|---|---|---|---|---|
| chained fixed-share | 12 divisions | 28 | 12 | 26 | 1.52 | 1.95 | 27 |
| chained fixed-share | COICOP 3-digit | 28 | 50 | 17 | 0.82 | 0.77 | 24 |
| fixed-base Laspeyres | 12 divisions | 28 | 12 | 26 | 1.94 | 2.13 | 28 |
| fixed-base Laspeyres | COICOP 3-digit | 28 | 50 | 18 | 1.57 | 1.34 | 20 |

Change in the ratio from 12 divisions to finer detail (pp of ratio):

| formula | up / down | median change | mean change |
|---|---|---|---|
| chained fixed-share | 8 / 18 | -0.87 | -1.18 |
| fixed-base Laspeyres | 6 / 20 | -0.57 | -0.80 |

Which division's split moves the ratio (fixed-base Laspeyres; exact decomposition, contributions sum to each country's change):

| division | mean contribution | median | countries < -0.05 | countries > +0.05 |
|---|---|---|---|---|
| 04 Housing, water, electricity, gas & fuels | -0.82 | -0.18 | 16 | 9 |
| 09 Recreation & culture | -0.18 | -0.12 | 17 | 4 |
| 06 Health | -0.07 | -0.00 | 10 | 3 |
| 11 Restaurants & hotels | -0.02 | -0.00 | 8 | 5 |
| 12 Miscellaneous goods & services | -0.01 | -0.03 | 8 | 6 |
| 10 Education | -0.01 | -0.01 | 4 | 3 |
| 08 Communication | -0.00 | 0.00 | 1 | 0 |
| 03 Clothing & footwear | 0.00 | 0.00 | 0 | 0 |
| 01 Food & non-alcoholic beverages | 0.01 | 0.00 | 0 | 3 |
| 02 Alcohol, tobacco & narcotics | 0.04 | 0.00 | 1 | 5 |
| 05 Furnishings & household equipment | 0.04 | 0.01 | 5 | 9 |
| 07 Transport | 0.23 | 0.11 | 7 | 18 |

By country, fixed-base Laspeyres:

| country | 12 divisions | 3-digit | change |
|---|---|---|---|
| Türkiye | 3.38 | 5.81 | 2.43 |
| Latvia | 4.53 | 5.23 | 0.70 |
| Ireland | 5.92 | 4.53 | -1.39 |
| Estonia | 4.48 | 4.44 | -0.05 |
| Serbia | 3.46 | 3.02 | -0.45 |
| Lithuania | 2.94 | 2.92 | -0.02 |
| Slovenia | 1.17 | 2.57 | 1.41 |
| Croatia | 1.80 | 2.20 | 0.40 |
| Malta | 2.11 | 2.11 | -0.01 |
| Romania | 2.08 | 2.08 | 0.00 |
| Bulgaria | 3.30 | 2.07 | -1.22 |
| Poland | 2.56 | 2.05 | -0.51 |
| Greece | 1.75 | 1.90 | 0.14 |
| Cyprus | 2.51 | 1.78 | -0.73 |
| Montenegro | 1.15 | 1.36 | 0.21 |
| Portugal | 0.83 | 0.83 | 0.00 |
| Belgium | 3.44 | 0.48 | -2.96 |
| Hungary | 1.01 | 0.37 | -0.64 |
| Netherlands | 2.81 | -0.16 | -2.97 |
| Austria | 1.03 | -0.23 | -1.26 |
| Slovakia | -0.23 | -0.26 | -0.02 |
| Denmark | 1.51 | -0.41 | -1.92 |
| France | 1.35 | -0.51 | -1.85 |
| Spain | 0.93 | -0.53 | -1.46 |
| Norway | 3.27 | -0.95 | -4.22 |
| Finland | 0.32 | -1.43 | -1.74 |
| Luxembourg | -0.62 | -1.78 | -1.16 |
| Germany | 0.90 | -2.09 | -2.99 |

