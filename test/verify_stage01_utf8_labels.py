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
    try:
        raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        errors.append(f"whole log is not UTF-8 at byte offset {exc.start}: {exc.reason}")
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


# Seven fixed Portuguese labels were UTF-8-decodable but double-encoded in
# the real SHA fd5f8ff21ea5a526e1e4c60f26c67a370e7b01d4 Native artifact. This independent
# literal oracle verifies their exact output, not merely UTF-8 well-formedness.
STATIC_LABELS = (
    "BigInt subtração",
    "BigInt multiplicação simples",
    "BigInt módulo euclidiano negativo",
    "diferença Tablets-Foundation",
    "permutação rank 1",
    "permutação rank 720",
    "drop múltiplo de 720",
)

def verify_static(raw: bytes) -> tuple[int, list[str]]:
    errors: list[str] = []
    for label in STATIC_LABELS:
        expected = (f"OK: {label}\n").encode("utf-8")
        mojibake = (f"OK: {label}\n").encode("utf-8").decode("iso-8859-1").encode("utf-8")
        count = raw.count(expected)
        if count != 1:
            errors.append(f"fixed Portuguese label {label!r}: expected once, found {count}")
        if mojibake != expected and mojibake in raw:
            errors.append(f"fixed Portuguese label {label!r}: double-encoded UTF-8 remains")
    return len(STATIC_LABELS), errors

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log_file", type=Path, help="Raw tee log, not decoded job-log text")
    args = parser.parse_args()
    raw = args.log_file.read_bytes()
    checked, errors = verify(raw)
    static_checked, static_errors = verify_static(raw)
    print("UTF8_STATIC_LABEL_SUMMARY: PASS 7/7 exact labels, no double encoding" if not static_errors else f"UTF8_STATIC_LABEL_SUMMARY: FAIL {len(static_errors)} errors")
    errors.extend(static_errors)
    whole_log_ok = not any(e.startswith("whole log is not UTF-8") for e in errors)
    print("UTF8_FULL_LOG_SUMMARY: PASS" if whole_log_ok else "UTF8_FULL_LOG_SUMMARY: FAIL")
    if errors:
        for error in errors:
            print(f"UTF8_LABEL_FAIL: {error}")
        print(f"UTF8_LABEL_SUMMARY: {checked} expected lines; {len(errors)} errors")
        return 1
    print(f"UTF8_LABEL_SUMMARY: {checked}/{checked} labels match exact UTF-8 bytes; 0 errors")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
