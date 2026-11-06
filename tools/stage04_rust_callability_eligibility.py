#!/usr/bin/env python3
"""Bounded executed callability check for a pinned pre-Stage4 Rust source.

Only an actually compiled and invoked historical Rust function can be marked
callable. SOURCE_ONLY is not proof of global absence; no outcome asserts RED.
"""
from __future__ import annotations

import argparse
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile
import tomllib

from stage04_rust_witness_provenance import ProvenanceError, checked_rust_path, git, verify_pin

F = -15_055_671
IDENT = re.compile(r"[A-Za-z_][A-Za-z_0-9]*\Z")
MARKER = re.compile(r"STAGE04_OLD_RUST_CALLABILITY_OUTPUT=(-?\d+),(-?\d+),(-?\d+)(?=\s|$)")

class RuntimeUnverified(RuntimeError):
    pass

def validated_symbol(path: str, symbol: str) -> str:
    checked_rust_path(path)
    parts = symbol.split("::")
    if not parts or not all(IDENT.fullmatch(p) for p in parts):
        raise ProvenanceError("invalid Rust symbol path")
    relative = Path(path).relative_to("src")
    if relative == Path("lib.rs"):
        expected = []
    elif relative.name == "mod.rs":
        expected = list(relative.parts[:-1])
    else:
        expected = list(relative.with_suffix("").parts)
    if parts[:-1] != expected:
        raise ProvenanceError("symbol must map directly to pinned Rust file")
    return symbol

def supported_signature(source: str, function: str) -> bool:
    # Conservative eligibility for a directly exported day-tag BigInt API.
    # Compiling and invoking the historical source is the definitive check.
    return bool(re.search(r"(?m)^\s*pub\s+fn\s+" + re.escape(function) +
        r"\s*\(\s*[A-Za-z_][A-Za-z_0-9]*\s*:\s*&\s*BigInt\s*\)\s*->\s*BigInt\b", source))

def test_body(crate: str, symbol: str) -> str:
    # Interpolate names once: no placeholder token is allowed to rewrite an
    # otherwise valid Rust crate or function identifier.
    return (
        "use num_bigint::BigInt;\n"
        "#[test]\n"
        "fn historical_rust_daytag_callable() {\n"
        f"    let old: fn(&BigInt) -> BigInt = {crate}::{symbol};\n"
        f"    let a = old(&BigInt::from({F - 1}));\n"
        f"    let b = old(&BigInt::from({F}));\n"
        f"    let c = old(&BigInt::from({F + 1}));\n"
        '    println!("STAGE04_OLD_RUST_CALLABILITY_OUTPUT={},{},{}", a,b,c);\n'
        "}\n"
    )

