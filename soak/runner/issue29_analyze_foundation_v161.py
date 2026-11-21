#!/usr/bin/env python3
"""Issue #29 v161: inspect QA-only evidence; NEVER imports/calls calendar F(c,t).

The earliest *observed* unequal node need not be the first unequal calculation:
Sauce, streams and several rank decisions lack instrumented receipts.
"""
from __future__ import annotations

from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import sys


def digest_json(x: object) -> str:
    return sha256(json.dumps(x, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()


def load_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines() if path.is_file() else []


def labelled_json(lines: list[str], prefix: str):
    matches = [x[len(prefix):] for x in lines if x.startswith(prefix)]
    if len(matches) != 1:
        return None
    return json.loads(matches[0])


def parse_ada(lines: list[str]) -> dict:
    scalar: dict[str, str] = {}
    indexed: dict[str, dict[int, int]] = {
        "month_length": {}, "month_name": {}, "weave": {}, "ticket": {},
    }
    for line in lines:
        if line.startswith("V159_ADA_DIAG|"):
            pieces = line.split("|")
            if len(pieces) == 3:
                _, name, value = pieces
                if name in scalar:
                    raise ValueError("duplicate Ada scalar: " + name)
                scalar[name] = value.strip()
            elif len(pieces) == 4:
                _, name, index, value = pieces
                if name not in indexed:
                    raise ValueError("unexpected Ada index category: " + name)
                i = int(index.strip())
                if i in indexed[name]:
                    raise ValueError("duplicate Ada index: " + name)
                indexed[name][i] = int(value.strip())
        elif line.startswith("W|") or line.startswith("T|"):
            pieces = line.split("|")
            if len(pieces) != 3:
                raise ValueError("malformed compact Ada trace line")
            name = "weave" if pieces[0] == "W" else "ticket"
            i, value = int(pieces[1].strip()), int(pieces[2].strip())
            if i in indexed[name]:
                raise ValueError("duplicate compact Ada trace position")
            indexed[name][i] = value

    def dense(xs: dict[int, int]) -> list[int] | None:
        if not xs:
            return None
        lo = min(xs)
        if lo != 1 or set(xs) != set(range(1, max(xs) + 1)):
            raise ValueError("noncontiguous Ada trace indices")
        return [xs[i] for i in range(1, max(xs) + 1)]

    integer_names = ("year_open_day", "year_close_day", "month_count",
                     "month_count_rank", "month_name_rank", "target_offset0",
                     "month_id", "month_index", "day_in_month",
                     "month_lengths_global_rank")
    out = {k: int(v) for k, v in scalar.items() if k in integer_names}
    out["source_mode"] = scalar.get("source_mode")
    out["month_lengths"] = dense(indexed["month_length"])
    out["month_weaving"] = dense(indexed["weave"])
    out["month_name_indices"] = dense(indexed["month_name"])
    out["tickets"] = dense(indexed["ticket"])
    return out


def tuple_from_stdout(lines: list[str], prefix: str) -> list[int] | None:
    matches = [x[len(prefix):] for x in lines if x.startswith(prefix)]
    if len(matches) != 1:
        return None
    fields = [int(x.strip()) for x in matches[0].split("|")]
    if len(fields) != 5:
        raise ValueError("not a five-field calendar tuple")
    return fields


def summarize(x):
    if x is None:
        return {"observed": False}
    if isinstance(x, list):
        return {
            "observed": True, "length": len(x), "sha256": digest_json(x),
            "first_8": x[:8], "last_8": x[-8:],
        }
    return {"observed": True, "value": x}


def validate_calendar_trace(x: dict) -> list[str]:
    problems = []
    m = x.get("month_count")
    lengths = x.get("month_lengths")
    weave = x.get("month_weaving")
    names = x.get("month_name_indices")
    offset = x.get("target_offset0")
    mid = x.get("month_id")
    if m is None or lengths is None or weave is None or names is None:
        return ["missing required calendar trace"]
    if len(lengths) != m or len(names) != m:
        problems.append("month count does not match length/name arrays")
    if sum(lengths) != len(weave):
        problems.append("month length total does not match weave length")
    if sorted(set(names)) != sorted(names) or len(set(names)) != m:
        problems.append("names are not pairwise distinct")
    if any(n < 1 or n > m for n in weave):
        problems.append("weave has invalid month identifiers")
    if not problems and [Counter(weave)[i] for i in range(1, m + 1)] != lengths:
        problems.append("weave frequency differs from month lengths")
    if offset is None or not (0 <= offset < len(weave)):
        problems.append("target offset out of range")
    elif mid != weave[offset]:
        problems.append("month id differs from weave at the target offset")
    elif x.get("month_index") != names[mid - 1]:
        problems.append("month name mapping differs from output field")
    elif x.get("day_in_month") != sum(v == mid for v in weave[:offset + 1]):
        problems.append("day-in-month count differs from the woven prefix")
    return problems


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: analyzer evidence_dir output.json", file=sys.stderr)
        return 2
    d, target = Path(sys.argv[1]), Path(sys.argv[2])
    p_err, a_err = load_lines(d / "run-python.stderr"), load_lines(d / "run-ada.stderr")
    p_out, a_out = load_lines(d / "run-python.stdout"), load_lines(d / "run-ada.stdout")
    py = labelled_json(p_err, "V159_PY_DIAG|result|")
    # Python telemetry renders calendar-day integers as decimal strings while
    # Ada renders them as big integers. Normalize *before* equality checks;
    # otherwise the identical normative gates become false positives.
    if isinstance(py, dict):
        for integer_day in ("calculation_day", "target_day", "year_open_day", "year_close_day"):
            if integer_day in py:
                text_value = py[integer_day]
                if not isinstance(text_value, (str, int)) or isinstance(text_value, bool):
                    raise ValueError("invalid Python day type: " + integer_day)
                py[integer_day] = int(text_value)
    selector = labelled_json(p_err, "V159_PY_DIAG|selector|")
    ada = parse_ada(a_err)
    py_tuple = tuple_from_stdout(p_out, "V160_PY_RESULT|")
    ada_tuple = tuple_from_stdout(a_out, "V160_ADA_RESULT|")
    status = "BOTH_COMPLETE" if py is not None and ada_tuple is not None and ada["month_weaving"] is not None else "PARTIAL_OR_FAILED"
    comparisons = []
    first = None
    fields = [
        "year_open_day", "year_close_day", "month_count", "month_lengths",
        "month_weaving", "month_name_indices", "target_offset0", "month_id",
        "month_index", "day_in_month",
    ]
    for name in fields:
        pv = py.get(name) if isinstance(py, dict) else None
        av = ada.get(name)
        observed = pv is not None and av is not None
        equal = (pv == av) if observed else None
        item = {"node": name, "both_observed": observed, "equal": equal,
                "python": summarize(pv), "ada": summarize(av)}
        if observed and not equal and first is None:
            first = name
        if observed and not equal and isinstance(pv, list) and isinstance(av, list):
            item["first_different_zero_based_position"] = next(
                (i for i in range(min(len(pv), len(av))) if pv[i] != av[i]),
                min(len(pv), len(av)),
            )
        comparisons.append(item)

    summary = {
        "schema": "ISSUE29_V161_QA_FOUNDATION_INTERMEDIATE_COMPARISON/1",
        "case": {"c": -15055671, "t": -15055671},
        "source_mode": "QA_INSTRUMENTED_COPIES_NOT_HISTORICAL_ORIGINAL_EXECUTION",
        "status": status,
        "final_five_fields": {
            "python": py_tuple, "ada": ada_tuple,
            "historical_python": [5000, 10, 503, 20, 56],
            "historical_ada": [5000, 10, 503, 30, 52],
        },
        "first_unequal_among_observed_nodes": first,
        "actual_first_divergent_computation_certified": False,
        "unobserved_earlier_nodes": [
            "Sauce internal residues", "Ask_Bowl/Answer_At intermediate stream",
            "full selector input/rank correlation across language implementations",
        ],
        "comparison": comparisons,
        "python_selector": {
            "observed": selector is not None,
            "month_lengths_consistent_with_result": (
                selector.get("month_lengths") == py.get("month_lengths")
                if selector is not None and py is not None else None),
            "family_count_hex": selector.get("family_count_hex") if selector else None,
            "global_rank_hex": selector.get("global_rank_hex") if selector else None,
        },
        "ada_distinct_choice_rank": ada.get("month_lengths_global_rank"),
        "ada_month_count_rank": ada.get("month_count_rank"),
        "ada_name_rank": ada.get("month_name_rank"),
        "ada_tickets": summarize(ada.get("tickets")),
        "trace_internal_consistency": {
            "python": validate_calendar_trace(py) if isinstance(py, dict) else ["no Python final trace"],
            "ada": validate_calendar_trace(ada),
        },
        "no_full_soak": True,
        "original_source_F_calls": 0,
    }
    target.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("V161_ANALYSIS_STATUS", status)
    print("V161_FIRST_UNEQUAL_AMONG_OBSERVED_NODES", first or "NONE_OR_NOT_OBSERVED")
    print("V161_PY_QA_FIVE_FIELDS", py_tuple)
    print("V161_ADA_QA_FIVE_FIELDS", ada_tuple)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
