#!/usr/bin/env python3
"""Build a quote-free NARS workspace that tests ⎕EC + ⎕FX + function execution."""
import argparse
import hashlib
import json
import pathlib
import re
import sys

from lx_workspace_probe import make_canary

FX_NAME = "APL_GERMAN_FX_PROBE_20261118"
FX_TOKEN = "42"
FX_LINES = [
    f"∇ z←{FX_NAME} x",
    "  z←x+1",
    "∇",
]


def _codes(text: str) -> str:
    values = [ord(ch) for ch in text]
    if any(value < 0x20 or value > 0xFFFF for value in values):
        raise ValueError("FX_PROBE_TEXT_OUTSIDE_NARS_BMP_RANGE")
    return " ".join(str(value) for value in values)


def _matrix_expression(lines: list[str]) -> tuple[str, tuple[int, int]]:
    if not lines:
        raise ValueError("FX_PROBE_EMPTY_FUNCTION")
    cols = max(len(line) for line in lines)
    if cols < 1:
        raise ValueError("FX_PROBE_EMPTY_FUNCTION_LINE")
    rows = len(lines)
    flat = "".join(line.ljust(cols) for line in lines)
    return f"({rows} {cols}⍴⎕UCS {_codes(flat)})", (rows, cols)


def make_fx_probe(raw: bytes, marker: str) -> tuple[bytes, dict]:
    # Reuse the already native-proven workspace parser/mutator, then replace
    # only the newly allocated ⎕LX global with a quote-free ⎕EC expression.
    candidate, meta = make_canary(raw, marker, mode="display")
    matrix, shape = _matrix_expression(FX_LINES)
    inner = (
        f"⎕FX {matrix} ⋄ "
        f"(⍕{FX_NAME} 41) ⎕NAPPEND "
        f"((⎕UCS {_codes(marker)}) ⎕NCREATE 0)"
    )
    apl = "⎕EC ⎕UCS " + _codes(inner)
    if "'" in apl or '"' in apl:
        raise ValueError("FX_PROBE_OUTER_EXPRESSION_NOT_QUOTE_FREE")
    serialized = apl.replace("⎕", "{quad}")
    if not serialized.isascii():
        raise ValueError("FX_PROBE_SERIALIZATION_NOT_ASCII")

    global_id = meta["lx_new_global"]
    prefix = f":{global_id}=V C "
    lines = candidate.decode("cp1252").splitlines(keepends=True)
    found = 0
    for index, line in enumerate(lines):
        if not line.startswith(prefix):
            continue
        ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
        body = line[:-len(ending)] if ending else line
        if not body.endswith("'") or body.count("'") != 2:
            raise ValueError("FX_PROBE_GLOBAL_LITERAL_CONTRACT_MISMATCH")
        lines[index] = f":{global_id}=V C {len(apl)} 1 {len(apl)} '{serialized}'" + ending
        found += 1
    if found != 1:
        raise ValueError("FX_PROBE_LX_GLOBAL_NOT_UNIQUE")

    out = "".join(lines).encode("cp1252")
    meta.update({
        "contract": "APL_GERMAN_FX_EC_PROBE_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "mode": "fx_probe",
        "canary_token": FX_TOKEN,
        "apl_statement": apl,
        "inner_apl_statement": inner,
        "fx_function_name": FX_NAME,
        "fx_source_lines": FX_LINES,
        "fx_matrix_shape": list(shape),
        "actual_apl_characters": len(apl),
        "representation_ascii_characters": len(serialized),
        "native_executed": False,
        "output_sha256": hashlib.sha256(out).hexdigest(),
    })
    return out, meta


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=pathlib.Path)
    parser.add_argument("--candidate", required=True, type=pathlib.Path)
    parser.add_argument("--receipt", required=True, type=pathlib.Path)
    parser.add_argument("--canary", required=True)
    args = parser.parse_args()
    try:
        out, meta = make_fx_probe(args.source.read_bytes(), args.canary)
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(out)
        args.receipt.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("FX_PROBE_CANDIDATE_ONLY", meta["output_sha256"])
        return 0
    except (OSError, ValueError) as exc:
        failure = {
            "contract": "APL_GERMAN_FX_EC_PROBE_CANDIDATE_V1",
            "status": "GENERATION_FAILED",
            "native_executed": False,
            "error": str(exc),
        }
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(json.dumps(failure, indent=2) + "\n", encoding="utf-8")
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
