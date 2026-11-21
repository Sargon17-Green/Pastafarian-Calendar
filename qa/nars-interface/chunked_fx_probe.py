#!/usr/bin/env python3
"""Load a locked APL prefix in independent ⎕EC chunks; not Stage 1."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys

from lx_workspace_probe import make_canary
from stage01_fx_prefix_probe import PREFIX_HELPER, nested_fx_expression
from stage01_import_workspace import SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources

ASSERT_HELPER = [
    "z←expected Stage01ChunkAssert unused",
    "  :If Stage01PrefixCount≠expected",
    "      ⎕ERROR 'CHUNK_FX_COUNT_MISMATCH'",
    "  :EndIf",
    "  z←Stage01PrefixCount",
]

def marker_write(token: str, path: str) -> str:
    return f"(⎕UCS {_codes(token)}) ⎕NAPPEND ((⎕UCS {_codes(path)}) ⎕NCREATE 0)"

def build_chunked(raw: bytes, root: pathlib.Path, marker: str,
                  count: int = 15, chunk_size: int = 5) -> tuple[bytes, dict]:
    if count not in (15, 20) or chunk_size != 5:
        raise ValueError("CHUNK_COUNT_OR_SIZE_NOT_ALLOWED")
    locked = load_locked_sources(root)
    blocks = locked["blocks"][:count]
    names = [b["name"] for b in blocks]
    if len(blocks) != count or len(set(names)) != count:
        raise ValueError("LOCKED_PREFIX_INVALID")
    path_obj = pathlib.PureWindowsPath(marker)
    stages = []
    expressions = []
    for offset in range(0, count, chunk_size):
        after = offset + chunk_size
        parts = []
        if offset == 0:
            parts += ["⎕FX " + nested_fx_expression(PREFIX_HELPER),
                      "⎕FX " + nested_fx_expression(ASSERT_HELPER),
                      "Stage01PrefixCount←0"]
        for block in blocks[offset:after]:
            parts.append(
                f"(⎕UCS {_codes(block['name'])}) Stage01PrefixFix "
                + nested_fx_expression(fx_definition_lines(block))
            )
        point_path = str(path_obj.with_name(f"{path_obj.stem}_after_{after:02d}.txt"))
        point_token = (
            f"APL_GERMAN_FX_CHUNK_V1|SOURCE={SOURCE_COMMIT}|COUNT={count}"
            f"|SIZE={chunk_size}|AFTER={after:02d}|NAME={names[after-1]}"
        )
        parts.append(f"{after} Stage01ChunkAssert 0")
        parts.append(marker_write(point_token, point_path))
        expression = " ⋄ ".join(parts)
        expressions.append(expression)
        stages.append({
            "after": after,
            "name": names[after-1],
            "marker_path": point_path,
            "token": point_token,
            "expected_bytes": len(point_token.encode("ascii")),
            "token_sha256": hashlib.sha256(point_token.encode("ascii")).hexdigest(),
            "inner_chars": len(expression),
            "inner_sha256": hashlib.sha256(expression.encode("utf-8")).hexdigest(),
        })
    final_token = f"APL_GERMAN_NATIVE_CHUNKED_FX_{count}_PASS_SOURCE_{SOURCE_COMMIT}"
    # A separate, final controlled statement is executed only after chunk checks.
    # The native checker also requires ALL per-chunk marker tokens, not only this.
    final = f"{count} Stage01ChunkAssert 0 ⋄ " + marker_write(final_token, marker)
    expressions.append(final)
    outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(expr) for expr in expressions)
    base, meta = make_canary(raw, marker, mode="display")
    gid = meta["lx_new_global"]
    prefix = f":{gid}=V C "
    # NARS .ws.nars syntax escapes diamond separators as {diamond}.
    # This matches the established lx_workspace_probe workspace serializer.
    serialized = outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕") != outer:
        raise ValueError("OUTER_LX_SERIALIZATION_NOT_REVERSIBLE")
    if not serialized.isascii() or "'" in serialized:
        raise ValueError("UNSAFE_OUTER_EXPRESSION")
    lines = base.decode("cp1252").splitlines(keepends=True)
    found = 0
    for index, line in enumerate(lines):
        if line.startswith(prefix):
            ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
            lines[index] = f":{gid}=V C {len(outer)} 1 {len(outer)} '{serialized}'" + ending
            found += 1
    if found != 1:
        raise ValueError("LX_GLOBAL_NOT_UNIQUE")
    candidate = "".join(lines).encode("cp1252")
    receipt = {
        "schema": "APL_GERMAN_NATIVE_FX_CHUNKED_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "native_executed": False,
        "stage01": "NOT_RUN",
        "source_commit": SOURCE_COMMIT,
        "source_manifest_sha256": locked["manifest"]["manifest_sha256"],
        "count": count,
        "chunk_size": chunk_size,
        "chunk_count": len(stages),
        "names": names,
        "stages": stages,
        "marker_path": marker,
        "marker_token": final_token,
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "workspace_source_sha256": meta["input_sha256"],
        "outer_lx_chars": len(outer),
        "chunk_inner_characters": [len(x) for x in expressions],
    }
    return candidate, receipt

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--repo-root", type=pathlib.Path, required=True)
    p.add_argument("--source", type=pathlib.Path, required=True)
    p.add_argument("--candidate", type=pathlib.Path, required=True)
    p.add_argument("--receipt", type=pathlib.Path, required=True)
    p.add_argument("--marker", required=True)
    p.add_argument("--count", type=int, required=True)
    args = p.parse_args()
    try:
        candidate, receipt = build_chunked(args.source.read_bytes(), args.repo_root.resolve(),
                                           args.marker, count=args.count)
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(candidate)
        args.receipt.write_bytes((json.dumps(receipt, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
        print("CHUNKED_FX_GENERATED_NOT_NATIVE_VALIDATED", receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        fail = {"schema": "APL_GERMAN_NATIVE_FX_CHUNKED_CANDIDATE_V1",
                "status": "GENERATION_FAILED", "native_executed": False,
                "error": f"{type(exc).__name__}:{exc}"}
        args.receipt.write_bytes((json.dumps(fail, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
        print(fail["error"], file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
