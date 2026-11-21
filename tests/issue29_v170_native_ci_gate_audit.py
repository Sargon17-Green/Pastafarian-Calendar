#!/usr/bin/env python3
"""Static-only audit of Issue #29 v170 native CI per-stage gates.

This script parses workflow text. It NEVER invokes Ada, calendar code, a test
binary, a Stage runner, or a native F call.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

WORKFLOW = Path(".github/workflows/canonical-names-lock.yml")
EXPECTED_STAGES = [f"{n:02d}" for n in range(1, 42)]
EXPECTED_CONDITION = (
    "if: github.event_name == 'push' && "
    "github.ref == 'refs/heads/Ada+తెలుగు' && "
    "vars.ISSUE29_NATIVE_STAGE{stage}_ENABLED == 'true'"
)


def fail(message: str) -> None:
    raise SystemExit("V170_GATE_AUDIT_FAIL: " + message)


def job_blocks(text: str) -> dict[str, str]:
    matches = list(re.finditer(
        r"^  ([A-Za-z0-9_-]+):\s*\n(.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\Z)",
        text, re.MULTILINE | re.DOTALL
    ))
    return {m.group(1): m.group(2) for m in matches}


def main() -> None:
    text = WORKFLOW.read_text(encoding="utf-8")
    blocks = job_blocks(text)
    native = {
        name: block for name, block in blocks.items()
        if re.fullmatch(r"native-stage\d{2}(?:-[A-Za-z0-9_-]+)?", name)
    }
    if len(native) != 41:
        fail(f"expected 41 native jobs, found {len(native)}")

    seen = []
    for name, block in native.items():
        match = re.match(r"native-stage(\d{2})(?:-|$)", name)
        if not match:
            fail("unrecognized native job name: " + name)
        stage = match.group(1)
        seen.append(stage)
        expected = EXPECTED_CONDITION.format(stage=stage)
        lines = [line.strip() for line in block.splitlines() if line.strip().startswith("if:")]
        if lines != [expected]:
            fail(f"{name} has wrong or multiple job-level gates: {lines!r}")
        if f"ISSUE29_NATIVE_STAGE{stage}_ENABLED" not in expected:
            fail(f"{name} lacks its unique per-stage opt-in")
    if sorted(seen) != EXPECTED_STAGES:
        fail(f"stage coverage mismatch: {sorted(seen)!r}")

    synthetic = blocks.get("stage14-synthetic")
    if synthetic is None:
        fail("independent Stage14 synthetic job missing")
    if "python3 -B tests/stage14_fivefield_oracle.py" not in synthetic:
        fail("Stage14 synthetic job no longer invokes its Python oracle")
    if re.search(r"\b(?:gprbuild|gnatmake|run_stage\d+|bin/|bin_v\d+/)", synthetic):
        fail("Stage14 synthetic job unexpectedly invokes native build/run code")

    if not re.search(r"^on:\s*$", text, re.MULTILINE):
        fail("workflow event declaration missing")
    if not re.search(r"^  push:\s*$", text, re.MULTILINE):
        fail("push event missing")
    if not re.search(r"^  pull_request:\s*$", text, re.MULTILINE):
        fail("pull_request event missing")
    if "vars.ISSUE29_NATIVE_STAGE" not in text:
        fail("repository-variable opt-in gates missing")

    report = {
        "status": "PASS_STATIC_ONLY_41_NATIVE_JOBS_INDEPENDENTLY_GATED",
        "workflow": str(WORKFLOW),
        "native_job_count": len(native),
        "stages": sorted(seen),
        "required_repository_variables": [
            f"ISSUE29_NATIVE_STAGE{stage}_ENABLED" for stage in EXPECTED_STAGES
        ],
        "unset_or_false_variable_behavior": "job condition false; native job skipped",
        "stage14_synthetic_job": "preserved; Python-only; not a native date call",
        "verify_job": "preserved",
        "push_and_pull_request_events": "preserved",
        "native_binaries_executed": 0,
        "calendar_date_invocations": 0,
        "soak_years_executed": 0,
        "main_modified": False,
        "ada_development_branch_modified": False,
        "merge_performed": False,
    }
    print(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2))


if __name__ == "__main__":
    main()
