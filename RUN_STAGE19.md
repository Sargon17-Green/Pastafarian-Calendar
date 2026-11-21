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
