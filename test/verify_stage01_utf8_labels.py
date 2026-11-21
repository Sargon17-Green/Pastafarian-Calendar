#!/usr/bin/env python3
"""Check exact UTF-8 bytes in dynamic Portuguese Stage 1 output labels.

Independent oracle: Python Unicode literals encoded as UTF-8, not Pascal's
runtime codepage or the host locale. Other legacy suites in the combined
native artifact remain out of scope for this bounded regression.
"""
from __future__ import annotations

import argparse
from pathlib import Path

LABEL_STEMS = (
    "determinismo da taça",
    "ordem 46 contém identificador",
)

def verify(raw: bytes) -> tuple[int, list[str]]:
    errors: list[str] = []
    checked = 0
    for stem in LABEL_STEMS:
        for i in range(1, 7):
            label = f"OK: {stem} {i}\n"
            utf8 = label.encode("utf-8")
            latin1 = label.encode("iso-8859-1")
            count = raw.count(utf8)
            checked += 1
            if count != 1:
                errors.append(f"expected exactly one UTF-8 line {label.strip()!r}; found {count}")
            if latin1 != utf8 and latin1 in raw:
                errors.append(f"legacy single-byte output remains for {label.strip()!r}")
    return checked, errors

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log_file", type=Path, help="Raw tee log, not decoded job-log text")
    args = parser.parse_args()
    checked, errors = verify(args.log_file.read_bytes())
    if errors:
        for error in errors:
            print(f"UTF8_LABEL_FAIL: {error}")
        print(f"UTF8_LABEL_SUMMARY: {checked} expected lines; {len(errors)} errors")
        return 1
    print(f"UTF8_LABEL_SUMMARY: {checked}/{checked} labels match exact UTF-8 bytes; 0 errors")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
