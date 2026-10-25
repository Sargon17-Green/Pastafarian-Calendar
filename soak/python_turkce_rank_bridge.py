#!/usr/bin/env python3
"""Independent Python+Türkçe PRODUCTION selector bridge (not full-date)."""
import os
import sys
from types import SimpleNamespace

root = os.environ.get("PASTAFARIAN_PYTHON_SRC")
if not root:
    raise SystemExit("E_COMPONENT_PYTHON_SRC")
sys.path.insert(0, root)
from pastafari_calendar.legacy_arithmetic import M_OLD  # noqa: E402
from pastafari_calendar.legacy_selection import (  # noqa: E402
    LegacyAnswerRing, LegacyBiasedSelectionAdapter,
)

selector = LegacyBiasedSelectionAdapter()
for line in sys.stdin:
    fields = line.rstrip("\r\n").split("\t")
    if len(fields) != 4:
        raise SystemExit("E_COMPONENT_PYTHON_FIELDS")
    kind = fields[0]
    if kind not in ("G", "Y"):
        raise SystemExit("E_COMPONENT_PYTHON_KIND")
    ident, first, step = map(int, fields[1:])
    if not (1 <= first <= M_OLD and step in (1, -1)):
        raise SystemExit("E_COMPONENT_PYTHON_INPUT")
    if kind == "G" and ident == 0:
        raise SystemExit("E_COMPONENT_ZERO_GATE")
    n = 922 if kind == "G" else ident
    if not 1 <= n <= 100000:
        raise SystemExit("E_COMPONENT_FAMILY_SIZE")
    ctx = SimpleNamespace(branch_trace=[], logs=[])
    rank = selector.call_with_ring(ctx, LegacyAnswerRing(first, step), n)
    gap = 41 + rank if kind == "G" else 0
    rejected = ctx.patch13_rejection_count
    sys.stdout.write("\t".join(map(str, (
        kind, ident, first, step, rank, gap, rejected
    ))) + "\n")
    sys.stdout.flush()
