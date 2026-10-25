#!/usr/bin/env python3
"""External Python+Türkçe bridge for post-55 differential soak; no oracle shortcuts."""
import os
import sys

source = os.environ.get("PASTAFARIAN_PYTHON_SRC")
if not source:
    raise SystemExit("E_SOAK_PYTHON_SRC_MISSING")
sys.path.insert(0, source)
from pastafari_calendar import calendar_date_spaghetti, SOURCE_LANGUAGE_CATALOG  # noqa: E402

cutlets = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.cutlets}
months = {item.text: item.canonical_index for item in SOURCE_LANGUAGE_CATALOG.months}
if len(cutlets) != 17 or len(months) != 47:
    raise SystemExit("E_SOAK_PYTHON_CATALOG_AMBIGUOUS")
for line in sys.stdin:
    pair = line.rstrip("\r\n").split("\t")
    if len(pair) != 2:
        raise SystemExit("E_SOAK_PYTHON_INPUT")
    c, t = (int(x) for x in pair)
    result = calendar_date_spaghetti(c, t)
    values = (
        c, t, int(result.year_number),
        cutlets[result.cutlet_name], int(result.day_in_cutlet),
        months[result.month_name], int(result.day_in_month),
    )
    sys.stdout.write("\t".join(map(str, values)) + "\n")
    sys.stdout.flush()
