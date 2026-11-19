#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REV = ROOT / "outputs" / "revision"
OUT = ROOT / "outputs"
SRC = "*Source:* author's calculations from IMF, Eurostat, and World Bank data."

def tables(path: Path):
    out, cur = [], []
    for ln in path.read_text(encoding="utf-8").splitlines():
        if ln.startswith("|"):
            cur.append(ln)
        elif cur:
            out.append(cur)
            cur = []
    if cur:
        out.append(cur)
    return out

def get(path: Path, header_start: str, rows: int | None = None) -> str:
    for t in tables(path):
        if t[0].lower().startswith(header_start.lower()):
            t = t if rows is None else t[: 2 + rows]
            return "\n".join(t)
    sys.exit(f"table starting {header_start!r} not found in {path.name}")

def line_after(path: Path, startswith: str) -> str:
    for ln in path.read_text(encoding="utf-8").splitlines():
        if ln.startswith(startswith):
            return ln.strip()
    return ""

A = OUT / "r1_01_aplus_numbers.md"
blocks = []

def add(label: str, title: str, body: str, notes: str) -> None:
    blocks.append(f"## Table {label} — {title}\n\n{body}\n\n*Notes:* {notes} {SRC}\n")

def rows_of(table: str, keep: list[str]) -> str:
    lines = table.split("\n")
    return "\n".join(lines[:2] + [l for l in lines[2:] if any(l.startswith(f"| {k} ") for k in keep)])

add("6", "Ratio by weight source (%, 2021-01 to 2024-12)",
    get(A, "| weight source"),
    "The ratio is calculated based on Equation 3. GCD uses global income segments and HBS "
    "national quintiles, so the groups are not the same thing in the two rows. The pooled row is a sensitivity check only.")

add("7", "Ratio by calendar year, 51 countries",
    get(A, "| year") + "\n\n" + get(A, "| food relative to all-items"),
    "group inflation is chained within the calendar year, and a country-year needs all 12 months. The second panel splits "
    "country-years by whether food rose faster or slower than all-items in that country and year.")

add("B2", "Cumulative inflation and expenditure shares by COICOP division (medians, %)",
    get(A, "| division"), "medians over the countries in each weight source.")

add("B3", "Two kinds of energy: budget shares of the bottom and top quintile (median across countries, % of budget)",
    get(REV / "07_energy_subperiods.md", "| source | item"),
    "household energy is COICOP 04.5 and motor fuel is 07.2.2; the HBS row for vehicles is 07.2, which includes fuel. HBS shares exclude imputed rent; "
    "the GCD rows use national quintiles rebuilt from the global segments (31 countries).")

add("C2", "Balanced panel of 23 countries present in all four HBS waves",
    get(REV / "03_weight_waves.md", "| wave"),
    "same 2021-24 prices and the chained index of the paper; only the HBS wave of the quintile weights changes, and the shares include imputed rent. "
    "Food-share gap = food share of the bottom quintile minus the top quintile, percentage points.")

add("E1", "Income-group definitions: the paper's weight sources and the harmonised specification (%)",
    get(REV / "08_revised_headline.md", "| set"),
    "revised = national quintiles for every country (HBS 2020, or GCD 2010 segments rebuilt into national quintiles), HBS without imputed rent, "
    "fixed-base index. The paper rows keep the paper's specification (chained index, HBS with imputed rent). 'Middle between' counts countries "
    "where the middle group lies between the low and high groups.")

add("F1", "Finer categories for Eurostat countries (%)",
    get(REV / "06_finer_categories.md", "| formula | level"),
    "HBS 2020 quintile shares at COICOP 3-digit level priced with the Eurostat HICP, 2021-01 to 2024-12; imputed rent dropped because the HICP has no price "
    "for it. The budget is the same at every level.")

add("F2", "Index formula: the paper's chained index against alternatives (%)",
    rows_of(get(REV / "04_index_formula.md", "| formula"),
            ["chained fixed-share (paper)", "fixed-quantity Laspeyres (s=0)", "geometric (s=1)", "CES s=1.50", "Tornqvist s=0.50"]
            ).replace("Tornqvist", "Törnqvist").replace("fixed-quantity Laspeyres (s=0)", "fixed-base (s=0)"),
    "same baskets and prices; only the index formula changes. 's' is the elasticity of substitution in the CES variants; 'up' and 'down' count countries "
    "whose ratio rises or falls relative to the paper's index.")

out = OUT / "tables_revision.md"
out.write_text("\n".join(blocks), encoding="utf-8")
print(f"wrote {out.relative_to(ROOT)}: {len(blocks)} tables ({', '.join(re.findall(r'## Table (\S+)', out.read_text()))})")
