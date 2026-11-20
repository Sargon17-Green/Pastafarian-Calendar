#!/usr/bin/env python3
"""Isolated, fail-closed NARS2000 prefix-20 progress probe; NOT Stage 1."""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

from lx_workspace_probe import make_canary
from stage01_fx_prefix_probe import PREFIX_HELPER, nested_fx_expression
from stage01_import_workspace import SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources

COUNT = 20
CHECKPOINTS = (0, 1, 5, 10, 15, 16, 17, 18, 19, 20)


def write_expr(token: str, path: str) -> str:
    return f"(⎕UCS {_codes(token)}) ⎕NAPPEND ((⎕UCS {_codes(path)}) ⎕NCREATE 0)"


def record(marker: str, index: int, names: list[str]) -> dict:
    base = pathlib.PureWindowsPath(marker)
    path = str(base.with_name(f"{base.stem}_after_{index:02d}.txt"))
    name = "START" if index == 0 else names[index - 1]
    token = (
        f"APL_GERMAN_FX_TRACE_V1|SOURCE={SOURCE_COMMIT}"
        f"|COUNT={COUNT}|AFTER={index:02d}|NAME={name}"
    )
    return {
        "after": index,
        "name": name,
        "path": path,
        "token": token,
        "token_sha256": hashlib.sha256(token.encode("ascii")).hexdigest(),
        "expected_bytes": len(token.encode("ascii")),
    }


def create_progress(raw: bytes, marker: str, repo: pathlib.Path, mode: str = "full") -> tuple[bytes, dict]:
    if mode not in ("full", "start_only", "canary_only"):
        raise ValueError("INVALID_PROGRESS_MODE")
    locked = load_locked_sources(repo)
    blocks = locked["blocks"][:COUNT]
    if len(blocks) != COUNT:
        raise ValueError("LOCKED_BLOCK_COUNT_MISMATCH")
    names = [b["name"] for b in blocks]
    if len(set(names)) != COUNT:
        raise ValueError("LOCKED_FUNCTION_NAMES_NOT_UNIQUE")
    indexes = CHECKPOINTS if mode == "full" else (0,)
    traces = [record(marker, i, names) for i in indexes]
    by_index = {x["after"]: x for x in traces}
    token = (
        f"APL_GERMAN_FX_TRACE_CANARY_V1|SOURCE={SOURCE_COMMIT}"
        if mode == "canary_only"
        else f"APL_GERMAN_PREFIX_{COUNT}_FX_VERIFIED_SOURCE_{SOURCE_COMMIT}"
    )
    parts = [write_expr(traces[0]["token"], traces[0]["path"])]
    if mode != "canary_only":
        parts += ["⎕FX " + nested_fx_expression(PREFIX_HELPER), "Stage01PrefixCount←0"]
        for index, block in enumerate(blocks, 1):
            parts.append(
                f"(⎕UCS {_codes(block['name'])}) Stage01PrefixFix "
                + nested_fx_expression(fx_definition_lines(block))
            )
            if index in by_index:
                checkpoint = by_index[index]
                parts.append(write_expr(checkpoint["token"], checkpoint["path"]))
    parts.append(write_expr(token, marker))
    inner = " ⋄ ".join(parts)
    outer = "⎕EC ⎕UCS " + _codes(inner)
    base, meta = make_canary(raw, marker, mode="display")
    gid = meta["lx_new_global"]
    prefix = f":{gid}=V C "
    lines = base.decode("cp1252").splitlines(keepends=True)
    serialized = outer.replace("⎕", "{quad}")
    if not serialized.isascii() or "'" in serialized:
        raise ValueError("LX_OUTER_NOT_SAFE_ASCII")
    matches = 0
    for index, line in enumerate(lines):
        if line.startswith(prefix):
            ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
            lines[index] = f":{gid}=V C {len(outer)} 1 {len(outer)} '{serialized}'" + ending
            matches += 1
    if matches != 1:
        raise ValueError("LX_GLOBAL_NOT_UNIQUE")
    candidate = "".join(lines).encode("cp1252")
    result = {
        "schema": "APL_GERMAN_FX_NATIVE_PROGRESS_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "native_executed": False,
        "stage01": "NOT_RUN",
        "source_commit": SOURCE_COMMIT,
        "source_manifest_sha256": locked["manifest"]["manifest_sha256"],
        "count": COUNT,
        "fx_count": 0 if mode == "canary_only" else COUNT,
        "mode": mode,
        "names": names,
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "workspace_source_sha256": meta["input_sha256"],
        "outer_lx_chars": len(outer),
        "inner_sha256": hashlib.sha256(inner.encode("utf-8")).hexdigest(),
        "marker_path": marker,
        "marker_token": token,
        "checkpoints": traces,
    }
    return candidate, result


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", type=pathlib.Path, required=True)
    ap.add_argument("--source", type=pathlib.Path, required=True)
    ap.add_argument("--candidate", type=pathlib.Path, required=True)
    ap.add_argument("--receipt", type=pathlib.Path, required=True)
    ap.add_argument("--marker", required=True)
    ap.add_argument("--mode", choices=("full", "start_only", "canary_only"), default="full")
    args = ap.parse_args()
    try:
        candidate, receipt = create_progress(args.source.read_bytes(), args.marker, args.repo_root.resolve(), mode=args.mode)
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(candidate)
        args.receipt.write_bytes((json.dumps(receipt, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
        print("FX_PROGRESS_20_GENERATED_NOT_NATIVE_VALIDATED", receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        failure = {"schema": "APL_GERMAN_FX_NATIVE_PROGRESS_CANDIDATE_V1",
                   "status": "GENERATION_FAILED", "native_executed": False,
                   "error": f"{type(exc).__name__}:{exc}"}
        args.receipt.write_bytes((json.dumps(failure, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
