# DISCOVERY24 — iterative canonical suffix-interval QA (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: Clojure+Nederlands
Scope: TEST/QA ONLY; Stage 2 OPEN.

## Immutable inputs and exact-source checks
- Previous branch HEAD c841b9f4959af2f0d06c4aa991fb746299ed4b96; QA script commit f96477ade5bd348d7a39babb723a8d5770db15d2 [skip ci].
- Script qa/clojure-dutch/discovery24_iterative_canonical_interval_qa.py: local SHA256 bb0e5a372baae125ce2a7c25cf34c28ab7526fd6257e014e8f486b288e74302c; local Git blob 820a58b5794ef18cd384991675a247d749dbc984 = GitHub fetched blob; 10,621 bytes.
- Earlier immutable source ec0051ec6335fe178c03bcf3583b3dbfec1ffa84, https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365: verify 137340625261 completed SUCCESS; isolated DP 137340625561 completed SUCCESS but DP_FEASIBILITY_UNPROVEN; full Native 137340626593 SKIPPED.
- Downloaded original artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365/artifacts/14770898411; ZIP SHA256 eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5 (12,468 bytes). Parsed canonical input JSON SHA256 25af5f3f21262c1fa29b8e495d0fd6be3942c5b9bdf3bb15529ee441920f947c and result JSON SHA256 8a315b22b903e64a1733f2e5f77aa07a85fd8d398105ad3aad2fc05ef64ed8ce.
- Independently checked all five blob SHAs against the exact source commit tree: test/pastafari/normative_oracle.clj 5b2f486a12aeb8ff3cea0d762ba26882d67fb4cc; src/pastafari/maandlengtes.clj 7f87252e1bf17425e2bad73b3c56531f309e059e; src/pastafari/maandaantal.clj 166b87a11124f0be4594a4b537c1e87d336ba659; src/pastafari/maandweving.clj e3954a4742414435f85c95955f0d319d136877d2; src/pastafari/maandrang.clj 62f304dc013a9a9f70475bb0d34f186838b27318.
- Artifact canonical input: 33 months, 3569 days, 5288-digit rank, 128 search budget, production and normative identities recorded true. This new Python QA does NOT independently re-execute normative Clojure computations: it verifies the original artifact SHA and source blob identity, then performs independent suffix combinatorics.

## Independent algorithm, measurable contract
- Input: independently enumerated small legal words or the original exact-SHA artifact ZIP. Optional QA expansion cap 0..10000 (4096 used). Production budget remains 5000000.
- Iterative (no recursion) suffix-language expansion by legal first-opening and last-closing grammar, sorted bottom-up by remaining symbols. Terminal [1,1]. Unexpanded reachable state [1,multinomial]. Expanded states: sum disjoint child lower and upper, upper bounded by unrestricted multinomial. Exact nodes cached. No production imports or borrowed fixtures.
- Candidate rank decision only when the entire certified count/rank interval agrees; sole grammar-legal symbol is forced when source-locked rank is valid. Otherwise explicit UNPROVEN_SUFFIX_INTERVAL. Production candidate charge is checked in exact visited order using 1+(m-opened+1)*(1+remaining); never equate aggregate DP-graph charges with rank-path accounting.
- Output: correct prefix + mandatory charged candidates, or first undecidable count or budget excess; explicitly no Stage2 acceptance from bounded QA.

## Commands and observed QA
python -m py_compile qa/clojure-dutch/discovery24_iterative_canonical_interval_qa.py
python qa/clojure-dutch/discovery24_iterative_canonical_interval_qa.py --artifact-zip /path/to/github-actions-artifact-14770898411.zip --expansion-cap 4096

Local syntax check exit 0; full standalone QA exit 0 (runtime 4.82s, observed process max RSS 116632 KB). Six exhaustive independent tiny families, 59 legal complete words, 436/436 exact rank-position prefixes, 436/436 cost-equality budget accepts and 436/436 cost-minus-one refusals. A long 29-month length-123 case completes nonrecursively. Invalid expansion cap exits 2; a byte-tampered ZIP is SHA-rejected and exits 1.

Canonical p82 and p520: after one uniquely forced letter 1, charged 117778 raming units, next candidate letter 1 costs another 117745. At QA cap 4096, first undecidable rank decision is at position 2. Certified suffix count interval lower has 9 decimal digits, upper 5358 digits; canonical rank 5288 digits. Both outputs: UNPROVEN_SUFFIX_INTERVAL at prefix length 1, not a budget refusal, not numeric equality. No new Clojure Native, production tel-rest, or five-field differential was run.

GATES: local Python syntax PASS, independent tiny model rank/cost PASS, immutable artifact and five source Git blobs VERIFIED; canonical p82/p520 rank path UNPROVEN, new CI/Native NOT_RUN, five-field differential NOT_RUN, Stage2 OPEN.

## NEXT
TEST/QA ONLY: derive and independently validate much tighter count lower/upper bounds exploiting both ascending first openings and ascending last closings, specifically the canonical position-2 candidate. Confirm admissibility exhaustively against tiny independently enumerated words and maintain exact per-candidate production charge trace. A blind cap increase without improved mathematical bound is not the next test. Stop with UNPROVEN unless every rank decision and its 5000000 budget gate are proved. Retain original 128 search and 5000000 cell ceiling. Do not change production, API, Native, main, merge, or publication; do not rerun the accepted same-SHA CI. No pending-execution cleanup without newly received execution results.
