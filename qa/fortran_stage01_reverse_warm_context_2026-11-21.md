# Fortran+English Stage1: reverse-warm calculation-context differential QA (2026-11-21)

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Authorized branch: `Fortran+English`. Parent: `77575e18703b93a7779a9705764d2f84a7ad38b7`, tree: `4933e0df2a2a139df851a3e159afe0da66e4fe0b`.

## Verified prior Native evidence
- GitHub Actions [run 44820117995](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820117995), attempt 1: completed/success, all 10 of 10 jobs; branch and run commit match the parent above.
- Original context job 136578534267 log: 14/14 Python-pinned independent contexts (70/70 exact fields), 2/2 context-sensitive target pairs, original no-reset same-process order `11,13,12,14,11,13,12,14` 8/8 calls (40/40 fields), harness 36/36.
- Original cache structure job 136578534692 215 assertions, zero failures; original Stage1 entrypoint job 136578535623 58/58, exit 0. Both are gate-only, **not** full Stage1 acceptance.
- Artifact 14672760383, ZIP SHA256 `7d1dc068987c1e9283fc5359903a602d44fcf91456a323215fd4f4358c2ccca9` (matches GitHub digest), CRC valid; JSON SHA256 `3b147a922a8a112717f17c65d72593df46102f66994d000a7e08aeb4c7bcf480`. Parsed JSON identity and 14 individual/8 same-process rows independently replayed against the retained Python expected fields with zero discrepancies.

## Narrow uncovered dimension
The prior no-reset sequence warms the original Fortran cache with boundary targets in forward order, then repeats it. This does not verify identical Python-backed answers if a **new process warms the cache in reversed first-use order**. This is a coverage gap, not an observed bug.

## QA-only change contract
- Keep existing 14 standalone reference comparisons and forward same-process order unchanged.
- In an independent Fortran process, reset the cache once at startup and call the **original** `normative_calendar_date` in reverse initial order `14,12,13,11,14,12,13,11`, with no reset between calls.
- For each of the eight calls, require exactly one step marker and exact input numbers; compare five numeric fields to the existing independent SHA-pinned Python oracle results. Require reverse 8/8 calls, 40/40 fields; keep forward 8/8, 40/40 and standalone 14/14, 70/70 as required gates.
- Retain the prior JSON key `same_process_context_sequence`; add `same_process_reverse_context_sequence` carrying order, reset status, matching counters and per-call expected/actual fields. Preserve JSON on failure.
- Add four harness invariants, 36 to 40 self-test assertions; retain Python reference commit/blob lock. Per-process 480s timeout and 1GiB address limit. Raise only this CI job's total cap from 20 to 25 minutes to include the additional bounded process.
- **No change to normative Fortran algorithm or existing Fortran CLI probe.** No Stage2/main/merge/release.

Evidence classes: prior Native/differential PASS applies only to parent SHA; QA source + workflow + this report are static until fresh source-SHA-matching GitHub Actions logs and retained artifact are inspected. New reverse-order gate is NOT yet Native PASS or full Stage1 acceptance.
