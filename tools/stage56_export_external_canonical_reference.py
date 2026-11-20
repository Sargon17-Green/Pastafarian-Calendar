#!/usr/bin/env python3
"""Export *external* canonical reference years; never impersonate the PHP provider.

The calculation day is an essential part of the calendar's input. This exporter
requires an unmodified, exact-commit checkout of the canonical Python source.
The output is NOT accepted production input for PHP Stage56 B5.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from collections import Counter

PROJECT = "PC-BRANCH-PHP-MALAY"
CANONICAL_REPO = "Sargon17-Green/pastafari-calendar"
PROVIDER = "implementations/python/pastafari_calendar/core.py"
JS_REFERENCE = "browser/pastafari-calendar-fast.js"


def git(root: Path, *args: str) -> bytes:
    p = subprocess.run(["git", "-C", str(root), *args], capture_output=True, check=False)
    if p.returncode:
        raise ValueError(f"git {args[0]} failed (exit={p.returncode}): {p.stderr.decode(errors='replace')[:240]}")
    return p.stdout


def source_binding(root: Path, commit: str, path: str) -> dict[str, str]:
    # Compare Git's committed source bytes with bytes Python will execute.
    committed = git(root, "show", f"{commit}:{path}")
    disk = (root / path).read_bytes()
    if disk != committed:
        raise ValueError(f"Working-tree source differs from committed Git bytes: {path}")
    git_blob = hashlib.sha1(b"blob " + str(len(committed)).encode() + b"\0" + committed).hexdigest()
    advertised = git(root, "rev-parse", f"{commit}:{path}").decode().strip()
    if advertised != git_blob:
        raise ValueError(f"Git blob identity failed: {path}")
    return {"path": path, "git_blob_sha1": git_blob, "sha256": hashlib.sha256(committed).hexdigest()}


def canonical_bytes(obj: object) -> bytes:
    return (json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def check_years(years: list[dict[str, object]], anchor: dict[str, int]) -> None:
    assert [y["number"] for y in years] == [4999, 5000, 5001]
    assert years[1]["open_gate_day"] == anchor["open_gate_day"]
    for i, rec in enumerate(years):
        a, b = rec["open_gate_day"], rec["close_gate_day"]
        lengths, word = rec["month_lengths"], rec["month_weaving"]
        assert isinstance(a, int) and isinstance(b, int) and 252 <= b - a <= 5778
        assert 3 <= len(lengths) <= 47 and all(4 <= n <= 123 for n in lengths)
        assert sum(lengths) == b - a == len(word)
        assert Counter(word) == Counter({k: lengths[k - 1] for k in range(1, len(lengths) + 1)})
        first, last = {}, {}
        for pos, m in enumerate(word):
            assert isinstance(m, int) and 1 <= m <= len(lengths)
            first.setdefault(m, pos)
            last[m] = pos
        assert all(first[k] < first[k + 1] and last[k] < last[k + 1] for k in range(1, len(lengths)))
        if i:
            assert years[i - 1]["close_gate_day"] == a


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".stage56-", delete=False) as f:
        temporary = Path(f.name)
        f.write(data)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--canonical-repo", type=Path, required=True, help="Clean local checkout of the canonical repository")
    ap.add_argument("--source-commit", required=True, help="Exact, externally recorded 40-hex canonical commit")
    ap.add_argument("--calculation-jdn", type=int, required=True, help="Mandatory input; Year5000 anchor depends on it")
    ap.add_argument("--output", type=Path, required=True, help="External-reference JSON (NOT a B5 production export)")
    a = ap.parse_args()
    root = a.canonical_repo.resolve(strict=True)
    output = a.output.resolve()
    if not re.fullmatch(r"[0-9a-f]{40}", a.source_commit):
        raise ValueError("source-commit must be a lowercase full SHA-1")
    if root == output or root in output.parents:
        raise ValueError("Export must be written outside canonical Git working tree")
    origin = git(root, "remote", "get-url", "origin").decode().strip()
    permitted = {f"https://github.com/{CANONICAL_REPO}", f"https://github.com/{CANONICAL_REPO}.git", f"git@github.com:{CANONICAL_REPO}.git"}
    if origin not in permitted:
        raise ValueError("Unexpected canonical repository origin")
    head = git(root, "rev-parse", "HEAD").decode().strip()
    if head != a.source_commit:
        raise ValueError(f"Source checkout HEAD differs from pinned source commit: {head}")
    if git(root, "status", "--porcelain", "--untracked-files=all").strip():
        raise ValueError("Source checkout is not clean")
    provider_binding = source_binding(root, head, PROVIDER)
    js_binding = source_binding(root, head, JS_REFERENCE)

    # Executes the reviewed external reference source *as it exists at HEAD*.
    spec = importlib.util.spec_from_file_location("stage56_external_reference_core", root / PROVIDER)
    if spec is None or spec.loader is None:
        raise ValueError("Could not load canonical source")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    state = mod.CalculationState(a.calculation_jdn)
    year5000 = state.get_year_5000()
    candidates = [state.previous_year(year5000), year5000, state.next_year(year5000)]
    anchor = {"number": 5000, "calculation_jdn": a.calculation_jdn,
              "open_gate_index": year5000.open_index, "close_gate_index": year5000.close_index,
              "open_gate_day": year5000.start_jdn - 1}
    years = []
    for number, year in zip((4999, 5000, 5001), candidates):
        if year.number != number:
            raise ValueError("Unexpected canonical year number")
        structure = state.get_structure(year)
        years.append({"number": number, "open_gate_day": year.start_jdn - 1,
                      "close_gate_day": year.end_jdn,
                      "month_lengths": list(structure.month_lengths),
                      "month_weaving": [m + 1 for m in structure.month_weave]})
    check_years(years, anchor)
    anchor_sha = hashlib.sha256(canonical_bytes(anchor)).hexdigest()
    document = {
        "project_id": PROJECT,
        "status": "EXTERNAL_REFERENCE_NOT_PHP_PROVIDER",
        "source": {"kind": "external_canonical_reference", "repository": CANONICAL_REPO,
                   "source_commit": head, "provider": provider_binding,
                   "independent_js_reference": js_binding,
                   "js_python_semantic_parity": "NOT_ASSESSED",
                   "anchor_sha256": anchor_sha},
        "calculation_jdn": a.calculation_jdn,
        "year5000_anchor": anchor,
        "years": years,
    }
    data = canonical_bytes(document)
    digest = hashlib.sha256(data).hexdigest()
    atomic_write(output, data)
    atomic_write(output.with_suffix(output.suffix + ".sha256"), f"{digest}  {output.name}\n".encode())
    print(json.dumps({"status": "REFERENCE_ONLY_NOT_B5_PASS", "file": str(output),
                      "sha256": digest, "source_commit": head,
                      "calculation_jdn": a.calculation_jdn, "years": [4999, 5000, 5001]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError, AssertionError) as exc:
        print(f"STAGE56_EXTERNAL_REFERENCE_REJECTED: {exc}", file=sys.stderr)
        sys.exit(2)
