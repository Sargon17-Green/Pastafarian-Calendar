# Stage22 — Twelve-batch bowl evolution

**State (2026-11-25):** production operation 39 has been appended to `src/monster_bootstrap.false`; source/static review only; Native has not been run; Stage22 is not accepted.

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

Production operation `39` is appended after accepted operation `38`. It validates the allocated `[1,bowls]` argument and six canonical positive Base512 BigInts; sums the six old bowl values; computes `T=SAVE(sum+6+149u)`; derives rank `4+((T-4) mod 7)` with the signed BigInt Euclidean-remainder helper; obtains the lexicographic order from production operation `34`; maps predecessor/successor positions back to bowl IDs; computes all six new values from the same old snapshot; and only then builds a fresh direct `[6,...]` table for the next batch. It returns the final direct table after exactly twelve batches. Input records and BigInts are read-only. Invalid physical pointers, truncated allocations, corrupt heaps, and memory-unsafe aliasing remain outside the bounded contract.

- Design oracle: PASS (397 cases; 4,764 transitions; 28,584 comparisons).
- Production op39: source committed; Native/static execution not yet performed.
- CI/Native: NOT_RUN.
- Stage22 acceptance: NO.
- Main/merge/release: not authorized and not performed.

**Native QA prepared (2026-11-25):** `tools/stage22_native_diagnostic.py` builds allocated direct-record fixtures and probes; `tools/stage22_native_acceptance.py` pins the source/runtime, executes three full 12-batch paths, six 1/6-batch probes, a byte-identical replay, 16 semantic invalids and five actual arithmetic/order source substitutions; `tools/stage22_offline_audit.py` independently recomputes with factoradic unranking and Mersenne folding, checks all Native logs, source snapshots, corruption controls, and a CRC-verified evidence bundle. The reusable workflow is wired through `canonical-names-lock.yml` and runs only on the explicit Stage22 acceptance commit marker.

- Operation 39: source committed at parent `609a1645af71dad6e3bb19ce02c0ba1e76c0748c`.
- First CI attempt: run `45684008657`, job `139451675350`, failed at source-pin verification because `SOURCE_PIN` contained a literal backslash; build and Native steps were skipped.
- Second CI attempt: run `45684287557`, job `139452646856`, passed source/runtime pin, compiler build and Unicode preflight, then stopped before Native because `cmp` required byte-identical JSON key order and historical metadata. The generated and committed mathematical oracle values agree; the gate is being changed to compare the full mathematical fields and all five numeric witnesses semantically. Artifact `15056140710` has SHA-256 `df9f01220730ca81fed08e1b1d0db14ae8e2fdf64288180e1e370fd9e7a91d8b`; ZIP CRC test passed.
- Native/CI: not yet completed; no PASS claimed.
- Independent offline audit: prepared, not yet executed.
- Stage22 acceptance: NO.
- Main/merge/release: not authorized and not performed.

**NEXT:** inspect the completed Stage22 run, job logs, exact source/runtime pins, artifact SHA-256/ZIP CRC, and offline audit; only then decide bounded acceptance. No main/merge.