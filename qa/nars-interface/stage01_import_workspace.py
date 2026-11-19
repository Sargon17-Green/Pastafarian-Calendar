#!/usr/bin/env python3
"""Build a fail-closed native NARS2000 Stage 1 importer from the locked five APL files."""
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys

from lx_workspace_probe import make_canary

SOURCE_COMMIT = "7161824b9fcbfaca91f20d1ea492417e77003ff4"
EXPECTED_TOTAL_FUNCTIONS = 95
SOURCE_FILES = [
    ("src/monster_bootstrap.apl", "cb94d203116afa32fb55b8ff74b8569d6e03d02c", 13),
    ("src/normative_oracle.apl", "d1dd480d9a5122df2d77eba92b6ce246f5a88c91", 69),
    ("src/source_language_catalog.apl", "f47575e1c32d915836fb96556b64b58226b90005", 6),
    ("test/stage01_fixtures.apl", "a6aa84274aa2880b053d5dd221b1654dbbd70a2c", 1),
    ("test/stage01_tests.apl", "3371f1575da8c03cb4175b0031f244ee1757ed00", 6),
]
HELPER_LINES = [
    "z←name Stage01Fix source;fixed",
    "  fixed←⎕FX source",
    "  :If ~name≡fixed",
    "      ⎕←'STAGE01_FX_IMPORT_FAILED: ',name",
    "      ⎕ERROR 'STAGE01_FX_IMPORT_FAILED'",
    "  :EndIf",
    "  Stage01FXCount←Stage01FXCount+1",
    "  z←fixed",
]
COUNT_HELPER_LINES = [
    "Stage01CheckFXCount",
    "  :If Stage01FXCount≠95",
    "      ⎕ERROR 'STAGE01_FX_COUNT_MISMATCH'",
    "  :EndIf",
]


