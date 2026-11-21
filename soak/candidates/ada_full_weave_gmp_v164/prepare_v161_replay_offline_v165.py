#!/usr/bin/env python3
"""v165 offline-only, hash-locked replay fixture from prior v161 instrumented QA.

The earlier archive ZIP was independently verified at SHA-256
0d1722164fc4c460c0691fe372a1e4530a2f0d2f4339dc8351626745a2f51f50.
Only the existing 45 lengths + global rank were transferred to this QA branch.
No dynamic network, no login/token, no historical calendar execution, no Soak.
"""
from __future__ import annotations

import base64
from hashlib import sha256
import json
from pathlib import Path
import sys

ARCHIVE_ID = 14707599556
ARCHIVE_ZIP_SHA256 = "0d1722164fc4c460c0691fe372a1e4530a2f0d2f4339dc8351626745a2f51f50"
RANK_SHA256 = "e5291e359bb51c67d80ac89e1752c05d209fe13a597dfccc8740f5e402c91989"
COUNT_SHA256 = "ccb69e9aa37f74a6ffd09d35e7b6477cfce36c37283861c3b59c67e3e8c9aec5"
WEAVE_JSON_SHA256 = "4d3320d1feef2af21542c9461cc2ac730b230f341462c61197666dfa68f81b66"
LENGTHS = [
    115, 108, 119, 109, 106, 81, 115, 114, 117, 120, 98, 52,
    81, 97, 121, 97, 115, 96, 107, 61, 106, 115, 119, 39,
    84, 103, 115, 107, 55, 119, 97, 50, 122, 110, 81, 54,
    101, 83, 88, 40, 25, 77, 98, 122, 105,
]
NAMES = [
    18, 14, 37, 28, 24, 42, 6, 20, 19, 41, 16, 39,
    25, 1, 9, 38, 3, 46, 27, 40, 12, 43, 35, 32,
    29, 10, 44, 36, 23, 17, 33, 5, 30, 15, 11, 45,
    8, 4, 7, 31, 34, 22, 13, 2, 26,
]


def hash_text(x: str) -> str:
    return sha256(x.encode("ascii")).hexdigest()


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: v165_preparer.py archived-rank.b64 NEW_OUTPUT_DIR")
    rank_file, out = Path(sys.argv[1]), Path(sys.argv[2])
    if out.exists():
        raise RuntimeError("refuse to overwrite any existing replay directory")
    lines = rank_file.read_text(encoding="ascii").splitlines()
    comments = [line for line in lines if line.startswith("#")]
    if len(comments) != 3:
        raise RuntimeError("unexpected witness header")
    raw64 = "".join(line.strip() for line in lines if not line.startswith("#"))
    raw = base64.b64decode(raw64, validate=True)
    if len(raw) != 2809:
        raise RuntimeError("witness must be 2809 big-endian bytes")
    rank_hex = raw.hex()
    if len(rank_hex) != 5618 or rank_hex.startswith("0"):
        raise RuntimeError("wrong rank hex canonical encoding")
    if hash_text(rank_hex) != RANK_SHA256 or int(rank_hex, 16).bit_length() != 22469:
        raise RuntimeError("replayed rank does not match prior archive")
    if len(LENGTHS) != 45 or sum(LENGTHS) != 4244 or not all(4 <= n <= 123 for n in LENGTHS):
        raise RuntimeError("wrong pinned month lengths")
    if len(NAMES) != 45 or len(set(NAMES)) != 45 or not all(1 <= n <= 47 for n in NAMES):
        raise RuntimeError("wrong pinned month name indices")
    if NAMES[7] != 20:
        raise RuntimeError("wrong pinned month mapping")

    out.mkdir(parents=True)
    selector = ",".join(map(str, LENGTHS)) + "\n" + rank_hex + "\n"
    (out / "v164-captured-selector.txt").write_text(selector, encoding="ascii")
    evidence = {
        "schema": "ISSUE29_V165_OFFLINE_PINNED_V161_SELECTOR/1",
        "archived_artifact_id": ARCHIVE_ID,
        "archived_zip_sha256": ARCHIVE_ZIP_SHA256,
        "rank_hex_sha256": RANK_SHA256,
        "rank_bit_length": 22469,
        "count_hex_sha256": COUNT_SHA256,
        "count_bit_length": 22470,
        "weave_json_sha256": WEAVE_JSON_SHA256,
        "month_lengths": LENGTHS,
        "month_name_indices": NAMES,
        "months": 45,
        "year_days": 4244,
        "offset0": 2031,
        "expected_projection": {"month_id": 8, "month_index": 20, "day_in_month": 56},
        "fixture_bytes_sha256": sha256(selector.encode("ascii")).hexdigest(),
        "provenance": "PINNED_PREVIOUS_V161_QA_TELEMETRY_NOT_ORIGINAL_SOURCE",
        "original_calendar_calls_this_run": 0,
        "qa_calendar_calls_this_run": 0,
        "soak_years_this_run": 0,
    }
    (out / "v165-locked-replay-expectation.json").write_text(
        json.dumps(evidence, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print("V165_OFFLINE_REPLAY_FIXTURE_LOCKS_PASS")
    print("V165_NO_NETWORK_NO_F_NO_SOAK")


if __name__ == "__main__":
    main()
