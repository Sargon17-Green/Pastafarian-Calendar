#!/usr/bin/env python3
"""Instrument an exact temporary copy; never edit tracked production source."""
import difflib
import hashlib
import json
import subprocess
from pathlib import Path

SOURCE = Path("src/big_integer.cob")
EXPECTED_BLOB = "982c1f266a18c2bcaba79b994177a93750f27bfa"
actual_blob = subprocess.check_output(
    ["git", "rev-parse", "HEAD:src/big_integer.cob"], text=True
).strip()
assert actual_blob == EXPECTED_BLOB, (actual_blob, EXPECTED_BLOB)

original = SOURCE.read_text()
instrumented = original
old_id = "PROGRAM-ID. BIG-INTEGER-SERVICE."
assert instrumented.count(old_id) == 1
instrumented = instrumented.replace(
    old_id, "PROGRAM-ID. BIG-INTEGER-SERVICE-REAL.", 1
)

old_end = "END PROGRAM BIG-INTEGER-SERVICE."
assert instrumented.count(old_end) == 1
instrumented = instrumented.replace(
    old_end, "END PROGRAM BIG-INTEGER-SERVICE-REAL.", 1
)

fields_anchor = "01 BI-ARENA-ACTIVE PIC 9 VALUE 0.\n"
fields = fields_anchor + """01 WS-QA51B-CMD PIC X(8) VALUE SPACES.
01 WS-QA51B-TARGET PIC X(16) VALUE SPACES.
01 WS-QA51B-COUNT PIC 9(4) COMP-5 VALUE 0.
01 WS-QA51B-FAIL PIC 9(4) COMP-5 VALUE 0.
01 WS-QA51B-TRIP PIC 9 COMP-5 VALUE 0.
"""
assert instrumented.count(fields_anchor) == 1
instrumented = instrumented.replace(fields_anchor, fields, 1)

allocation_anchor = (
    "PREPEND-CHUNK-R.\n"
    "    ALLOCATE NODE-N INITIALIZED\n"
)
allocation_hook = """PREPEND-CHUNK-R.
    MOVE "CHECK" TO WS-QA51B-CMD
    MOVE "ALLOC-R" TO WS-QA51B-TARGET
    MOVE 0 TO WS-QA51B-COUNT WS-QA51B-FAIL WS-QA51B-TRIP
    CALL "QA51B-FAULT-CONTROL" USING
        WS-QA51B-CMD WS-QA51B-TARGET WS-QA51B-COUNT
        WS-QA51B-FAIL WS-QA51B-TRIP
    IF WS-QA51B-TRIP = 1
        MOVE WS-QA51B-FAIL TO LK-STATUS
        EXIT PARAGRAPH
    END-IF
    ALLOCATE NODE-N INITIALIZED
"""
assert instrumented.count(allocation_anchor) == 1
instrumented = instrumented.replace(allocation_anchor, allocation_hook, 1)

work = Path("work")
evidence = Path("build")
work.mkdir(exist_ok=True)
evidence.mkdir(exist_ok=True)
output = work / "big_integer_real.cob"
output.write_text(instrumented)

diff = difflib.unified_diff(
    original.splitlines(True),
    instrumented.splitlines(True),
    fromfile="tracked/src/big_integer.cob",
    tofile="temporary/work/big_integer_real.cob",
)
(evidence / "instrumented-source.diff").write_text("".join(diff))
sha = hashlib.sha256(output.read_bytes()).hexdigest()
(evidence / "instrumentation.json").write_text(json.dumps({
    "schema": "COBOL_QA51B_TEMPORARY_INSTRUMENTATION/1",
    "tracked_git_blob": actual_blob,
    "tracked_source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    "temporary_source_sha256": sha,
    "program_id_renamed": True,
    "hook": "one-shot ALLOC-R failure before second PREPEND-CHUNK-R allocation",
    "hook_scope": "temporary test-build copy only",
    "tracked_production_source_changed": False,
    "true_runtime_oom_claimed": False
}, indent=2) + "\n")
print("QA51B_INSTRUMENTED_COPY_OK", sha)
