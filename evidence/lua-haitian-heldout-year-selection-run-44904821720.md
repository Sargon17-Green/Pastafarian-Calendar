# Lua Haitian held-out Native year-selection: verified receipt

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Authorized branch: `Lua+Kreyòl-ayisyen`
**Tested source commit:** `4f9816f0ac3de0847f8c88237359848a41301484`
**Run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904821720
**Focused job:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904821720/job/136848032736
**Evidence ZIP:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904821720/artifacts/14707099185
**Evidence ZIP SHA-256:** `3b9dc8e606687c5cf02393646116d9c1112f21936b00e78938f499d9888e2156`

## Verified observations

- Branch ref was `4f9816f0ac3de0847f8c88237359848a41301484` during verification. The tested commit had parent `0a6cd90ece555655f4cb5225458710d490e607f4`, changing five QA/CI/documentation files and no production Lua source.
- Workflow run 44904821720: `completed/success`, head branch `Lua+Kreyòl-ayisyen`, head SHA as above. Focused job 136848032736: `completed/success` and each of eight named verification/execution/receipt steps succeeded. The job's own log includes the exact differential success marker.
- Artifact metadata agrees with the tested SHA and ZIP digest. ZIP CRC check returned no errors; inventory has 15 files including `SHA256SUMS.txt`; **all 14/14 listed member SHA-256 hashes match**, with no extra or missing unlisted payload members.
- `manifest.txt` fixes project, branch, day, source SHA and resource caps. Python, native Lua 5.3 and differential verifier raw exit codes are each **0**; all three stderr files are **empty**.
- Python frozen output: `STATIC_PYTHON_SELFTEST: 16/16 PASS` and report hash `89fae158fad5cb09fb320cef76ef801855002422624bacc135cbe34785410caf`. Verifier mutation controls: `14/14 PASS`.
- Native day `-15017676`, year 5000, candidate count **69**, one-based selected rank **56**, chosen gate indices **71..82**, opening day `-15018117`, closing day `-15012823`, interval length **5294 days**, gap calls **85**, minimum months **44**, reason `MIN_MONTHS_OVER_CAP`. These fields agree with the independently implemented frozen Python selection.
- GNU-time receipt: wall **55.03 s** (cap 120), CPU **54.95 s** (cap 110), maximum RSS **3816 KiB** (cap 131072); Lua internal CPU **54.928377 s**. Native gap calls **85** (cap 200). `verification_stdout.txt`: `HELDOUT_NATIVE_DIFFERENTIAL: PASS day=-15017676 rank=56/69 gates=71..82`.
- **Accepted scope:** **one held-out year-selection differential only**, on the tested source SHA. Composition **NOT_INVOKED**, full-date **NOT_RUN**. No Stage56 acceptance, release or merge. This comparison tests implementation agreement with the same normative source, not whether that normative source is correct.

## Feasibility finding and next authorized step

A 5294-day selected interval requires `ceil(5294/123) = 44` months at the bound used by this test, exceeding the 16-month cap. This is **not** a success result for full-year composition; neither this witness nor Python's independent prediction establishes that a compliant alternative was selected.

**NEXT:** statically audit the source-defined year-selection/composition boundary and fail-closed treatment of this already established over-cap witness. Specify a separate, measurable composition oracle and rejection criterion grounded in the normative source; do not change the normative rules, assume a successful full-date result, rerun accepted exact-SHA evidence, create Stage56, or touch main. If a product defect is demonstrated, correct it in the authorized branch with independently specified tests and a fresh source lock. Keep canonical CI and held-out differential gates separately classified.

Receipt generated after the completed run from job logs and independently inspected original artifact bytes. The commit recording this report is documentation-only, **not** a new Native certification of that later commit.
