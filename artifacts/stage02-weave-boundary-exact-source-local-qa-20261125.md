# Stage02 — corrected weave boundary local QA (2026-11-25)

PROJECT_ID: PC-BRANCH-WAT-SPANISH
Tested commit: d686f475bedb4e5f14f3cd95968595fa74460177
Environment: isolated Linux container, Python 3.13.5. Not GitHub Actions and not WAT execution.

Both complete source files retrieved from the tested commit were reproduced byte-for-byte and checked with git hash-object before the recorded execution:
- tests/stage02_calendar_weave_boundary_qa.py blob 7cc463fa44c848e8ffe1b9706e1da5456bacd51c; SHA256 9a3254c9739fbb9a0d0bb51feaa74699dbfe22dea800bf9862549452b26405b8
- tests/stage02_calendar_weave_independent_oracle.py blob 5793a3a9e310f6515d33fd86362324ba0f577a34; SHA256 eb4717b2427b714a23b9afdca5c7b0590167ba74aa96a2df15aaeb321e405bff

Commands (set -euo pipefail; each execution bounded to 30 seconds):
```sh
python -m py_compile stage02_calendar_weave_boundary_qa.py
timeout 30s python stage02_calendar_weave_boundary_qa.py --enumerator-only | tee enumeration.json
timeout 30s python stage02_calendar_weave_independent_oracle.py --selftest | tee prior-selftest.log
timeout 30s python stage02_calendar_weave_boundary_qa.py | tee boundary.json
```
All exited 0. No production source was changed.

Exact stdout, enumeration.json (SHA256 937a7389eb8d9a1aaa4bc74b69ed4f730b58ebc45d9d0393d7e3afec3af2f3d7):
```json
{"enumerator_only": true, "families": [{"count": 14, "lengths": [2, 2, 2, 2]}, {"count": 37, "lengths": [2, 3, 2, 2]}, {"count": 19, "lengths": [3, 2, 3]}, {"count": 71, "lengths": [3, 3, 3]}, {"count": 50, "lengths": [4, 3, 2]}], "project": "PC-BRANCH-WAT-SPANISH", "rank_order_witness": {"canonical_word": [1, 1, 2, 3, 2, 1, 2, 3, 3], "different_ranks": 17, "lengths": [3, 3, 3], "lexical_word": [1, 1, 2, 3, 1, 2, 3, 2, 3], "rank": 20}}
```
prior-selftest.log (SHA256 2c52f597ec70e963420b4114e290a6d6d952d007f74e3b9e015f0961c7aaabe6):
```text
WEAVE_SMALL_EXHAUSTIVE_PASS
```
boundary.json (SHA256 c5600360ec711914aee0b473f93432bc3aee185c8c5618c901fb6df657971325):
```json
{"gate": "FOCUSED_QA_PASS", "large_structural": {"cases": [{"family_rank_decimal_digits": 69, "lengths": [5, 7, 9, 11, 13, 15, 17, 19], "ranks_sampled": 7}, {"family_rank_decimal_digits": 24, "lengths": [3, 4, 5, 6, 7, 8, 9], "ranks_sampled": 7}], "independent_expected_large_outputs": false, "structural_probes": 70}, "native_pass": false, "oracle_source_sha256": "eb4717b2427b714a23b9afdca5c7b0590167ba74aa96a2df15aaeb321e405bff", "project": "PC-BRANCH-WAT-SPANISH", "rank_order_witness": {"canonical_word": [1, 1, 2, 3, 2, 1, 2, 3, 3], "different_ranks": 17, "lengths": [3, 3, 3], "lexical_word": [1, 1, 2, 3, 1, 2, 3, 2, 3], "rank": 20}, "small_independent": {"boundary_probes": 1677, "cases": [{"independent_words": 14, "lengths": [2, 2, 2, 2]}, {"independent_words": 37, "lengths": [2, 3, 2, 2]}, {"independent_words": 19, "lengths": [3, 2, 3]}, {"independent_words": 71, "lengths": [3, 3, 3]}, {"independent_words": 50, "lengths": [4, 3, 2]}], "rejected_mutations": 120, "words": 191}, "stage02_accepted": false}
```
Output hashes cover the single stdout line plus trailing LF.

Disposition: local exact-source independent differential on five small families PASS (191 words, 1677 offset probes; 120 rejection/comparator checks); 70 large-family structural probes PASS, not independent expected large outputs. The corrected focused workflow is configured for push on the QA files, but the connector's commit-run listing only exposes pull-request runs and returned no runs; combined status list empty. No inference of CI success or absence of push runs. No duplicate dispatch. WAT Native not run here. Historical original Stage02 ZIP/manifest remains unverified. Stage02 NOT ACCEPTED.
