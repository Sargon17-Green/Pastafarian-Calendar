# Stage 1: exact 4243-step whole-year rank-interval replay

**STATUS:** Source and bounded CI job written. No new PASS may be
claimed until the corresponding GitHub Actions job log passes.
This is an intermediate test-only SystemVerilog arithmetic milestone,
NOT autonomous HDL generation of completion-block counts or production RTL.

## CI proven prerequisite

[GitHub Actions 40170380568](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40170380568)
completed **SUCCESS in all seven jobs** on implementation
`3b47e7f82b6e5305b1008b85071001471e531c45`.
The `full_year_reference` job executed the entire exact
101594-cell Python transfer plus all 4244 lexical choices in
**15.34 seconds**, and a separate native Icarus SystemVerilog
bench verified month lengths, first/last order, and day 2032.
The full-word SHA256 remained
`e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29`.

## New arithmetic ledger

The Python full-year exact unrank now emits a fixed-width
binary witness alongside the previously approved word:

```text
build/foundation_weave_root.bin            2809 bytes
build/foundation_weave_rank.bin            2809 bytes
build/foundation_weave_all4244.bin         4244 bytes
build/foundation_weave_all4244.hex         4244 hex lines
build/foundation_weave_rank_intervals.bin  23837174 bytes
```

There are 4243 interval entries (all choices AFTER the
forced month ordinal 1), each exactly 5618 bytes:

```text
skipped_count  : 2809-byte big-endian unsigned integer
selected_count : 2809-byte big-endian unsigned integer
```

For each exact parent block count, Python independently
computes *every* legal earlier and later candidate, checks
the partition and records the exact sum of all
lexicographically earlier siblings (`skipped`) and the
selected branch size (`selected`).

## New native SystemVerilog rank-interval replay

`tests/tb_weave_full_rank_replay.sv` independently reads
the binary pair stream and the 4244-symbol word. It does
not accept an updated rank at any position from Python.
It starts with the separately root/rank-hash-checked
selected one-based rank and performs, for every position:

```text
0 <= skipped < old_rank
0 < selected <= parent_count - skipped
new_rank = old_rank - skipped
1 <= new_rank <= selected
parent_count = selected
```

If the next chosen ordinal is the first fresh month,
it additionally requires `skipped+selected=parent_count`
*before* updating the parent. The checker independently
tracks the 45 month-length counters, ensures only previously
started labels or exactly the next fresh label can appear,
checks each occurrence stays in range, and demands
`rank=parent_count=1` with every monthly counter exhausted
at the end.

A negative regression uses `+mutate_ledger` to corrupt
the first skipped rank and REQUIRES the native
`FULL_YEAR_RANK_REPLAY_INVALID_BLOCK` fatal. The shell
runner treats an unexpected success as a failed test.

The runner verifies SHA256 of both 2809-byte root and rank
against earlier **native 22528-bit oracle** goldens; the
word SHA256 and exact ledger length are also checked
before the separate replay starts.

## Acceptance boundary

This checks **all 4243 lexicographic rank transitions in
SystemVerilog using 22528-bit exact unsigned arithmetic**,
but the ledger's child counts are computed by a Python
reference program. It is therefore neither an independent
SystemVerilog suffix count nor a native whole-year unrank.
The full binary ledger can be preserved for independent
reconstruction and forensic replay.

The eventual native full-year implementation must compute
the `H_s(N)` transfer coefficients and started-month
`A(r)` counts itself, produce the branch counts without
looking them up from Python, and reproduce the word SHA.
Separately, synthesizable RTL must handle the actual
five-field calendar query interface; the current
production bootstrap still does not assert `date_valid`.

Stage 1 stays open. The eight verified woven ordinals and
full reference CI green status do not approve the 64 native
Kalaallisut labels (0/64 approved), permit Stage 2, or
authorize any change to `main`.
