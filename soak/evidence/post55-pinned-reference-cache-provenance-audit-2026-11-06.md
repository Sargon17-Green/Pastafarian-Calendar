# Kotlin+Cymraeg — pinned-reference cache and checkpoint provenance audit (2026-11-06)

Project ID: `PC-BRANCH-KOTLIN-CYMRAEG`  
Scope: bounded source/provenance audit of the exact pinned Python reference used by the completed seven-field FOUNDATION differential. **Not** certification and **not** an independent TABLETS full-date oracle.

## Verified prior execution (do not rerun on unchanged SHA)

- Audited Kotlin commit: `3cf410bbcb9131fe56bb7db7abd00b7664d052e3` (the exact branch HEAD observed before this audit).
- [Seven-field run 41979716472](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979716472): completed/success, attempt 1; JDK21/Kotlin production compilation successful; 9/9 synthetic tests; 3 FOUNDATION−1/0/+1 comparisons, 15/15 date fields agree; 3 isolated pinned reference processes, per-process acceleration-cache reset, zero mismatches.
- [Canonical Names Lock 41979716690](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979716690): completed/success, all 30 jobs succeeded on that commit.
- [Artifact 13393238775](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979716472/artifacts/13393238775), GitHub reported ZIP SHA-256 `d29350273a079b5a9b067db37cd2e42b7027294eac5f2156c05032736d9e4c1b`. Log status: `PASS_BOUND_PRODUCTION_SEVEN_FIELDS_VS_PINNED_NOT_CERTIFIED`.

## Source-identity and dependency finding

Pinned Python commit: `7cb12bf355461e5a179e0deadb7365689288bf29`.
Exact Git blob IDs inspected at this commit:
- `src/pastafari_calendar/final_integration.py`: `c927c324f039a94bc36b2ea8827acd58511b6f8c`.
- `src/pastafari_calendar/calendar.py`: `3ab6fdb56f107cb08b27bb60f3eca27b5164435a`.
- `src/pastafari_calendar/acceleration_scars.py`: `1f25dff702bde739ab027556457377e01962ee49`.

The pinned `final_integration.py` defines **75** immutable `GATE_CHECKPOINTS_INTEGRATED` index/day pairs, strictly increasing in both coordinates and including `(0, -15055671)`. The `IntegratedGateCache.ensure_cover` source invokes `_reanchor_for_cover`; that method chooses a matching static checkpoint and assigns `self.gates = {index: day}` when index != 0. Thus the source contains an explicit static re-anchoring dependency.

For each of three actual TABLETS days `-278523`, `-278522`, `-278521`, applying the **pinned source's selection rule** yields the checkpoint `(28672, -674161)`; the next positive checkpoint `(29696, -169081)` lies beyond those days. This is a verified *static source derivation*, **not** a runtime observation of a TABLETS date calculation and not validation of the checkpoint's arithmetic truth.

In `acceleration_scars.py`, `reset_acceleration_scars_for_tests` clears the five mutable acceleration stores (final results, year structures, year checkpoints, gate shards, selection oracle) plus metrics; it does **not** remove the module-level immutable checkpoint table in `final_integration.py`. Therefore the observed 3 isolated/cold Python processes cannot, by themselves, establish an unseeded/static-checkpoint-free reference, nor mathematical independence. This is a **provenance limitation**, not a discovered date mismatch.

## Separately bounded next verification contract

- Verify both Git revisions, distinct roots, exact Git-backed source identity and pinned module hashes.
- Run **six** `python -I` cold processes, two modes (`table` and process-local `empty` static checkpoint table) for each of FOUNDATION−1/0/+1; reset acceleration stores for each run.
- Compare 3 pairs × 5 typed fields (15 field comparisons), reject any provenance, process, timeout, or field discrepancy; report actual re-anchor events; caps: 90 seconds per process and 420 seconds total.
- Keep the table-removal experiment local to the child process; do not mutate the pinned tree.
- Treat positive results near FOUNDATION as *bounded* evidence only. A genuine TABLETS date independent of static checkpoints still needs a separately constrained oracle/architecture. No changes to production 8192, --certify, main, merge, or protected refs.

A local implementation of this proposed bounded test harness completed 10/10 synthetic unit tests and Python compilation, but **no cold six-process run against the real pinned checkout was executed in this audit**. It is not CI evidence.

**Disposition:** partial source/provenance audit completed; reference cache reset is confirmed by previous workflow/log, but checkpoint-free TABLETS full-date independence remains **unproven**. Next step: run the six-process source-locked audit and inspect evidence before any broader gate.
