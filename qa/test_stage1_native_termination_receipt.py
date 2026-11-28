#!/usr/bin/env python3
"""QA-only Native BF98 termination provenance regression.

A trace's 'normal' status and remaining_ips=0 are observer claims, not
independent proof of termination. For this pinned single-IP four-cell
candidate, the last physically executed instruction must be @.
"""
import json
import sys
from pathlib import Path

import stage1_native_four_cell_full_postfork_trace_audit as audit


def check(folder):
    root = Path(folder)
    candidate = (root / "four_cell_candidate.b98").read_bytes()
    audit.need(audit.gitblob(candidate) == audit.CANDIDATE,
               "Native termination probe candidate source blob drifted")
    source = candidate.split(b"\n")
    report = json.loads(
        (root / "native_full_postfork_four_pairs.json").read_text("utf-8"))
    # Replay the complete original evidence, not just an isolated selector.
    audited = audit.verify(report, source)
    audit.need(len(audited) == 4, "four real Native input pairs missing")
    rejected = 0
    for row in report["records"]:
        for side in ("control", "forced"):
            original = row[side]
            trace = original["complete_postfork_trace"]
            audit.need(trace[-1][5:7] == [ord("@"), 0],
                       "historical Native termination opcode unexpectedly changed")
            audit.need(trace[-2][5] != ord("@"),
                       "negative control needs a nonterminating predecessor")
            # The original source and every retained opcode stay untouched.
            # Only the last @ is removed and the untrusted step count is
            # shortened to match; the old verifier accepted all eight.
            forged = dict(original)
            forged["steps"] = original["steps"] - 1
            forged["complete_postfork_trace"] = trace[:-1]
            try:
                audit.verify_run(
                    forged, source,
                    require_prefork=(report["schema"] == audit.SCHEMA_V2),
                    require_gate_anchor=True)
            except AssertionError as exc:
                audit.need("without executed terminating @" in str(exc),
                           "forgery rejected for an unrelated reason: " + str(exc))
                rejected += 1
            else:
                raise AssertionError(
                    "Native trace with no executed @ accepted: " +
                    row["label"] + "/" + side)
    audit.need(rejected == 8, "Native termination falsification coverage incomplete")
    print("NATIVE_EIGHT_GENUINE_TERMINATIONS_REPLAY_PASS")
    print("NATIVE_EIGHT_MISSING_TERMINATOR_FALSIFICATIONS_REJECTED_PASS")
    print("STAGE1_OPEN=YES FULL_NATIVE_ACCEPTANCE=NO")


if __name__ == "__main__":
    audit.need(len(sys.argv) == 2,
               "usage: test_stage1_native_termination_receipt.py ARTIFACT_FOLDER")
    check(sys.argv[1])
