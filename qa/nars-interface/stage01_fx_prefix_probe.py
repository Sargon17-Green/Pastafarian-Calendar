#!/usr/bin/env python3
"""Native NARS ⎕FX prefix experiment: compile first five functions, not Stage1 acceptance."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys

from lx_workspace_probe import make_canary
from stage01_import_workspace import (
    SOURCE_COMMIT, _codes, _matrix_expression, fx_definition_lines, load_locked_sources
)

PREFIX_COUNT = 5
PREFIX_HELPER = [
    "z←expected Stage01PrefixFix source;actual",
    "  actual←⎕FX source",
    "  :If ~expected≡actual",
    "      ⎕ERROR 'STAGE01_PREFIX_FX_NAME_MISMATCH'",
    "  :EndIf",
    "  Stage01PrefixCount←Stage01PrefixCount+1",
    "  z←actual",
]


def nested_fx_expression(lines: list[str]) -> str:
    """Use ⎕FX nested character-vector strand without matrix space padding."""
    if not lines:
        raise ValueError("NESTED_FX_NO_LINES")
    entries = []
    for line in lines:
        if not line:
            entries.append("(0⍴⎕UCS 32)")
        else:
            entries.append("(⎕UCS " + _codes(line) + ")")
    return "(" + " ".join(entries) + ")"

def create_prefix(raw_workspace: bytes, marker: str, repo_root: pathlib.Path, count: int = PREFIX_COUNT) -> tuple[bytes, dict]:
    if not 1 <= count <= 95:
        raise ValueError("PREFIX_COUNT_OUT_OF_BOUNDS")
    locked = load_locked_sources(repo_root)
    subset = locked["blocks"][:count]
    if len(subset) != count:
        raise ValueError("PREFIX_INVENTORY_TOO_SMALL")
    names = [b["name"] for b in subset]
    if len(set(names)) != count:
        raise ValueError("PREFIX_NAME_NOT_UNIQUE")
    token = f"APL_GERMAN_PREFIX_{count}_FX_VERIFIED_SOURCE_" + SOURCE_COMMIT
    program = ["⎕FX " + nested_fx_expression(PREFIX_HELPER), "Stage01PrefixCount←0"]
    for block in subset:
        program.append(
            f"(⎕UCS {_codes(block['name'])}) Stage01PrefixFix " +
            nested_fx_expression(fx_definition_lines(block))
        )
    # Only reached after the five independent exact-name comparisons succeed.
    program.append(
        f"(⎕UCS {_codes(token)}) ⎕NAPPEND ((⎕UCS {_codes(marker)}) ⎕NCREATE 0)"
    )
    inner = " ⋄ ".join(program)
    outer = "⎕EC ⎕UCS " + _codes(inner)
    if "'" in outer or '"' in outer:
        raise ValueError("PREFIX_OUTER_APL_NOT_QUOTE_FREE")
    base, meta = make_canary(raw_workspace, marker, mode="display")
    gid = meta["lx_new_global"]
    prefix = f":{gid}=V C "
    lines = base.decode("cp1252").splitlines(keepends=True)
    serialized = outer.replace("⎕", "{quad}")
    if not serialized.isascii():
        raise ValueError("PREFIX_OUTER_APL_NOT_ASCII")
    found = 0
    for idx, line in enumerate(lines):
        if line.startswith(prefix):
            ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
            lines[idx] = f":{gid}=V C {len(outer)} 1 {len(outer)} '{serialized}'" + ending
            found += 1
    if found != 1:
        raise ValueError("PREFIX_LX_GLOBAL_NOT_UNIQUE")
    candidate = "".join(lines).encode("cp1252")
    record = {
        "schema": "APL_GERMAN_NATIVE_PREFIX_FX_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "native_executed": False,
        "source_commit": SOURCE_COMMIT,
        "source_manifest_sha256": locked["manifest"]["manifest_sha256"],
        "fx_count": count,
        "fx_transport": "NESTED_CHARACTER_VECTOR_STRAND_V1",
        "fx_names": names,
        "fx_blocks": [{"name": b["name"], "path": b["path"], "source_lines": [b["start_line"], b["end_line"]]} for b in subset],
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "workspace_source_sha256": meta["input_sha256"],
        "marker_path": marker,
        "marker_token": token,
        "outer_lx_chars": len(outer),
        "inner_apl_chars": len(inner),
        "inner_sha256": hashlib.sha256(inner.encode("utf-8")).hexdigest(),
        "candidate_bytes": len(candidate),
    }
    return candidate, record


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--repo-root", type=pathlib.Path, required=True)
    p.add_argument("--source", type=pathlib.Path, required=True)
    p.add_argument("--candidate", type=pathlib.Path, required=True)
    p.add_argument("--receipt", type=pathlib.Path, required=True)
    p.add_argument("--marker", type=str, required=True)
    p.add_argument("--count", type=int, default=PREFIX_COUNT)
    args = p.parse_args()
    try:
        candidate, receipt = create_prefix(args.source.read_bytes(), args.marker, args.repo_root, args.count)
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(candidate)
        args.receipt.write_bytes((json.dumps(receipt, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
        print("PREFIX_FX_5_CANDIDATE_ONLY", receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        failure={"schema":"APL_GERMAN_NATIVE_PREFIX_FX_CANDIDATE_V1","status":"GENERATION_FAILED","native_executed":False,"error":str(exc)}
        args.receipt.write_bytes((json.dumps(failure, indent=2) + "\n").encode("utf-8"))
        print("PREFIX_FX_5_GENERATION_FAILED", type(exc).__name__, str(exc), file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
