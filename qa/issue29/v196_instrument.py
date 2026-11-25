#!/usr/bin/env python3
"""Generate an instrumented copy of the pinned GMP package; never edit source in place."""
import hashlib, json, subprocess, sys
from pathlib import Path

SOURCE_BLOB = "947c3325b705d61504f09dc1d46275ed14f52249"
path = Path(sys.argv[1])
original = path.read_text()
actual = subprocess.check_output(
    ["git", "rev-parse", "HEAD:src/canonical_full_weave_gmp_v164.adb"],
    text=True,
).strip()
assert actual == SOURCE_BLOB, (actual, SOURCE_BLOB)
assert hashlib.sha1(("blob " + str(len(path.read_bytes())) + "\0").encode() + path.read_bytes()).hexdigest() == SOURCE_BLOB

changes = [
    (
        "with GNATCOLL.GMP;\n",
        "with GNATCOLL.GMP;\nwith Issue29_V196_Hooks;\n",
        "hook import",
    ),
    (
        "         if F.H (I) /= null then\n            Free_Row (F.H (I));\n",
        "         if F.H (I) /= null then\n            Issue29_V196_Hooks.Note_Free;\n            Free_Row (F.H (I));\n",
        "Finalize free counter",
    ),
    (
        "      F.H (F.Month_Count) :=\n        new Big_Row (0 .. F.Prefix (F.Month_Count));\n",
        "      F.H (F.Month_Count) :=\n        new Big_Row (0 .. F.Prefix (F.Month_Count));\n      Issue29_V196_Hooks.Note_Allocation (Terminal => True);\n",
        "terminal allocation injection",
    ),
    (
        "            F.H (I) := new Big_Row (0 .. F.Prefix (I));\n",
        "            F.H (I) := new Big_Row (0 .. F.Prefix (I));\n            Issue29_V196_Hooks.Note_Allocation (Terminal => False);\n",
        "lower allocation injection",
    ),
]
instrumented = original
for old, new, label in changes:
    assert instrumented.count(old) == 1, (label, instrumented.count(old))
    instrumented = instrumented.replace(old, new, 1)
path.write_text(instrumented)
diff_result = subprocess.run(
    ["git", "diff", "--no-index", "--", "/dev/null", str(path)],
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
assert diff_result.returncode in (0, 1), diff_result.stdout
patch = diff_result.stdout
Path("evidence").mkdir(exist_ok=True)
Path("evidence/instrumented-package-body.diff").write_text(patch)
Path("evidence/instrumented-package-body.sha256").write_text(
    hashlib.sha256(path.read_bytes()).hexdigest() + "\n"
)
Path("evidence/instrumentation.json").write_text(json.dumps({
    "source_git_blob": SOURCE_BLOB,
    "instrumented_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    "insertions": [label for _, _, label in changes],
    "production_tree_modified": False,
    "failure_hooks": 2,
    "allocation_and_free_counters": True,
}, indent=2) + "\n")
print("V196_INSTRUMENTATION_OK", hashlib.sha256(path.read_bytes()).hexdigest())