def _run_git(repo_root: pathlib.Path, *args: str) -> bytes:
    p = subprocess.run(
        ["git", *args], cwd=repo_root, check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    return p.stdout


def _git_blob_sha(raw: bytes) -> str:
    header = b"blob " + str(len(raw)).encode("ascii") + b"\0"
    return hashlib.sha1(header + raw).hexdigest()


def _function_name(header: str) -> str:
    if not header.startswith("∇"):
        raise ValueError("FUNCTION_HEADER_MISSING_NABLA")
    signature = header[1:].strip().split(";", 1)[0].strip()
    if "←" in signature:
        signature = signature.split("←", 1)[1].strip()
    tokens = signature.split()
    if len(tokens) in (1, 2):
        name = tokens[0]
    elif len(tokens) == 3:
        name = tokens[1]
    else:
        raise ValueError("UNSUPPORTED_FUNCTION_HEADER:" + header)
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", name):
        raise ValueError("INVALID_FUNCTION_NAME:" + name)
    return name


def parse_function_blocks(text: str, path: str) -> list[dict]:
    blocks = []
    active = None
    for line_no, line in enumerate(text.splitlines(), 1):
        if active is None:
            if line.startswith("∇") and line.strip() != "∇":
                active = {"header": line, "lines": [line], "start_line": line_no}
            elif line.strip() and not line.lstrip().startswith("⍝"):
                raise ValueError(f"TOP_LEVEL_EXECUTABLE_TEXT:{path}:{line_no}")
        else:
            active["lines"].append(line)
            if line.strip() == "∇":
                active["end_line"] = line_no
                active["name"] = _function_name(active["header"])
                blocks.append(active)
                active = None
    if active is not None:
        raise ValueError(f"UNCLOSED_FUNCTION:{path}:{active['start_line']}")
    return blocks


def load_locked_sources(repo_root: pathlib.Path, source_commit: str = SOURCE_COMMIT) -> dict:
    if source_commit != SOURCE_COMMIT:
        raise ValueError("UNEXPECTED_SOURCE_COMMIT")
    # The source commit must be an ancestor of this QA checkout.
    _run_git(repo_root, "merge-base", "--is-ancestor", source_commit, "HEAD")
    files = []
    all_names = []
    all_blocks = []
    for path, expected_blob, expected_count in SOURCE_FILES:
        raw = _run_git(repo_root, "show", f"{source_commit}:{path}")
        blob = _git_blob_sha(raw)
        head_blob = _run_git(repo_root, "rev-parse", f"HEAD:{path}").decode("ascii").strip()
        if blob != expected_blob or head_blob != expected_blob:
            raise ValueError(f"SOURCE_BLOB_LOCK_MISMATCH:{path}:{blob}:{head_blob}")
        text = raw.decode("utf-8", errors="strict")
        blocks = parse_function_blocks(text, path)
        names = [b["name"] for b in blocks]
        if len(blocks) != expected_count:
            raise ValueError(f"SOURCE_FUNCTION_COUNT_MISMATCH:{path}:{len(blocks)}:{expected_count}")
        files.append({
            "path": path,
            "git_blob_sha1": blob,
            "file_sha256": hashlib.sha256(raw).hexdigest(),
            "function_count": len(blocks),
            "function_names": names,
        })
        all_names.extend(names)
        for block in blocks:
            all_blocks.append({
                "path": path,
                "name": block["name"],
                "lines": block["lines"],
                "start_line": block["start_line"],
                "end_line": block["end_line"],
            })
    if len(all_blocks) != EXPECTED_TOTAL_FUNCTIONS:
        raise ValueError(f"TOTAL_FUNCTION_COUNT_MISMATCH:{len(all_blocks)}")
    if len(set(all_names)) != EXPECTED_TOTAL_FUNCTIONS:
        raise ValueError("FUNCTION_NAMES_NOT_UNIQUE")
    if "RunStage01Tests" not in all_names:
        raise ValueError("STAGE01_ENTRYPOINT_MISSING")
    test_block = next(b for b in all_blocks if b["name"] == "RunStage01Tests")
    test_text = "\n".join(test_block["lines"])
    for init_name in ("SourceLanguageCatalogInit", "MonsterBootstrapInit", "OracleInit", "Stage01FixturesInit"):
        if init_name not in test_text:
            raise ValueError("STAGE01_INIT_SEQUENCE_MISSING:" + init_name)
    if "STAGE01 PASS" not in test_text:
        raise ValueError("STAGE01_PASS_SENTINEL_MISSING")
    manifest = {
        "schema": "APL_GERMAN_STAGE01_SOURCE_MANIFEST_V1",
        "source_commit": source_commit,
        "source_branch": "APL+Deutsch",
        "ordered_files": files,
        "function_count": len(all_blocks),
        "unique_function_count": len(set(all_names)),
        "ordered_function_names": all_names,
        "test_entrypoint": "RunStage01Tests",
        "test_initializers": ["SourceLanguageCatalogInit", "MonsterBootstrapInit", "OracleInit", "Stage01FixturesInit"],
    }
    canonical = json.dumps(manifest, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    manifest["manifest_sha256"] = hashlib.sha256(canonical).hexdigest()
    return {"manifest": manifest, "blocks": all_blocks}


def _codes(text: str) -> str:
    values = [ord(ch) for ch in text]
    if any(value < 0x20 or value > 0xFFFF for value in values):
        raise ValueError("APL_PROGRAM_CHARACTER_OUTSIDE_NARS_BMP")
    return " ".join(str(value) for value in values)


def _matrix_expression(lines: list[str]) -> str:
    if not lines:
        raise ValueError("EMPTY_APL_FUNCTION")
    cols = max(len(line) for line in lines)
    if cols < 1:
        raise ValueError("EMPTY_APL_FUNCTION_LINE")
    rows = len(lines)
    flat = "".join(line.ljust(cols) for line in lines)
    return f"({rows} {cols}⍴⎕UCS {_codes(flat)})"


def fx_definition_lines(block: dict) -> list[str]:
    """Convert editor-style ∇ ... ∇ to NARS ⎕FX header-and-body input."""
    source = block["lines"]
    if len(source) < 3 or not source[0].startswith("∇") or source[-1].strip() != "∇":
        raise ValueError("FX_BLOCK_MISSING_EDITOR_DELIMITERS:" + block["name"])
    header = source[0][1:].strip()
    if _function_name(source[0]) != block["name"]:
        raise ValueError("FX_BLOCK_HEADER_NAME_MISMATCH:" + block["name"])
    body = source[1:-1]
    if any(line.strip() == "∇" for line in body):
        raise ValueError("FX_BLOCK_NESTED_EDITOR_DELIMITER:" + block["name"])
    return [header] + body


def build_inner_program(loaded: dict, marker_path: str) -> tuple[str, str]:
    manifest = loaded["manifest"]
    blocks = loaded["blocks"]
    if len(blocks) != EXPECTED_TOTAL_FUNCTIONS:
        raise ValueError("FX_IMPORT_COUNT_NOT_95")
    token = (
        "APL_GERMAN_STAGE01_NATIVE_PASS_V1"
        f"|SOURCE={SOURCE_COMMIT}|FILES=5|FX=95|TEST=STAGE01_PASS"
    )
    parts = [
        "⎕FX " + _matrix_expression(HELPER_LINES),
        "⎕FX " + _matrix_expression(COUNT_HELPER_LINES),
        "Stage01FXCount←0",
    ]
    for block in blocks:
        parts.append(
            f"(⎕UCS {_codes(block['name'])}) Stage01Fix "
            + _matrix_expression(fx_definition_lines(block))
        )
    parts.extend([
        "Stage01CheckFXCount",
        "RunStage01Tests",
        f"(⎕UCS {_codes(token)}) ⎕NAPPEND ((⎕UCS {_codes(marker_path)}) ⎕NCREATE 0)",
    ])
    inner = " ⋄ ".join(parts)
    outer = "⎕EC ⎕UCS " + _codes(inner)
    if "'" in outer or '"' in outer:
        raise ValueError("OUTER_LX_EXPRESSION_NOT_QUOTE_FREE")
    return outer, token


def make_stage01_candidate(raw_workspace: bytes, marker_path: str, repo_root: pathlib.Path) -> tuple[bytes, dict, dict]:
    loaded = load_locked_sources(repo_root)
    outer, token = build_inner_program(loaded, marker_path)
    base, base_meta = make_canary(raw_workspace, marker_path, mode="display")
    serialized = outer.replace("⎕", "{quad}")
    if not serialized.isascii():
        raise ValueError("OUTER_LX_SERIALIZATION_NOT_ASCII")
    global_id = base_meta["lx_new_global"]
    prefix = f":{global_id}=V C "
    lines = base.decode("cp1252").splitlines(keepends=True)
    found = 0
    for index, line in enumerate(lines):
        if not line.startswith(prefix):
            continue
        ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
        body = line[:-len(ending)] if ending else line
        if not body.endswith("'") or body.count("'") != 2:
            raise ValueError("STAGE01_LX_GLOBAL_LITERAL_CONTRACT_MISMATCH")
        lines[index] = f":{global_id}=V C {len(outer)} 1 {len(outer)} '{serialized}'" + ending
        found += 1
    if found != 1:
        raise ValueError("STAGE01_LX_GLOBAL_NOT_UNIQUE")
    candidate = "".join(lines).encode("cp1252")
    manifest = loaded["manifest"]
    manifest_bytes = json.dumps(manifest, ensure_ascii=False, indent=2).encode("utf-8") + b"\n"
    receipt = {
        "schema": "APL_GERMAN_STAGE01_IMPORT_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "native_executed": False,
        "source_commit": SOURCE_COMMIT,
        "source_file_count": len(manifest["ordered_files"]),
        "function_count": manifest["function_count"],
        "unique_function_count": manifest["unique_function_count"],
        "test_entrypoint": "RunStage01Tests",
        "test_initializers": manifest["test_initializers"],
        "source_manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
        "workspace_source_sha256": base_meta["input_sha256"],
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "outer_lx_sha256": hashlib.sha256(outer.encode("utf-8")).hexdigest(),
        "outer_lx_characters": len(outer),
        "inner_program_sha256": hashlib.sha256(build_inner_program(loaded, marker_path)[0].encode("utf-8")).hexdigest(),
        "inner_program_characters": len(build_inner_program(loaded, marker_path)[0]),
        "serialized_workspace_characters": len(serialized),
        "lx_previous_global": base_meta["lx_previous_global"],
        "lx_new_global": global_id,
        "marker_path": marker_path,
        "marker_token": token,
        "function_names": manifest["ordered_function_names"],
    }
    return candidate, manifest, receipt


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--source-workspace", required=True, type=pathlib.Path)
    parser.add_argument("--candidate", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    parser.add_argument("--receipt", required=True, type=pathlib.Path)
    parser.add_argument("--marker-path", required=True)
    args = parser.parse_args()
    try:
        candidate, manifest, receipt = make_stage01_candidate(
            args.source_workspace.read_bytes(), args.marker_path, args.repo_root.resolve()
        )
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(candidate)
        # On Windows, Path.write_text() translates LF to CRLF. The receipt
        # commits to exact serialized UTF-8 bytes, not platform-normalized
        # line endings. Write bytes directly to keep hashes reproducible.
        args.manifest.write_bytes((json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
        args.receipt.write_bytes((json.dumps(receipt, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
        print("STAGE01_CANDIDATE_ONLY", receipt["candidate_sha256"], "FUNCTIONS=95")
        return 0
    except Exception as exc:
        failure = {
            "schema": "APL_GERMAN_STAGE01_IMPORT_CANDIDATE_V1",
            "status": "GENERATION_FAILED",
            "native_executed": False,
            "error": f"{type(exc).__name__}:{exc}",
        }
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_bytes((json.dumps(failure, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
