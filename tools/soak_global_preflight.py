#!/usr/bin/env python3
"""Machine-readable readiness probe for the C++/Latina global-soak adapter.

This checks runtime transport compatibility, not calendar correctness across
implementations and not Git provenance. The orchestrator must still pin the
tested source SHA and invalidate all outputs after any nonzero shard exit.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

CONTRACT = "PASTAFARI_SOAK_PREFLIGHT_V1"
FIELDS = [
    "request_id", "calculation_day", "target_day", "year_number",
    "cutlet_index", "day_in_cutlet", "month_index", "day_in_month",
]
V1_FIELDS = [
    "request_id", "calculation_day", "target_day", "year_number",
    "cutlet_name", "day_in_cutlet", "month_name", "day_in_month",
]
DECIMAL = re.compile(rb"-?(?:0|[1-9][0-9]*)\Z")
TEST_INPUT = (
    b"probe_1\t-15055671\t-15055671\n"
    b"probe_2\t-015055671\t-015055671\n"
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def run(binary, args, input_bytes, timeout):
    try:
        return subprocess.run(
            [binary, *args], input=input_bytes, capture_output=True,
            timeout=timeout, check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ValueError("probe timed out; reject implementation until investigated") from exc


def manifest_contract(path):
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    canonical = raw.get("canonical_numeric")
    require(isinstance(canonical, dict), "missing canonical_numeric")
    require(raw.get("manifest_version") == 1, "unsupported manifest_version")
    require(raw.get("branch") == "C++&Latina", "wrong implementation branch")
    require(raw.get("repository") == "Sargon17-Green/Pastafarian-Calendar",
            "wrong implementation repository")
    require(raw.get("implementation_id") == "pastafarian-calendar-cpp-latina",
            "wrong implementation ID")
    require(raw.get("transport") == "stdin_stdout_tsv", "unsupported transport")
    require(raw.get("protocol") == "PASTAFARI_SOAK_TSV_V1", "V1 contract missing")
    require(raw.get("request_fields") == FIELDS[:3], "request fields do not match")
    require(raw.get("response_fields") == V1_FIELDS, "V1 response fields differ")
    require(raw.get("integrity", {}).get("nonzero_exit_invalidates_entire_shard") is True,
            "shard invalidation must be mandatory")
    require(raw.get("integrity", {}).get("never_silently_skip_hard_cases") is True,
            "silent skipping must be forbidden")
    require(raw.get("time_series") == {
        "stream": "stderr", "prefix": "SOAK_TIMING_NS", "unit": "ns",
    }, "unknown timing protocol")
    require(canonical.get("protocol") == "PASTAFARI_SOAK_CANONICAL_V2",
            "wrong canonical protocol")
    require(canonical.get("schema_arg") == "--schema-canonical",
            "wrong schema command")
    require(canonical.get("run_arguments") == ["--canonical-indices", "--timing-ns"],
            "canonical run arguments differ")
    require(canonical.get("response_fields") == FIELDS, "V2 fields differ")
    require(canonical.get("catalog") == "include/pastafari/source_language_catalog.hpp",
            "wrong canonical catalog source")
    require(canonical.get("numeric_format") == "ASCII decimal integers",
            "wrong canonical numeric representation")
    require(canonical.get("index_ranges") == {"cutlet": [1, 17], "month": [1, 47]},
            "canonical index bounds differ")
    commit = raw.get("engine_verified_commit", "")
    require(isinstance(commit, str) and re.fullmatch(r"[a-f0-9]{40}", commit),
            "missing/invalid verified engine commit")
    return raw


def check_banner(binary, arguments, expected, timeout):
    result = run(binary, arguments, b"", timeout)
    require(result.returncode == 0 and not result.stderr,
            "schema command failed")
    require(result.stdout.decode("ascii", "strict").strip() == expected,
            "schema announcement differs from manifest")


def verify_result(result):
    require(result.returncode == 0, "valid V2 probe exited with an error")
    require(not b"SOAK_ADAPTER_ERROR" in result.stderr, "valid probe reported error")
    records = result.stdout.splitlines()
    require(len(records) == 2, "valid probe must return exactly two rows")
    parsed = []
    for n, row in enumerate(records, 1):
        cols = row.split(b"\t")
        require(len(cols) == 8, "wrong response column count")
        require(cols[0] == f"probe_{n}".encode(), "lost or reordered request ID")
        for number in cols[1:]:
            require(DECIMAL.fullmatch(number) is not None, "noncanonical decimal output")
        require(cols[1] == b"-15055671" and cols[2] == b"-15055671",
                "leading-zero decimal not normalized as base ten")
        require(1 <= int(cols[4]) <= 17 and 1 <= int(cols[6]) <= 47,
                "index outside canonical range")
        require(int(cols[5]) > 0 and int(cols[7]) > 0,
                "nonpositive day in calendar tuple")
        parsed.append(cols)
    require(parsed[0][1:] == parsed[1][1:],
            "identical decimal (c,t) pairs returned different dates")
    timings = result.stderr.splitlines()
    require(len(timings) == 2, "missing/extra per-row timing records")
    for n, line in enumerate(timings, 1):
        cols = line.split(b"\t")
        require(len(cols) == 3 and cols[:2] == [
            b"SOAK_TIMING_NS", f"probe_{n}".encode()],
            "timing record ID/order differs")
        require(re.fullmatch(rb"[0-9]+", cols[2]) is not None,
                "invalid nanosecond timing")


def verify_rejection(binary, options, timeout):
    result = run(binary, options, b"invalid\t0x10\t0\n", timeout)
    require(result.returncode != 0, "invalid input accepted")
    require(not result.stdout, "invalid input produced an apparent result")
    require(result.stderr.startswith(b"SOAK_ADAPTER_ERROR\tline 1:"),
            "invalid input did not produce a line-specific error")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--manifest", required=True)
    p.add_argument("--adapter", required=True)
    p.add_argument("--timeout-seconds", type=int, default=300)
    args = p.parse_args()
    try:
        require(1 <= args.timeout_seconds <= 3600, "invalid probe timeout")
        manifest = manifest_contract(args.manifest)
        binary = str(Path(args.adapter).resolve())
        check_banner(
            binary, ["--schema"],
            "PASTAFARI_SOAK_TSV_V1\tid,c,t,year,cutlet,day_cutlet,month,day_month",
            args.timeout_seconds,
        )
        check_banner(
            binary, ["--schema-canonical"],
            "PASTAFARI_SOAK_CANONICAL_V2\tid,c,t,year,cutlet_index,day_cutlet,month_index,day_month",
            args.timeout_seconds,
        )
        options = manifest["canonical_numeric"]["run_arguments"]
        verify_result(run(binary, options, TEST_INPUT, args.timeout_seconds))
        verify_rejection(binary, options, args.timeout_seconds)
        output = {
            "contract": CONTRACT,
            "ready": True,
            "implementation_id": manifest["implementation_id"],
            "engine_verified_commit": manifest["engine_verified_commit"],
            "runtime_protocol": manifest["canonical_numeric"]["protocol"],
            "verified_rows": 2,
            "invalid_input_rejected": True,
            "global_soak_executed": False,
        }
    except (OSError, UnicodeError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        output = {
            "contract": CONTRACT,
            "ready": False,
            "reason": str(exc),
            "global_soak_executed": False,
        }
    print(json.dumps(output, ensure_ascii=True, sort_keys=True, separators=(",", ":")))
    return 0 if output["ready"] else 1


if __name__ == "__main__":
    sys.exit(main())
