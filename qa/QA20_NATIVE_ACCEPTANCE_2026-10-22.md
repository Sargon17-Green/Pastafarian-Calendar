# QA20 — Native input-driven reachability, bounded acceptance (22 Oct 2026)

## Identity and immutable anchors
- **SUCCESS**, GitHub Actions run [39761821210](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210), tested commit `d0a1c686c4f9244121246aa5b70266c072c3ddce`, four actual Native PyFunge-98 source shards and fifth independent complete-shard receipt audit: **5/5 PASS**.
- Native source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`, unchanged. Frozen QA18 21-candidate report supplied by successful run 39423789058, SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`.
- Four original CI artifacts by shard 0..3: `12417714729`, `12418676466`, `12418536785`, `12417633980`; fifth aggregate `12419050654`. All five ZIP archives were downloaded and independently integrity-tested.
- Aggregate JSON SHA-256: `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117`.

## Results
- **48 input-origin Native BF98 runs: 27 valid and 21 invalid; 1,939,997 actual executed STEP events.** For each valid case, the seven-field output matched three fresh executable Native Befunge reference programs. All invalid inputs emitted the seven `-1` rejection sentinels.
- Original QA18 source candidate cells reached and executed as matching opcodes outside stringmode under ordinary input, without forced IP relocation or test-induced Funge-space edits: **6/21**:
  - `(10,44)` `>`, 15 invalid-case witnesses.
  - `(150,20)` `x`, 2 invalid-case witnesses.
  - `(175,38)` `x`, 3 invalid-case witnesses.
  - `(179,44)` `@`, 15 invalid-case witnesses.
  - `(235,11)` `x`, 1 invalid-case witness.
  - `(396,17)` `x`, 11 invalid-case witnesses.
- **All six had actual native witnesses only for malformed/invalid input in this frozen corpus.** No original QA18 candidate executed on these 27 valid cases. The other 15 had no contact at the source coordinate in this finite QA20 corpus; absence of contact is not proof of dead code or impossibility.
- The difficult legal `valid23` pair containing 81-digit magnitudes completed in **340,117** actual Native steps, preserving its complete trace and independent Befunge result.

## Historical failures (all retained)
1. Run 39647806994 RED: test-only constructor passed raw input to an older fixed-label helper.
2. Run 39648222804 RED: valid23 exhausted test's 175,000-step limit.
3. Run 39724322248 RED: `MAX_TICKS` was raised to 1,250,000, but shared helper `stage1_native_live_pair_matrix.tick` still enforced its unrelated hard-coded 250,000-step cap.
4. Repair commit `d0a1c686c4f9244121246aa5b70266c072c3ddce` replaced **only** the QA20 call site with `tick_qa20`, which invokes the same Native `Program.execute_step` and handles PyFunge normal termination exactly as before, now under the explicit QA20 step bound. No valid case was dropped or converted into skipped/timeout-success.

**Scope:** This certifies only finite natural IP reachability and results for the 48 selected inputs. It does not establish any of the reached source operators as necessary for a final numeric result, or prove absence of dead code, unrestricted semantic ownership or full Stage 1 geometry. `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No `main` or `Befunge+Кыргызча` change, no PR #17 merge and no Stage 2.
