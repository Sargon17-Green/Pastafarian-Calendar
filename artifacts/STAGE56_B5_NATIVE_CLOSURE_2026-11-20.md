# Stage56 B5 — exact-SHA native preflight acceptance and source gate (2026-11-20)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Working branch: PHP+Bahasa-Melayu
Source commit under verification: `17d9dd90c458f4ceb9483b6354c74ac6012c88bc`
Canonical CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44634213352
Evidence artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44634213352/artifacts/14584272709
Evidence ZIP SHA-256: `387798d62079bd9afbb5cf18c8c46fccbed2bd18ac5f2a365e634edd5aaf5c33`

## Verified conclusions

- Canonical run #44634213352, attempt 1, completed/success, 30 of 30 jobs concluded success; its `head_sha` and the branch HEAD were exactly the source SHA above.
- Native B5 job #135948444236 completed/success with PHP 8.3.37; its log tested PHP_INT_SIZE=8.
- Three PHP syntax gates exited 0. B5 structural preflight emitted `checks=16 synthetic_structure_only=YES provenance=NOT_VERIFIED status=PASS`. B5 CLI-negative suite emitted `checks=12 real_year_profiles=0 provenance=NOT_VERIFIED status=PASS`.
- Downloaded actual artifact #14584272709, verified ZIP SHA-256 byte-for-byte against GitHub's published digest and job log, inspected all 11 distinct members, verified ZIP CRC and embedded PROJECT_ID/source-SHA. Both stderr files were empty; exit.txt had all five recorded values 0.
- Added `tests/stage56_b5_artifact_audit.py` to reproduce the byte/hash/ZIP/log checks against an independently pinned archive digest, without requiring PHP or rewriting test evidence. Its local Python 3.13 self-test passed 9/9 (1 synthetic positive and 8 intentional invalid cases), followed by PASS on the actual downloaded artifact. Its printed PASS is for the B5 **artifact audit only**, never Stage56 as a whole.

## Production source boundary, reviewed at the same exact commit

- `src/Patches/DateTuplePatch23.php` receives `yearStructureProvider` as an injected callable; its class comment explicitly disclaims a normative production generator.
- `src/Patches/YearStructureSlices56.php` exposes counting/ranking operations but does not furnish validated production year records, their `month_weaving`, or a Year5000 anchor.
- The candidate path `src/Patches/YearStructureProvider.php` returned 404; this targeted negative finding does not prove absence of an implementation elsewhere in the repository.
- No independently reviewed, authorized YearStructureProvider + Year5000 anchor + source-committed exports for 4999/5000/5001 were established this round. Do not generate synthetic substitutes or treat the source hashes claimed inside arbitrary JSON as trusted provenance.

## Decision and NEXT

B5 synthetic preflight and CLI-boundary Native gate: **ACCEPTED** on exact source SHA. The new auditor only adds a repeatable independent integrity check; it does not change PHP production code, the previous acceptance evidence, or the canonical year algorithm.

Stage56: **IN_PROGRESS** (no genuine-year profile acceptance). Next independently review an authorized production provider and canonical anchor, pin source/anchor identifiers and export real 4999/5000/5001 structures. Only after independent provenance review, run three separate <=512 MiB / 900 s PHP 8.3 count/rank/unrank profiles and evaluate timings. If none exists, record that concrete source dependency without inventing data. Do not integrate PATCH22/PATCH23, merge to main, or claim Stage56 PASS.

Auditor commands (run from repository root, after manually downloading the exact ZIP):

```bash
python3 tests/stage56_b5_artifact_audit.py --self-test
python3 tests/stage56_b5_artifact_audit.py B5.zip 17d9dd90c458f4ceb9483b6354c74ac6012c88bc 387798d62079bd9afbb5cf18c8c46fccbed2bd18ac5f2a365e634edd5aaf5c33
```