def archive(repo: Path, commit: str, dest: Path) -> None:
    try:
        r = subprocess.run(["git", "-C", str(repo), "archive", "--format=tar", commit],
                           capture_output=True, timeout=20, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeUnverified("cannot fetch historical snapshot") from exc
    if r.returncode != 0 or len(r.stdout) > 8_000_000:
        raise RuntimeUnverified("historical archive unavailable or too large")
    try:
        with tarfile.open(fileobj=io.BytesIO(r.stdout), mode="r:") as t:
            members = t.getmembers()
            if any(m.issym() or m.islnk() or m.isdev() or
                   Path(m.name).is_absolute() or ".." in Path(m.name).parts for m in members):
                raise RuntimeUnverified("unsafe historic archive entry")
            t.extractall(dest, filter="data")
    except (tarfile.TarError, OSError) as exc:
        raise RuntimeUnverified("unpack failed") from exc

def check_callability(repo: Path, witness_commit: str, witness_path: str,
                      witness_blob: str, stage3_closure: str,
                      stage4_introduction: str, branch_head: str,
                      symbol: str, timeout: int = 300) -> dict[str, object]:
    if not 1 <= timeout <= 300:
        raise ProvenanceError("runtime bound must be 1..300 seconds")
    pin = verify_pin(repo, witness_commit, witness_path, witness_blob,
                     stage3_closure, stage4_introduction, branch_head)
    symbol = validated_symbol(witness_path, symbol)
    verdict = dict(pin, symbol=symbol, callable_numeric_function_verified=False,
                   callable_day_tag_route_verified=False,
                   observed_runtime_red=False, stage04_closure="NOT_CLAIMED")
    old_source = git(repo, "show", f"{witness_commit}:{witness_path}")
    if not supported_signature(old_source, symbol.split("::")[-1]):
        verdict["callability_status"] = "SOURCE_ONLY_NO_SUPPORTED_SIGNATURE"
        return verdict
    with tempfile.TemporaryDirectory(prefix="rust_az_stage04_callability_") as tmp:
        dest = Path(tmp)
        archive(repo, witness_commit, dest)
        cargo = dest / "Cargo.toml"
        if not cargo.is_file():
            raise RuntimeUnverified("pinned snapshot lacks Cargo.toml")
        try:
            manifest = tomllib.loads(cargo.read_text(encoding="utf-8"))
            crate = manifest.get("lib", {}).get("name",
                     manifest.get("package", {}).get("name", "").replace("-", "_"))
        except (ValueError, OSError) as exc:
            raise RuntimeUnverified("invalid pinned Cargo manifest") from exc
        if not isinstance(crate, str) or not IDENT.fullmatch(crate):
            raise RuntimeUnverified("invalid pinned crate name")
        (dest / "tests").mkdir(exist_ok=True)
        (dest / "tests" / "stage04_callability_gate.rs").write_text(
            test_body(crate, symbol), encoding="utf-8")
        env = dict(os.environ, CARGO_TARGET_DIR=str(dest / "target"))
        try:
            run = subprocess.run(["cargo", "test", "--manifest-path", str(cargo),
                   "--test", "stage04_callability_gate", "--", "--nocapture"],
                   capture_output=True, text=True, check=False, timeout=timeout, env=env)
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise RuntimeUnverified("native historical Rust test did not complete") from exc
        if run.returncode:
            raise RuntimeUnverified("native historical build/run failed (exit %d): %s" %
                                   (run.returncode, (run.stderr + run.stdout)[-700:]))
        matches = MARKER.findall(run.stdout)
        if len(matches) != 1 or "1 passed; 0 failed" not in run.stdout:
            raise RuntimeUnverified("native test lacked unique execution evidence")
        verdict["observed_outputs"] = [int(n) for n in matches[0]]
        verdict["callability_status"] = "EXECUTED_PINNED_RUST_PRODUCTION_FUNCTION"
        # Execution verifies a pinned numeric function, not its day-tag semantics.
        verdict["callable_numeric_function_verified"] = True
        return verdict

def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo", type=Path, default=Path("."))
    for arg in ("witness-commit", "witness-path", "witness-blob",
                "stage3-closure", "stage4-introduction", "branch-head", "symbol"):
        p.add_argument("--"+arg, required=True)
    p.add_argument("--timeout", type=int, default=300)
    a = p.parse_args()
    try:
        result = check_callability(a.repo, a.witness_commit, a.witness_path, a.witness_blob,
                                   a.stage3_closure, a.stage4_introduction,
                                   a.branch_head, a.symbol, a.timeout)
        code = 0
    except ProvenanceError as exc:
        result = dict(source_pin_eligible=False, callable_numeric_function_verified=False,
                      callable_day_tag_route_verified=False,
                      observed_runtime_red=False, stage04_closure="NOT_CLAIMED",
                      callability_status="SOURCE_INELIGIBLE", reason=str(exc))
        code = 2
    except RuntimeUnverified as exc:
        result = dict(source_pin_eligible=True, callable_numeric_function_verified=False,
                      callable_day_tag_route_verified=False,
                      observed_runtime_red=False, stage04_closure="NOT_CLAIMED",
                      callability_status="RUNTIME_UNVERIFIED", reason=str(exc))
        code = 3
    print(json.dumps(result, sort_keys=True))
    return code

if __name__ == "__main__":
    sys.exit(main())
