#!/usr/bin/env python3
import csv, glob, os, collections, sys
import openpyxl

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
xlsxs = glob.glob(os.path.join(HERE, "data/gcd_raw", "**", "*.xlsx"), recursive=True)
if not xlsxs:
    sys.exit("no GCD xlsx under data/gcd_raw/")
XLSX = max(xlsxs, key=os.path.getmtime)

SEGS = ["Lowest", "Low", "Middle", "Higher"]
DIVS = [f"{k:02d}" for k in range(1, 13)]
LCU = "Local currency"

ws = openpyxl.load_workbook(XLSX, read_only=True)["Sheet1"]
it = ws.iter_rows(values_only=True)
ix = {h: i for i, h in enumerate(next(it))}

pop = collections.defaultdict(float)
hh, hhs, pcx = {}, {}, {}
exp = collections.defaultdict(float)
ENERGY = {"11045": "household energy (04.5)", "110722": "motor fuel (07.2.2)"}
nrg = collections.defaultdict(float)
cname = {}
for r in it:
    if r[ix["Area"]] != "National" or r[ix["Incomegroup"]] not in SEGS:
        continue
    iso, seg, ind = r[ix["Countrycode"]], r[ix["Incomegroup"]], r[ix["Indicatorname"]]
    v = r[ix["Value"]] or 0.0
    cname[iso] = r[ix["Countryname"]]
    if (ind == "Population" and r[ix["Sex"]] == "Both" and r[ix["Agegroup"]] == "All"
            and r[ix["Measurementunit"]] == "Number"):
        pop[(iso, seg)] = v
    elif ind == "Extrapolated number of households":
        hh[(iso, seg)] = v
    elif ind == "Nb. of households in sample":
        hhs[(iso, seg)] = v
    elif ind == "Annual expenditure, per capita" and r[ix["Measurementunit"]] == LCU:
        pcx[(iso, seg)] = v
    elif (ind == "Annual household expenditure by product/service"
          and r[ix["Measurementunit"]] == LCU):
        code = str(r[ix["Codeofproductorservice"]])
        if len(code) >= 4 and code.startswith("11") and code[2:4] in DIVS:
            exp[(iso, seg, code[2:4])] += v
        for pre, item in ENERGY.items():
            if code.startswith(pre):
                nrg[(iso, seg, item)] += v

os.makedirs(os.path.join(HERE, "data", "revision"), exist_ok=True)
out = os.path.join(HERE, "data", "revision", "gcd_segments.csv")
n = 0
with open(out, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "country", "segment", "pop", "hh", "hh_sample", "pc_exp_lcu",
                "coicop", "exp_lcu"])
    for iso in sorted(cname):
        for seg in SEGS:
            if (iso, seg) not in hh and pop.get((iso, seg), 0) == 0:
                continue
            for cp in DIVS:
                w.writerow([iso, cname[iso], seg, pop.get((iso, seg), ""), hh.get((iso, seg), ""),
                            hhs.get((iso, seg), ""), pcx.get((iso, seg), ""), cp,
                            exp.get((iso, seg, cp), 0.0)])
                n += 1
print(f"saved: {out} ({n} rows, {len(cname)} countries)")

out2 = os.path.join(HERE, "data", "revision", "gcd_energy.csv")
with open(out2, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "segment", "item", "exp_lcu"])
    for (iso, seg, item), v in sorted(nrg.items()):
        w.writerow([iso, seg, item, v])
print(f"saved: {out2}")
