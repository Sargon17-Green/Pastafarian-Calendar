# Stage19 — bowl position lookup

PROJECT_ID: PC-BRANCH-FALSE-ARABIC · branch FALSE+العربية · reference op53 · production op36.

## Normative source and behavior

The next reference operation is op53 in `test/normative_reference.false` (blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`). Its input is `[order,bowlId]`; it calls `seqAt` for positions 1 through 6 and stops as soon as an equality is found. Therefore, for a six-element sequence, the output is the **first 1-based position** whose value equals `bowlId`, or 0 if there is no match. Duplicate values therefore resolve to the first match.

## Production adaptation

Accepted production operations 34 and 35 return a direct table `[6,o1,o2,o3,o4,o5,o6]`, not a sequence descriptor. Operation 36 accepts a two-cell allocated tuple `[orderTable,bowlId]`, reads the six direct table entries, and returns a small integer. It does not mutate the input tuple or order table.

## Measurable contract

- Input: allocated two-cell argument tuple; cell 0 is a valid handle to an allocated direct table with header 6 and six values; cell 1 is a FALSE small integer.
- Output: smallest `i ∈ {1,…,6}` for which `orderTable[i] = bowlId`; 0 if no such i.
- The six values are compared exactly. No permutation-only restriction is imposed; duplicates return the first match and arbitrary small values are allowed, matching op53's search semantics.
- Invalid direct-table header (anything other than 6) raises `E_BOWL_POSITION_LENGTH`.
- The tuple, table and all their cells remain unchanged. Repeated calls are deterministic.
- Excluded: unallocated/invalid pointers, physically truncated tuples/tables, corrupted heap, and non-small-integer object handles. The runtime exposes no safe allocation-extent metadata, so this stage does not claim physical pointer safety.

## Independent oracle and tests

`tools/stage19_bowl_position_design_oracle.mjs` recursively enumerates all 720 permutations in JavaScript and checks all 4,320 (permutation,bowlId) pairs, plus inverse/bijection properties. It separately checks 12 probes, including duplicates, missing values and negative values. The Python fixture generator independently enumerates with `itertools.permutations`; the offline audit must recompute each expected position from parsed input rather than trusting fixture metadata.

Native gate: original FALSE runtime pin `eb3135565a8670cced3f6bbca4dbf7b014c45634`; source pin is the exact dispatch commit. Six chunks each cover 120 orders × six IDs. Additional probes, bad-header controls (5 and 7), and deliberately corrupted expected-value controls are required. A queued run is not PASS; acceptance requires completed Native logs, exact source/runtime pins, artifact SHA/CRC, and independent audit. No main/merge.

## Transition policy

Routine advancement to the next numbered project stage does not require separate user approval. This records the user's clarification on 2026-11-21; substantive scope or policy changes remain separate decisions.

## 2026-11-21 — Stack-layout correction following run 44947691306

Verified run 44947691306 / job 136978517135 as completed/failure on source 8a0d58e218dac1b588ce63904be55ea4ad728348. Artifact 14723939744 SHA-256 `0507a30ae095fb651bd4d574ed16b4c89d3591726b2a468a92859af6c7b8210c`, 44 entries, ZIP CRC clean. `diagnostic_first_scalar.stdout.txt` yielded `STAGE19_DIAG_RESULT_SIX` for the first expected position 1, and the original interpreter emitted `STAGE19_BAD_LENGTH_ACCEPTED` for headers 5 and 7. The earlier double-dispatch candidate (run 44940370617) failed at the second `!`, before a positive marker.

The fixture generator incorrectly inserted `b;` between appending the order pointer and the bowl ID to the two-cell tuple (`d;a;!b;1a;!`). This pushed an uncounted stack item while `z` was used as the indexed heap length. As a result, `36h;!` fetched the nearby numeric table header (6) instead of the stored op36 quotation; double execution tried to execute a number, causing the earlier stack type mismatch. The corrected form is `z;b:d;a;!1a;!b;s:b;36h;!!o:`. The same repair applies to exhaustive cases, probes and invalid-header controls; the diagnostic injection anchor is updated accordingly. This is a QA-fixture correction, **not** a production code correction, Native PASS, or Stage19 acceptance. Stage18 remains last bounded accepted. Require the single marked push's completed original-FALSE Native evidence plus independent offline artifact verification before acceptance.

## 2026-11-22 — Stage19 bounded contract accepted after independent native artifact audit

Run [45065591190](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065591190), job 137340893421 completed success on source-locked SHA cab8ae7e2be3735e431a5547eb2ac149f02df438. Original FALSE runtime eb3135565a8670cced3f6bbca4dbf7b014c45634. ZIP artifact 14770988105 SHA256 ce1341de1e71e4ae66c50f1ce0a32052af2348cdb39c8c34fd4bf0a82e561868, 64 entries CRC clean. Independent offline auditor recomputed all 4320 first-match values from native test-program inputs, verified six exact normalized stdout streams and 720 order markers, checked 5040 input table cell assertions, 12 probes, two bad-header rejects, and two mutant rejects. Two independent corruptions of the evidence were deliberately rejected by the auditor. The source blobs were matched to GitHub's Git SHA-1 blob IDs. The exploratory tuple diagnostic is not a gate and separately exits 1 ("stack not empty"); that result remains disclosed and is not called PASS. Acceptance is strictly **BOUNDED_CONTRACT_ONLY**; invalid pointers, physically truncated allocations, and invalid object handles were not tested. Stage20 has not begun. No merge/main.
