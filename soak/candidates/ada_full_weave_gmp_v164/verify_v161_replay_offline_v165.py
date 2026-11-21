#!/usr/bin/env python3
"""Source-free v165: verify Ada-GMP 4244-month-ID replay using pinned v161 digests.

V161 was an instrumented QA run. This *never* invokes any calendar F(c,t).
No remote artifacts or network calls, and no raw source code is interpreted.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

COUNT_SHA = "ccb69e9aa37f74a6ffd09d35e7b6477cfce36c37283861c3b59c67e3e8c9aec5"
WEAVE_SHA = "4d3320d1feef2af21542c9461cc2ac730b230f341462c61197666dfa68f81b66"
RANK_SHA = "e5291e359bb51c67d80ac89e1752c05d209fe13a597dfccc8740f5e402c91989"


def hashed(v: bytes) -> str:
    return hashlib.sha256(v).hexdigest()


def unique(lines: list[str], label: str) -> str:
    prefix = "V164_PINNED_V161_" + label + "="
    matches = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    if len(matches) != 1:
        raise RuntimeError("missing/duplicated Ada output: " + prefix)
    return matches[0]


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: verify.py PINNED_EXPECTATION_JSON ADA_STDOUT NEW_RECEIPT_JSON")
    expect_path, stdout_path, destination = map(Path, sys.argv[1:])
    evidence = json.loads(expect_path.read_text(encoding="utf-8"))
    lines = stdout_path.read_text(encoding="utf-8").splitlines()
    if "V164_PINNED_V161_INTERMEDIATE_REPLAY_COMPLETE_NO_NEW_F" not in lines:
        raise RuntimeError("standalone native Ada GMP replay did not complete")
    count_hex = unique(lines, "COUNT_HEX")
    weave_text = unique(lines, "WEAVE_CSV")
    if (
        not count_hex or count_hex.startswith("0")
        or any(c not in "0123456789abcdef" for c in count_hex)
        or len(count_hex) != 5618
        or int(count_hex, 16).bit_length() != 22470
        or hashed(count_hex.encode("ascii")) != COUNT_SHA
        or COUNT_SHA != evidence["count_hex_sha256"]
        or RANK_SHA != evidence["rank_hex_sha256"]
        or WEAVE_SHA != evidence["weave_json_sha256"]
    ):
        raise RuntimeError("full-family count / archived checksum mismatch")
    try:
        word = [int(x) for x in weave_text.split(",")]
    except ValueError as exc:
        raise RuntimeError("invalid standalone Ada month-id CSV") from exc
    if len(word) != 4244 or len(evidence["month_lengths"]) != 45:
        raise RuntimeError("wrong recorded month/month-day dimensions")
    if any(not 1 <= n <= 45 for n in word):
        raise RuntimeError("invalid month identifier in Ada full weave")
    lengths = evidence["month_lengths"]
    if [word.count(k) for k in range(1, 46)] != lengths:
        raise RuntimeError("Ada output multiset differs from original recorded month lengths")
    firsts = [word.index(k) for k in range(1, 46)]
    lasts = [len(word) - 1 - word[::-1].index(k) for k in range(1, 46)]
    if firsts != sorted(firsts) or lasts != sorted(lasts):
        raise RuntimeError("Ada output violates canonical first/last occurrence order")
    computed_sha = hashed(json.dumps(word, separators=(",", ":")).encode("ascii"))
    if computed_sha != WEAVE_SHA:
        raise RuntimeError("Ada GMP 4244-month-ID word != SHA-256 of archived Python QA")
    offset = evidence["offset0"]
    mid = word[offset]
    projected = {
        "month_id": mid,
        "month_index": evidence["month_name_indices"][mid - 1],
        "day_in_month": sum(v == mid for v in word[:offset+1]),
    }
    if offset != 2031 or projected != {"month_id": 8, "month_index": 20, "day_in_month": 56}:
        raise RuntimeError("Ada GMP recorded foundation projection differs from v161")
    if evidence.get("original_calendar_calls_this_run") != 0 or evidence.get("qa_calendar_calls_this_run") != 0:
        raise RuntimeError("replay input violates no-calendar-call policy")

    receipt = {
        "schema": "ISSUE29_V165_PINNED_OFFLINE_GMP_REPLAY_VERDICT/1",
        "archived_artifact_id": evidence["archived_artifact_id"],
        "archived_zip_sha256": evidence["archived_zip_sha256"],
        "month_count": 45,
        "year_length": len(word),
        "rank_bit_length": evidence["rank_bit_length"],
        "count_bit_length": int(count_hex, 16).bit_length(),
        "pinned_count_hex_sha256": COUNT_SHA,
        "pinned_rank_hex_sha256": RANK_SHA,
        "full_weave_compact_json_sha256": computed_sha,
        "complete_4244_month_ids_match_archived_v161_qa_by_sha256": True,
        "projection_at_offset2031": projected,
        "all_month_length_frequencies_match": True,
        "both_canonical_first_last_orders": True,
        "provenance": "REPLAY_FROM_IMMUTABLE_V161_QA_INTERMEDIATES_NOT_ORIGINAL_BINARY",
        "new_calendar_F_calls": 0,
        "new_full_year_soak": 0,
        "integrated_Normative_Oracle_runtime_tested": False,
    }
    if destination.exists():
        raise RuntimeError("refuse to overwrite prior replay receipt")
    destination.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("V165_PINNED_ARCHIVED_V161_ADA_GMP_FULL_WEAVE_ALL_4244_MATCH_PASS")
    print("V165_PINNED_ARCHIVED_V161_MONTH20_DAY56_PASS")
    print("V165_NO_CALENDAR_F_RUN_NO_SOAK")


if __name__ == "__main__":
    main()
