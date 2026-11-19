# Stage56 B5 — genuine-year profile preflight (not actual-year acceptance)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Status: source-independent preflight candidate. No trusted year-structure export provided.
Predecessor: B4 Native accepted on c4ed57dc3785d253ed980ee4197eeb379e1799ed, run #44393768083, 30/30; see artifacts/STAGE56_PHASE_B4_NATIVE_CLOSURE_2026-11-19.md.

## Why B5 exists
Production DateTuplePatch23 uses an injected yearStructureProvider; no authorized standalone production YearStructureProvider and no authenticated Year5000 anchor or canonical input records for 4999/5000/5001 are present in this branch. The B4 synthetic-domain microgate is not an actual-year benchmark. Do not substitute test oracle/fixtures.

## Input contract and independent trust boundary
tests/stage56_actual_year_profile.php takes exactly three CLI arguments: an export JSON path, an out-of-band pinned SHA-256 of that exact JSON, and one year (4999|5000|5001). It expects JSON object keys:
- project_id = PC-BRANCH-PHP-MALAY
- source = {kind:"production_export", provider_path:string, source_commit:40-hex, provider_sha256:64-hex, anchor_sha256:64-hex}
- year5000_anchor = {number:5000,open_gate_day:int}
- years = ordered records for 4999,5000,5001, each {number:int,open_gate_day:int,close_gate_day:int,month_lengths:list<int>,month_weaving:list<int>}.

The exporter must independently derive these records from a *reviewed* production provider with independently checked anchor identity, and archive its source, parameters, origin, exact commit and digest. The preflight checks structure, bounds, adjacency, count totals, and ascending first/last occurrences, plus input ZIP/JSON hash binding. It DOES NOT authenticate whether claimed source, hash, or anchor belongs to the canonical production generator: those source fields are claims until reviewed. A hash of an arbitrary fixture does not prove authenticity. Neither valid input structure nor a benchmark result constitutes acceptance without independent source-provenance review.

## Exact measurement and bound
Execute each year in a fresh PHP 8.3 64-bit process, under an external 900s timeout and PHP memory_limit=512M, for example:

timeout 900s php -d memory_limit=512M tests/stage56_actual_year_profile.php production-years.json PINNED_SHA256 4999

Repeat separately for 5000 and 5001. The tool measures exact B4 BigInt count, rank and inverse unrank on the provided year weaving; asserts roundtrip, reports step durations, peak bytes and rank digit counts, with provenance UNATTESTED_REQUIRES_INDEPENDENT_REVIEW and result PROFILE_ONLY_NOT_STAGE56_ACCEPTANCE. The script also self-checks 900s/512MiB, but the external timeout is mandatory for bounding stalled operations.

## Preflight microgate (no actual-year run)
tests/stage56_actual_year_profile_preflight_tests.php constructs one explicitly synthetic, structurally valid three-year sample, plus 15 invalid mutations: project, source type/path/hash, anchor ID/value, year count/order/continuity, weaving length, month range/sum/ID/count and first-appearance order. It tests only the validator and does NOT invoke the expensive ranker on this invented sample. Local PHP 8.4.24 syntax 2/2 PASS; 16 validator checks PASS. This is not PHP 8.3 Native nor provenance proof. The canonical feature-branch CI includes a separate B5 preflight Native job after this commit.

## Gate
1. Run B5 preflight Native CI and confirm full-run completed/log/ZIP on the exact SHA.
2. Locate and independently review real production provider + Year5000 anchor; export source-bound actual 4999/5000/5001 inputs.
3. Run exact 3-year profiles, preserving original JSON SHA and logs; compare <=512MiB/900s separately. If O(mL²) fails, derive an independently proven state-updatable adjoint; no PATCH22/PATCH23 integration before that gate.
4. Stage56 remains IN_PROGRESS; no main/merge, no green for real-year profiling.

