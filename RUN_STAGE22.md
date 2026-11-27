# Stage22 — Twelve-batch bowl evolution

**State (2026-11-26):** production operation 39 is committed. Bounded Native attempts have reached the original interpreter, but no attempt has passed the complete acceptance gate; the latest source-locked run is queued. Stage22 is not accepted.

## Normative basis

- Normative operation 56 in `test/normative_reference.false`, blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`.
- Its comment defines twelve batches after the 46th visible drop and input tuple `[bowls]`.
- Normative operation 57 consumes operation 56's result as `finalBowls` and returns it together with `orderAt46`. Therefore operation 56 returns the final six-bowl state after twelve batches, not a history of twelve states.
- The loop in operation 56 visits bowl IDs 1 through 6; sequence construction preserves that logical order. The production result is indexed by bowl ID.

## Production mapping and data contract

**Planned production operation:** `39` (corresponds to normative operation `56`).

**Input:** one direct argument record `[1, bowlsHandle]`. `bowlsHandle` is a direct table `[6, B1, B2, B3, B4, B5, B6]`. Each `Bi` is a fully allocated canonical positive BigInt.

**Output:** a fresh direct table `[6, N1, N2, N3, N4, N5, N6]`, representing the final state after exactly twelve batches. It is not wrapped in a second record and does not contain intermediate snapshots.

BigInt contract:

- (M=2^{127}-1).
- Canonical positive values are in (1ldots M).
- Sign cell is (+1); digit count is 1 through 15; each base-512 digit is 0 through 511; the most-significant digit is nonzero.
- `SAVE(x)=1+((x-1) mod M)` for positive (x).

**Ownership and mutation:** all six values in a batch are computed from one immutable old-state snapshot. The input record, bowl table, and BigInt records remain unchanged. The output table and its six BigInt values are fresh; no output aliases an input handle. Invalid/unallocated physical pointers, truncated allocations, corrupt heaps, and memory-unsafe aliasing are outside this contract.

## Exact recurrence

Let (B^{(0)}=(B_1,ldots,B_6)) be the input. For each batch (u=1,ldots,12):

1. Compute the shared batch total:

[
T_u=operatorname{SAVE}left(sum_{i=1}^{6}B_i^{(u-1)}+6+149uight)
]

2. Compute the one-based lexicographic permutation rank:

[
r_u=4+left((T_u-4)mod 7ight)
]

The Euclidean remainder is in (0ldots6), so (r_u) is always in (4ldots10). Let (O_u) be the (r_u)-th lexicographic permutation of bowl IDs ((1,2,3,4,5,6)).

3. For each bowl ID (b=1,ldots,6), let (p) be its one-based position in (O_u). The cyclic predecessor and successor IDs are:

[
ell=O_u[1+((p-2)mod6)],qquad
q=O_u[1+(pmod6)]
]

Let (L=B_ell^{(u-1)}) and (R=B_q^{(u-1)}). Compute:

[
B_b^{(u)}=operatorname{SAVE}left(
(B_b^{(u-1)})^2+3L+5R+T_u+u+p^2+7LR
ight)
]

All six (B_b^{(u)}) values use the same (B^{(u-1)}); only after all six are computed does the next batch begin with (B^{(u)}).

**Return:** (B^{(12)}), in bowl-ID order 1 through 6.

## Independent design oracle

`tools/stage22_batch_bowls_design_oracle.py` uses only Python's standard library and does not import production code or any other branch's implementation. It compares two independently structured calculations:

- lexicographic permutation table plus exact modulo;
- factoradic unranking plus repeated Mersenne folding.

The deterministic run used 13 boundary/anchor inputs and 384 seeded inputs:

- 397 six-bowl inputs;
- 12 batches per input (4,764 transitions);
- 28,584 numeric comparisons and range checks;
- 28,584 checks that Mersenne folding agrees with `SAVE`;
- 397 input-immutability checks;
- all 720 permutation ranks checked;
- one full replay, byte-identical at the serialized mathematical trace level.

Oracle digest: `0xb2eaf77ee8b62ef6`.

Witness input `[2,3,5,7,11,13]` gives first-batch (T_1=196), rank (7), order `[1,2,4,3,5,6]`, and output `[529,349,853,394,878,599]`.

Five *mathematical wrong-algorithm witnesses* each produce a first numeric mismatch on bowl 1: changing (149u) to (148u), using modulus 6, swapping neighbor weights, omitting (p^2), or changing (7LR) to (6LR). These are design sensitivity witnesses, **not** Native source mutants and not acceptance evidence.

The serialized oracle output is in `evidence/stage22_design_oracle_2026-11-25.json`.

## Native acceptance gates after implementation

1. Lock the production source SHA and original interpreter runtime SHA; verify both in the completed run, job logs, and artifact.
2. Run at least three independent full twelve-batch inputs, instrumented probes after batches 1, 6, and 12, and an exact replay.
3. Independently compare every returned bowl against the Python oracle; verify the final direct table shape, all canonical BigInts, input immutability, and fresh output handles.
4. Run sixteen allocated semantic-invalid records covering outer record length, nested bowl-table length, sign, BigInt length, digit range, top digit, and value range. Each must emit its exact domain marker and nonzero exit.
5. Run five actual source substitutions for the five arithmetic/order faults above. Each must fail at the first independently predicted numeric assertion, not at parser setup or timeout.
6. Preserve raw stdout, stderr, exit code, source/runtime observations, logs, and artifacts; verify artifact SHA-256 and ZIP CRC. Use the existing bounded resource policy (2 GiB address-space cap, 600-second hard timeout, watchdog) and do not duplicate a run on the same accepted SHA.

## Implementation checkpoint — 2026-11-25

Production operation `39` is appended after accepted operation `38`. It validates the allocated `[1,bowls]` argument and six canonical positive Base512 BigInts; sums the six old bowl values; computes `T=SAVE(sum+6+149u)`; derives rank `4+((T-4) mod 7)` with the signed BigInt Euclidean-remainder helper; obtains the lexicographic order from production operation `34`; maps predecessor/successor positions back to bowl IDs; computes all six new values from the same old snapshot; and only then builds a fresh direct `[6,...]` table for the next batch. After batch 12 it copies the six final handles into a fresh durable direct return table. Input records and BigInts are read-only. Invalid physical pointers, truncated allocations, corrupt heaps, and memory-unsafe aliasing remain outside the bounded contract.

- Design oracle: PASS (397 cases; 4,764 transitions; 28,584 comparisons).
- Production op39: source committed; Native attempts have run, but no complete acceptance gate has passed.
- CI/Native: PREACCEPTANCE_FAILURES; latest source pin `983d80cf74c8782ab430663b26592b162228d420` has queued run `45779297478`.
- Stage22 acceptance: NO.
- Main/merge/release: not authorized and not performed.

**Native QA prepared (2026-11-25):** `tools/stage22_native_diagnostic.py` builds allocated direct-record fixtures and probes; `tools/stage22_native_acceptance.py` pins the source/runtime, executes three full 12-batch paths, six 1/6-batch probes, a byte-identical replay, 16 semantic invalids and five actual arithmetic/order source substitutions; `tools/stage22_offline_audit.py` independently recomputes with factoradic unranking and Mersenne folding, checks all Native logs, source snapshots, corruption controls, and a CRC-verified evidence bundle. The reusable workflow is wired through `canonical-names-lock.yml` and runs only on the explicit Stage22 acceptance commit marker.

- Operation 39: source committed at parent `609a1645af71dad6e3bb19ce02c0ba1e76c0748c`.
- First CI attempt: run `45684008657`, job `139451675350`, failed at source-pin verification because `SOURCE_PIN` contained a literal backslash; build and Native steps were skipped.
- Second CI attempt: run `45684287557`, job `139452646856`, passed source/runtime pin, compiler build and Unicode preflight, then stopped before Native because `cmp` required byte-identical JSON key order and historical metadata. The generated and committed mathematical oracle values agree; the gate is being changed to compare the full mathematical fields and all five numeric witnesses semantically. Artifact `15056140710` has SHA-256 `df9f01220730ca81fed08e1b1d0db14ae8e2fdf64288180e1e370fd9e7a91d8b`; ZIP CRC test passed.
- Third CI attempt: run `45684661404`, job `139453960901`, reached the original FALSE interpreter and failed immediately at `op22` with `stack type mismatch` while adding `6+149u` to the BigInt total; no numeric result was accepted. The fixture self-check passed. Artifact `15054463704` has SHA-256 `237c7b788a01afd604ce8d2568bad1a1d0db729104dc5ee26fafe89d5f55db3a`; ZIP CRC test passed.
- Superseded initial repair attempt: `op20` was incorrectly treated as small-to-BigInt. The subsequent Native failure showed that `op20` converts BigInt to a small cell; the correct signed-small-to-BigInt constructor is `op0`.
- Corrected source mapping (2026-11-26): all six scalar conversions in op39 (`6`, batch index in T, constants `4` and `7`, position `p`, and batch index in each bowl formula) now use `op0`. `op23` remains the BigInt-by-small multiplier; `op9` adds BigInts; `op14` multiplies BigInts; `op25` applies SAVE. The `7LR` term is added before its scratch handle is reused for the batch index. The mathematical recurrence is unchanged. The rank-modulus and position-square source-mutant anchors were retargeted to `op0`.
- Native/CI: no PASS claimed; attempts and exact causes are recorded below.
- Independent offline audit: prepared, not yet executed.
- Stage22 acceptance: NO.
- Main/merge/release: not authorized and not performed.

## Native QA attempt log — 2026-11-26

All attempts below are bounded preacceptance diagnostics. A failed probe or self-check is not a production PASS and does not accept Stage22.

- Run `45685335977`, job `139456325033`, source `4763c0f56507327abc70c8f91153203ad59420af`: fixture self-check passed; first positive probe failed at EOF with `unterminated statement`. Artifact `15054319915`, SHA-256 `41091671eaccae99c7be6f40d09034ba8fefb81a5546a47a956f62dc3c567c5d`, ZIP CRC PASS. Cause: prefix instrumentation omitted the closing bracket of the condition lambda.
- Run `45685426309`, job `139456648522`, source `624b23768772df237e166185b895ae30bb6982d2`: same malformed prefix-loop failure before numeric execution. Artifact `15055793724`, SHA-256 `51ad4a5e0d865b3e8e0fdddd0396281aa121ac0851296758b5725b1acb58083f`, ZIP CRC PASS. The instrumentation replacement was corrected to preserve `[condition][body]`.
- Run `45776706036`, job `139761977609`, source `183f4426d254b46880d309a7e27a8bd086b9a3fd`: pre-Native self-check failed because the newly added expected-loop assertion encoded a literal backslash-n rather than a newline. Artifact `15095508758`, SHA-256 `875e67d6985815a97ec08c7b022aaef80925e4d649c9a288bbb7e8ab831e415b`, ZIP CRC PASS. The assertion escape was corrected.
- Run `45776844772`, job `139762441041`, source `875ed860d2950aed9b753c2968c02f91fa5767e5`: design snapshot and fixture/mutation self-check passed; first Native probe failed at `E_SMALL_SIGN` with a stack type mismatch. Artifact `15096915102`, SHA-256 `c31e96bb9fbec6f7de8724f232981b000a6d9f97b79f2d10bb5bef86da41bb1a`, ZIP CRC PASS. Cause: op39 called op20 with scalar input although op20 is BigInt-to-small; scalar-to-BigInt must use op0.
- Run `45777104027`, job `139763299835`, source `e4c001c583787e3fa90767cbffa8b17cf341549e`: pre-Native self-check failed because the position-square mutant still targeted the old op20 conversion anchor. Artifact `15097035208`, SHA-256 `3ca02ec89a25358566c29a497c3fbe1d6db37b1f79a4b44e3c3d0815243a774c`, ZIP CRC PASS. The position-square and rank-modulus mutant anchors were retargeted to op0.
- Run `45777231412`, job `139763728873`, source `f56c3cf22079d1805e5e6b8a0a2ed8f15b1b5526`: pre-Native self-check failed because the rank-modulus mutant still targeted the old op20 conversion anchor. Artifact `15097485462`, SHA-256 `21e85e529d0ea021572ce6ab5e763a0f8d808c385366de2f7c840bfc363ecbfb`, ZIP CRC PASS.
- Run `45777291329`, job `139763929763`, source `3f602c0e03bac792a2bafa6044df8f5a3792a2f0`: same pre-Native self-check failure at the stale rank-modulus op20 anchor. Artifact `15097361586`, SHA-256 `db862a61d8faf33b5918aa15f2a2e16d8f9dcf03cf873f466d11bfe577a3ab78`, ZIP CRC PASS.
- Run `45777329229`, job `139764054680`, source `82134a9f16a60ae68ddd45bf9599690bcd849a3c`: `verify` passed (source/runtime pin, interpreter build, UTF-8 preflight); Native probe 1 executed op39 but failed the direct output-table length assertion. Artifact `15097002736`, SHA-256 `132543b623144e37c75ebd9d271658fe0899cd7c2242bc902829cef9924cc8f8`, ZIP CRC PASS. The returned pointer referenced the temporary last-batch table rather than a durable direct `[6, six handles]` return block. Corrected by copying all six handles into a fresh table at function return; a static self-check now requires that exact return sequence.
- Both mutation anchors (rank modulus and position square) were retargeted to op0 in source snapshot `82134a9f16a60ae68ddd45bf9599690bcd849a3c`. Run `45777329229` completed with an output-table-length failure; the durable-return fix is in source snapshot `983d80cf74c8782ab430663b26592b162228d420`, tested by queued run `45779297478`.
- Current source snapshot: `983d80cf74c8782ab430663b26592b162228d420`; all six scalar-to-BigInt conversions and both affected mutation anchors use op0, and op39 now copies the six final handles into a fresh durable direct return table. The exact return sequence is guarded by `stage22_native_diagnostic.py`. Run `45779297478` is queued for this exact source SHA. No Native PASS is claimed.

**NEXT:** inspect run `45779297478` on source pin `983d80cf74c8782ab430663b26592b162228d420`: verify the `verify` and `stage22-acceptance` jobs, exact source/runtime pins, all positive/invalid/mutant/replay evidence, offline audit, artifact SHA-256 and ZIP CRC. No queued run is PASS. If the return-shape failure recurs, diagnose from the new artifact before changing code. No main/merge.

## 2026-11-26 — repeated output-length failure and frame/fixture repair

Run 45779297478, job 139770576995, source 983d80cf74c8782ab430663b26592b162228d420, runtime eb3135565a8670cced3f6bbca4dbf7b014c45634: completed/failure. Canonical verify, source/runtime pin, original interpreter build and UTF-8 preflight passed. Design snapshot matched. First probe (ones, one batch) exited 1 with stdout STAGE22_OUTPUT_TABLE_LENGTH_FAIL and divide-by-zero assertion at line 1046; offline audit skipped. No later positive/invalid/mutant cases executed. Artifact 15100673413 SHA256 460054a27baa6a1f474096efa3cb70cb65610458cb224282f63de105a2bdb49c, 29 ZIP entries CRC PASS. All 10 archived source snapshots match the manifest SHA256 and Git blob SHA1; source and runtime observed pins match. This is a failed-gate diagnostic, not a full independent acceptance audit.

Root cause in op39: after restoring y, the sequence !y:g;!k: omits k; before g;!. The intended parent-frame lookup instead consumes a heap cell/index, removes the saved return handle, and corrupts k. The fresh six-handle return table itself is constructed. Repair: !y:k;g;!k: (only op39).
Independent diagnostic Python FALSE-subset interpreter replay of the exact archived one-batch program reproduced the original marker (2,050,580 token steps); trace showed fresh table index 47190, parent-frame index 67, but returned handle/k 41375. Correcting the epilogue exposed the next fixture defect: the 15 pairwise output alias assertions generated g without ;! and would have read while another temporary was on the stack. Repair: read prior handle completely into scratch r, compare to current t. Both fixes, regenerated fixture from candidate source: STAGE22_CASE_OK, 2,571,923 token steps, 99 fixture assertions, zero allocation-depth anomalies in the diagnostic interpreter. Local fixture/mutation self-check PASS. Diagnostic interpreter is not the original runtime, so no Native PASS, no completed full gate, no acceptance. New source-pinned CI required; no duplicate of prior SHA. Physical invalid pointers and truncated allocations remain excluded.

Expected next gate: 10 positives (3 full, 6 prefix, replay), 16 invalids, 5 actual mutants and offline audit, exact artifact ZIP SHA256/CRC and source/runtime locks. No main/merge.

## 2026-11-27 — Native positive gate verified; expected abort framing repair

Run 45900701084/job 140185470029 completed FAILURE on source a2163c344185b4741873607435e5fd84a4539068, runtime eb3135565a8670cced3f6bbca4dbf7b014c45634. Source/runtime pin, compiler, UTF-8, design snapshot and fixture self-check passed. All 10 positives passed (1706 assertions). External partial audit recomputed all 60 values via the independent factoradic/Mersenne-fold oracle, checked program hashes and verified byte-identical full/replay files. Artifact 15155358557 SHA256 ffc3b3ec8ff5a453afb55307eda8290394ccb0386b8ea5b53967e8711973fb7c; 79 ZIP entries CRC PASS; all 10 archived snapshots match manifest SHA256 and Git blob SHA1 (two hidden workflow snapshots not included by uploader). First invalid outer_zero returned exit 1, exact stdout E_BOWL_BATCH_RECORD_LENGTH and original interpreter stderr pointing at the intentional slash at line 924 column 51. Old gate falsely required empty stderr for exit 1. Remaining 15 invalids and 5 mutants were not run; full offline audit skipped. Stage22 NOT_ACCEPTED.

QA-only repair: keep positive stderr empty; require exit 1 plus expected marker and exact original-runtime divide-by-zero diagnostic at the explicit marker-specific 0 0/ guard in the exact executed program. Verify path, coordinates, source excerpt and caret; reject absent or unrelated stderr, wrong marker, position, path and appended output. The offline auditor checks the same evidence independently using parsed coordinates, retains independent mathematical expectations for mutants, and binds negative/mutant program hashes. No production FALSE changes. Self-check includes a replay of observed framing and negative controls. Full new source-locked CI gate required, no historical rerun. No main/merge.


## 2026-11-27 — Native full gate PASS; independent audit parser repair

Run 45907537034/job 140207774155 completed FAILURE on c99e76b63b6ee538bcca3f3d070e9d310ac72d52; source/runtime lock, verify, build, UTF-8, design snapshot and full Native gate PASS. Artifact 15158801090 SHA256 d5fe49c4c91733d84ba5c2d6ed4208b291ae3ce8cb1c2ae35ec2117995560922, 179/179 CRC entries; 10 positives/1706 assertions, 16 invalids and 5 actual numeric mutants. Independent auditor failed line 143: rsplit(b':',3) also splits the colon before the error message. The correction removes the exact suffix before splitting the final two coordinate delimiters. Local replay of the original archive with the corrected parser verified all 10 positive paths (60/60 numeric results), 16 invalid paths, 5 independently predicted mutant markers, byte-identical replay, and six rejected framing corruptions. Ten archived source snapshots matched their recorded SHA256 and Git blob SHA1; the two hidden workflow snapshots were absent from the uploaded ZIP (CI did verify the 12 source files before the parser failure). Workflow commit 312dded64e18964f248cfee7802f1dff7c0565b1 enables include-hidden-files. This local archive replay is not a completed full CI audit. No production change, no Stage22 acceptance, no Stage23/main/merge. A new exact QA commit must obtain the complete Native+offline gate and archive readback; do not redispatch an existing run.


## 2026-11-27 — Stage22 ACCEPTED_BOUNDED

Run 45913577333 / job 140227374442 and canonical verify 140227374293 completed/success on exact source f9659b9cf0b0a016e15a5f5b379e0c6a9864f17a; original runtime eb3135565a8670cced3f6bbca4dbf7b014c45634. Native 10 positives/1706 assertions, 16 semantic invalids, 5 numeric mutants and independent offline audit PASS. Downloaded artifact 15161002964 SHA256 933de2222f575036e7794d19239365ddd4567c7c2bcb194d6d65368db1073c7c; 185 outer/183 inner entries CRC PASS, all inner entries equal outer bytes, all 12 snapshots match live tree Git blobs and SHA256. External independent lexicographic-permutation/modular-reduction model recomputed 60 values and 5 mutant markers; 93 program/stdout/stderr hashes, 21 intentional aborts and byte-identical replay verified. Bounded contract only: physical invalid pointers/truncated allocations excluded. Receipt: evidence/stage22_bounded_acceptance_2026-11-27.json. No Stage23/main/merge.
