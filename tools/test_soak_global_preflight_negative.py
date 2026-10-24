#!/usr/bin/env python3
"""Fail-closed fault injections for the global-soak preflight handshake.

Verify machine-readable rejection of malformed manifests, impostor programs,
missing timing, an adapter that accepts bad TSV and a nonresponding process.
These tests deliberately make no claim of calendar engine correctness.
"""
import argparse
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

FAKE_SCRIPT = r'''#!/usr/bin/env python3
import sys
import time
mode = "__VARIANT__"
args = sys.argv[1:]
if mode == "hang-schema":
    time.sleep(20)
    sys.exit(0)
if args == ["--schema"]:
    print("PASTAFARI_SOAK_TSV_V1\tid,c,t,year,cutlet,day_cutlet,month,day_month")
    sys.exit(0)
if args == ["--schema-canonical"]:
    print("PASTAFARI_SOAK_CANONICAL_V2\tid,c,t,year,cutlet_index,day_cutlet,month_index,day_month")
    sys.exit(0)
data = sys.stdin.buffer.read()
if b"0x10" in data:
    # An impostor that accepts invalid TSV must NEVER be admitted.
    sys.exit(0)
for ident in ("probe_1", "probe_2"):
    print(f"{ident}\t-15055671\t-15055671\t5000\t10\t503\t20\t56", flush=True)
    if mode != "omit-timing":
        print(f"SOAK_TIMING_NS\t{ident}\t37", file=sys.stderr, flush=True)
'''


def run_probe(program, manifest, adapter, timeout_seconds=5):
    return subprocess.run(
        [sys.executable, str(program), "--manifest", str(manifest),
         "--adapter", str(adapter), "--timeout-seconds", str(timeout_seconds)],
        capture_output=True, timeout=40, check=False,
    )


def insist_rejection(result, name):
    if result.returncode == 0:
        raise AssertionError(f"{name}: preflight falsely admitted invalid integration")
    if result.stderr:
        raise AssertionError(f"{name}: diagnostic leaked outside JSON: {result.stderr[:160]!r}")
    output = result.stdout.decode("utf-8", "strict").splitlines()
    if len(output) != 1:
        raise AssertionError(f"{name}: expected exactly one machine-readable JSON line")
    try:
        record = json.loads(output[0])
    except json.JSONDecodeError as exc:
        raise AssertionError(f"{name}: failure was not valid JSON") from exc
    if (record.get("contract") != "PASTAFARI_SOAK_PREFLIGHT_V1"
            or record.get("ready") is not False
            or record.get("global_soak_executed") is not False
            or not isinstance(record.get("reason"), str)
            or not record["reason"]):
        raise AssertionError(f"{name}: malformed fail-closed response: {record!r}")


def altered_manifest(source, route, substitute):
    bad = copy.deepcopy(source)
    target = bad
    for key in route[:-1]:
        target = target[key]
    target[route[-1]] = substitute
    return bad


def make_fake(path, variant):
    path.write_text(FAKE_SCRIPT.replace("__VARIANT__", variant), encoding="utf-8")
    path.chmod(0o700)
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("preflight")
    parser.add_argument("manifest")
    parser.add_argument("adapter")
    parser.add_argument("compiler")
    args = parser.parse_args()
    original = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    preflight = Path(args.preflight).resolve()
    adapter = Path(args.adapter).resolve()
    count = 0
    modifications = (
        ("wrong-branch", ("branch",), "other-branch"),
        ("wrong-repository", ("repository",), "other-owner/other-repo"),
        ("wrong-implementation-id", ("implementation_id",), "other-implementation"),
        ("wrong-transport", ("transport",), "argv_json"),
        ("wrong-input-fields", ("request_fields",), ["request_id"]),
        ("wrong-v1-suffix", ("response_fields",),
         original["response_fields"][:4] + ["incorrect_cutlet", "day_in_cutlet",
                                            "month_name", "day_in_month"]),
        ("shard-invalidation-disabled",
         ("integrity", "nonzero_exit_invalidates_entire_shard"), False),
        ("hard-cases-skipped",
         ("integrity", "never_silently_skip_hard_cases"), False),
        ("wrong-timing-units", ("time_series", "unit"), "milliseconds"),
        ("missing-canonical-schema",
         ("canonical_numeric", "schema_arg"), "--schema"),
        ("wrong-v2-fields", ("canonical_numeric", "response_fields"), []),
        ("wrong-catalog-source", ("canonical_numeric", "catalog"), "other/catalog.hpp"),
        ("wrong-numeric-format", ("canonical_numeric", "numeric_format"), "hexadecimal"),
        ("wrong-v2-indices",
         ("canonical_numeric", "index_ranges",), {"cutlet": [0, 17], "month": [1, 47]}),
        ("wrong-v2-options",
         ("canonical_numeric", "run_arguments"), ["--timing-ns"]),
        ("unverifiable-commit", ("engine_verified_commit",), "not-a-commit"),
    )
    with tempfile.TemporaryDirectory(prefix="cpp-latina-preflight-neg-") as folder:
        root = Path(folder)
        manifest = root / "manifest.json"
        for label, route, value in modifications:
            manifest.write_text(
                json.dumps(altered_manifest(original, route, value)),
                encoding="utf-8",
            )
            insist_rejection(run_probe(preflight, manifest, adapter), label)
            count += 1
        manifest.write_text('{"manifest_version":', encoding="utf-8")
        insist_rejection(run_probe(preflight, manifest, adapter), "invalid-json")
        count += 1
        manifest.write_text(json.dumps(original), encoding="utf-8")
        insist_rejection(
            run_probe(preflight, manifest, root / "nonexistent-binary"),
            "missing-binary",
        )
        count += 1
        # /bin/true is a valid executable but is NOT a conforming calendar.
        insist_rejection(run_probe(preflight, manifest, "/bin/true"), "no-schema")
        count += 1
        for variant in ("omit-timing", "accept-invalid", "hang-schema"):
            fake = make_fake(root / ("fake-" + variant), variant)
            insist_rejection(
                run_probe(
                    preflight, manifest, fake,
                    timeout_seconds=1 if variant == "hang-schema" else 5,
                ),
                variant,
            )
            count += 1
    print(f"SOAK_GLOBAL_PREFLIGHT_NEGATIVE={count}/{count}_PASS COMPILER={args.compiler}")
    print("SOAK_GLOBAL_PREFLIGHT_FAIL_CLOSED_JSON=PASS")


if __name__ == "__main__":
    main()
