# Fortran+English Stage1: Foundation same-target warm-cache differential QA (2026-11-21)

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Authorized branch: `Fortran+English`. Verified parent commit: `01d1849fa6a9ec89ba07add5b26439ab0609d823`.

## Accepted evidence from parent (not whole-stage acceptance)
- [GitHub Actions run 44828417899](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828417899): push, attempt 1, completed/success, all 10/10 jobs, exact parent SHA and branch.
- Calculation-context differential job 136606837137: 14/14 independent pinned Python contexts, 70/70 exact fields; 2/2 sensitive boundary pairs; forward and reverse no-reset runs each 8/8 calls, 40/40 fields; harness 40/40.
- Cache-structure job 136606837285: 215 assertions, 0 failures. Stage1 full-mode job 136606837009: 58/58, exit 0. Both are bounded gate-only evidence.
- Retained artifact 14673989560, ZIP SHA256 `e54744cd80e716bfb461e48cf67d88a93c34c237fb1bffd2ad339a3809c4a5c7` (GitHub digest), CRC valid; JSON SHA256 `24624c365ebdfbbb5b41864796823a9bb1f97538c6d5e42f609c9f4b1fd97a30`; identity and reverse `same_process_reverse_context_sequence` 8/8 individual expected/actual field matches verified.

## Newly identified gap (not an observed bug)
Previous warm-cache same-process sequences use boundary targets -15057703 and -15053458. They do not test a *fixed Foundation target* (-15055671) under five distinct calculation-day contexts in a single process. In the independent pinned Python oracle, the Foundation target has demonstrably context-sensitive date fields for these five calculation days.

## QA-only contract
- Input: original normative Fortran CLI receives eight ordered case IDs `7,8,5,4,6,7,8,5` in one process; no cache reset between calls. The first five calculations use offsets -2048,+2048,0,-1,+1 from Foundation with a constant target day of -15055671. The final three calls revisit cases 7,8,5.
- Independent oracle: existing SHA-1 pinned reference `tests/normative_reference.py` from commit `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`; 5 exact numeric fields per result. Require 3/3 known sensitive Foundation context pairs (7/8, 4/6, 5/7).
- Output: strict step marker, case index, calculation day, target day and five fields for each call; require 8/8 calls and 40/40 fields. Preserve `same_process_context_sequence` and `same_process_reverse_context_sequence`; add `same_process_foundation_context_sequence` with per-call inputs and expected/actual values.
- Keep 14/14 standalone, 2/2 boundary-sensitive, forward 8/8 and reverse 8/8 unchanged as hard gates. Add six self-test assertions, now 46/46 expected. Bound each same-process run at 480s, 1GiB; set overall CI job timeout to 30 minutes. Retain JSON and logs on failure via existing always-upload artifact.
- No normative Fortran algorithm, reference source, Fortran probe, Stage2, main, merge or release change. New gate is **static QA until source-matching completed CI, job logs, artifact and SHA validation**; whole Stage1 remains NOT ACCEPTED.

