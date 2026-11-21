#!/usr/bin/env python3
"""Issue29 archived v161 month-selector replay verification (source-free QA).

This script does not call either calendar implementation; it compares a
standalone native Ada GMP unranking against the already captured 2026-11-21
Python QA trace. The historical artifact is SHA-256 pinned by the preparer.
"""
from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 4:
        raise RuntimeError("usage: verifier.py v161-expectations.json ada-stdout receipt.json")
    expectation, stdout_path, out = map(Path, sys.argv[1:])
    e = json.loads(expectation.read_text(encoding="utf-8"))
    stdout = stdout_path.read_text(encoding="utf-8").splitlines()

    def unique(prefix: str) -> str:
        matches = [l[len(prefix):] for l in stdout if l.startswith(prefix)]
        if len(matches) != 1:
            raise RuntimeError("pinned replay line missing or duplicated: " + prefix)
        return matches[0]

    count_hex = unique("V164_PINNED_V161_COUNT_HEX=")
    weave_text = unique("V164_PINNED_V161_WEAVE_CSV=")
    if "V164_PINNED_V161_INTERMEDIATE_REPLAY_COMPLETE_NO_NEW_F" not in stdout:
        raise RuntimeError("Ada GMP replay success marker missing")
    if not count_hex or any(c not in "0123456789abcdef" for c in count_hex):
        raise RuntimeError("Ada GMP family count hex is not canonical")
    ada_weave = [int(s) for s in weave_text.split(",")]
    expected_weave = e["expected_python_QA_month_weave"]
    if len(ada_weave) != 4244 or len(expected_weave) != 4244:
        raise RuntimeError("replayed weave differs from prescribed 4244-day year")
    if count_hex != e["selector_family_count_hex"]:
        raise RuntimeError("Ada GMP exact family size does not match pinned Python QA")
    if ada_weave != expected_weave:
        first_different = next(
            (i for i,(a,b) in enumerate(zip(ada_weave,expected_weave)) if a != b),
            None
        )
        raise RuntimeError(f"pinned v161 QA full weave differs at index {first_different}")
    digest = sha256(json.dumps(ada_weave, separators=(",", ":")).encode()).hexdigest()
    if digest != e["weave_json_sha256"]:
        raise RuntimeError("full weave digest does not match sealed QA trace")

    offset = e["offset0"]
    selected = ada_weave[offset]
    names = e["month_name_indices"]
    actual = {
        "month_id": selected,
        "month_index": names[selected - 1],
        "day_in_month": sum(x == selected for x in ada_weave[:offset + 1]),
    }
    if actual != e["expected_projection"]:
        raise RuntimeError("QA original observation not reproduced by pure GMP unrank")
    output = {
        "schema": "ISSUE29_V164_PINNED_V161_NO_F_FOUNDATION_INTERMEDIATE_REPLAY/1",
        "artifact_source_id": e["artifact_id"],
        "artifact_source_sha256": e["artifact_sha256"],
        "source_mode": "REPLAY_OF_PRIOR_QA_INTERMEDIATES_NOT_ORIGINAL_BINARY",
        "actual_F_calls_in_this_replay": 0,
        "new_native_soak_years": 0,
        "month_count": 45,
        "weave_length": len(ada_weave),
        "rank_hex_sha256": e["selector_rank_hex_sha256"],
        "count_hex_sha256": sha256(count_hex.encode("ascii")).hexdigest(),
        "weave_json_sha256": digest,
        "exact_full_family_count_equal": True,
        "all_4244_month_ids_equal": True,
        "replayed_offset0": offset,
        "replayed_projection": actual,
        "original_source_binary_correctness_certified": False,
        "integrated_Normative_Oracle_runtime_executed": False,
    }
    out.write_text(json.dumps(output, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("V164_PINNED_V161_PYTHON_QA_VS_ADA_GMP_COUNT_AND_ALL_4244_WEAVE_MATCH")
    print("V164_PINNED_V161_PROJECTION_MONTH20_DAY56_RECOVERED_NO_F")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
