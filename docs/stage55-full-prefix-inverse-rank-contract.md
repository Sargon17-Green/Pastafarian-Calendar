# Stage55 Year-5000 — independent full-prefix inverse-rank contract

**Project:** `PC-BRANCH-MATLAB-POLSKI`  
**Scope:** a branch-only QA verifier. This is not production calendar code, MATLAB Native evidence, a Stage55 acceptance, or a release.

## 1. Inputs and locks

The verifier consumes exactly:

- `tests/fixtures/stage55_year5000_middle_word.json` — 4,244 integer symbols, Git blob `cb4983bcb15e4840b26b46ef2c0566ab870a111e`, SHA-256 `82042fef5a65cc8b08120d069fa9d8f31c05e6761040f82c3341328ded9b44e5`.
- `tests/fixtures/stage55_year5000_appendix_a_metadata.json` — 45 multiplicities for Year 5000, Git blob `a1383b111a88203b0d652b8f0a0e9af1a8b75f25`.

The locked vector sums to 4,244 and ranges from 25 to 122. The word must contain exactly those multiplicities, with first occurrences and last occurrences each strictly increasing by label.

The vector is read as a pinned input. This verifier does **not** claim an independent normative derivation of the 45 lengths; that remains a separate NEXT gate.

## 2. Mathematical contract

A legal word is a permutation of the fixed multiset over labels `1..45` satisfying:

1. first occurrence of label `j` precedes first occurrence of `j+1`;
2. last occurrence of label `j` precedes last occurrence of `j+1`.

Words are ordered lexicographically by numeric label. For every prefix `P`, the verifier emits its exact 1-based inclusive rank interval `[lo(P), hi(P)]`. The interval width is the number of legal completions of `P`.

For each prefix state, the next-symbol blocks must partition its parent interval exactly. If the selected symbol is `x`, its child interval begins after all blocks for legal symbols smaller than `x`, and its width equals the block for `x`. The terminal full-word interval must be a singleton.

## 3. Independent inverse algorithm

`tools/stage55_full_prefix_inverse_rank.cpp` is a standalone C++17/GMP implementation. It does not import MATLAB code, the production calendar, the grouped-prefix unranker, or the projection oracle.

It counts completions by their first suffix symbol using a two-basis endpoint dynamic program:

- already-open labels and the next unopened label form the base suffix; their first-occurrence conditions are already satisfied by the fixed prefix;
- each later unopened label is inserted with its last copy fixed at the end and its first occurrence constrained to follow the preceding unopened label;
- for a new label of multiplicity `m >= 2`, the endpoint coefficient at first-position `p` is `C(N + m - p - 1, m - 2)`;
- the old first-position distributions are represented by two shared basis vectors. The ordered-opening insertion applies the same exact linear transform to each basis; it does not invoke the unrank counter;
- when at most one label remains unopened, only ordered last endpoints remain, and an exact common-denominator closed form supplies all next-symbol blocks.

All arithmetic is GMP integer arithmetic. Every exact division is checked. At every one of the 4,244 prefix positions the C++ core asserts that child blocks sum to the parent count and that the selected child width equals the emitted interval width.

## 4. Independent controls and acceptance assertions

The C++ self-test exhaustively enumerates 16 small multiplicity families and compares every distinct prefix partition against the DP: 1,172 legal words and 4,253 distinct prefixes.

For the full input, the runner verifies:

- input Git blob and SHA locks;
- 45 labels, 4,244 symbols, multiplicities, first-order and last-order legality;
- exactly 4,244 nested prefix intervals;
- root count SHA-256 `c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8`;
- inverse-rank SHA-256 `cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6`;
- `R = floor(T/2) + 1` and a singleton terminal interval.

When `--reference-trace` is supplied, the GMP core also compares every new interval to the archived unrank trace using exact GMP arithmetic. That optional differential is QA evidence; the inverse algorithm itself does not consume the unranker or its counter.

## 5. Runtime and outputs

Bounded input: 45 labels, 4,244 symbols, multiplicities 25–122. The runner enforces a 270-second core limit and the workflow has a 15-minute job timeout.

The output directory contains:

- `prefix_intervals.jsonl.gz` — all exact prefix interval endpoints;
- `report.json` — locks, root/rank hashes, counts, runtime, and scope limitations;
- `run.log` and `source_lock.txt`;
- copies of the verifier source and exact input fixtures;
- `SHA256SUMS.txt`.

The workflow uses Ubuntu 24.04, Python 3.12, C++17 and GMP. It is a GMP/CI verifier only; it does not run MATLAB Native.

## 6. Explicit non-claims and NEXT

This gate does not accept Stage55. It does not rederive the 45 month lengths from normative rules, independently validate the six cutlet partitions, or independently validate the Polish name mapping. It does not run the MATLAB Native or full production differential gates. `LAST_COMPLETED_STAGE` therefore remains 54.

NEXT: independently reconstruct the 45 month lengths from the authoritative project rules/catalog, then validate all six cutlet partitions and the Polish name mapping without using `sourceLanguageCatalog` as both source and oracle. Only after those separate gates should the remaining Stage55 production/Native/final-audit gates be considered.
