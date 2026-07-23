#!/usr/bin/env python3
# World Bank Global Consumption Database XLSX -> tidy per-country income-group baskets.
# XLSX manually downloaded from the Microdata Library, catalog 4424; re-run after any
# GCD update: drop the new XLSX in data/gcd_raw/ and run.
# uses indicator "Share of product/service in total expenditure (%)", Area = National.
# product codes 11XX... -> COICOP division XX (digits 3-4); shares summed to the 12
# divisions, normalised to sum to 1 per country x segment. ISO3 kept (mapped to ISO2 in R).
# output: data/gcd_weights_long.csv  (iso3, country, coicop, division, segment, weight)
import csv, glob, os, collections, sys
import openpyxl

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
xlsxs = glob.glob(os.path.join(HERE, "data/gcd_raw", "**", "*.xlsx"), recursive=True)
if not xlsxs:
    sys.exit("no GCD xlsx found under data/gcd_raw/ — download from microdata catalog 4424")
XLSX = max(xlsxs, key=os.path.getmtime)
print("reading", os.path.basename(XLSX))

IND = "Share of product/service in total expenditure (%)"
SEGS = {"Lowest", "Low", "Middle", "Higher", "All"}
DIVNAME = {"01": "Food & non-alcoholic beverages", "02": "Alcohol, tobacco & narcotics",
           "03": "Clothing & footwear", "04": "Housing, water, electricity, gas & fuels",
           "05": "Furnishings & household equipment", "06": "Health", "07": "Transport",
           "08": "Communication", "09": "Recreation & culture", "10": "Education",
           "11": "Restaurants & hotels", "12": "Miscellaneous goods & services"}

wb = openpyxl.load_workbook(XLSX, read_only=True)
ws = wb["Sheet1"]
it = ws.iter_rows(values_only=True)
hdr = next(it); ix = {h: i for i, h in enumerate(hdr)}

# (iso3, segment) -> {coicop -> summed share}; (iso3) -> country name
agg = collections.defaultdict(lambda: collections.defaultdict(float))
cname = {}
n = 0
for r in it:
    if r[ix["Indicatorname"]] != IND or r[ix["Area"]] != "National":
        continue
    seg = r[ix["Incomegroup"]]
    if seg not in SEGS:
        continue
    code = str(r[ix["Codeofproductorservice"]])
    if len(code) < 4 or not code.startswith("11"):
        continue
    div = code[2:4]
    if div not in DIVNAME:
        continue
    iso3 = r[ix["Countrycode"]]
    cname[iso3] = r[ix["Countryname"]]
    agg[(iso3, seg)][div] += (r[ix["Value"]] or 0.0)
    n += 1

# normalise each (country, segment) over the 12 divisions and write long
out = os.path.join(HERE, "data", "gcd_weights_long.csv")
rows = 0
with open(out, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "country", "coicop", "division", "segment", "weight"])
    for (iso3, seg), divs in sorted(agg.items()):
        tot = sum(divs.values())
        if tot <= 0:
            continue
        for cp in sorted(DIVNAME):
            w.writerow([iso3, cname[iso3], cp, DIVNAME[cp], seg, round(divs.get(cp, 0.0) / tot, 6)])
            rows += 1

ncoun = len({k[0] for k in agg})
print(f"processed {n:,} share rows -> {ncoun} countries")
print(f"saved: data/gcd_weights_long.csv ({rows} rows)")
print("segments: Lowest/Low/Middle/Higher/All (GLOBAL percentile bins — 'Higher' is thin/noisy in poor countries)")
