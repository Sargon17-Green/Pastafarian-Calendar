# Native SystemVerilog H(s,N) indexed-state archive

**Status:** Written and pushed for CI; verification not yet completed.
This is a test-only bridge toward native 4244-step lexical
unranking, not synthesizable production RTL.

## Native count computation already proven

[GitHub Actions 40192285282](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40192285282)
completed **SUCCESS 8/8 jobs**. The native `native_H_transfer`
job `121165675248` independently computed a 1602-bit
6-month golden, then the 101594-cell 45-month transfer.
The exact 22470-bit root plus four full-width prefix
completion counts passed predetermined SHA256 checks.
No Python count ledger was used for these computations.

## Fixed-record external index

The same `tb_weave_native_transfer.sv` is extended with
an opt-in `+dump_H` run mode (full 45 months only).
It computes identical exact values in native SV, retaining
only two rolling 22528-bit rows in RAM, and writes every
computed `H_s(N)` state to:

```text
build/native_H_table.hex
```

The archive is ordered by **descending s** (45 to 1), and
for each s by **ascending N** from zero to
`cap_s = Σ_(i<=s)L_i-s`. Each value is exactly
**5632 hexadecimal digits plus one LF byte**, corresponding
to a 22528-bit unsigned integer. For the Foundation lengths:

```text
rows:          101594
record bytes:  5633
total bytes:   572279002
```

The file is large but is a **CI-temporary scratch artifact**.
It is not committed, copied to the user's computer, or
uploaded in the CI artifact bundle. The bounded CI job uses
a 3-GiB virtual-memory ceiling and 31-minute timeout.

To seek state `(s,N)`, compute

```text
record_index = Σ_(q=s+1..45) (cap_q + 1) + N
byte_offset = record_index * 5633
```

The exact formula is implemented independently in
`tests/tb_weave_native_H_lookup.sv` using Icarus `$fseek`
and `$fscanf("%h",...)`. The lookup bench never computes
the recurrence; the producer computes it, the reader
indexes it independently.

## Independent count and index witnesses

The lookup bench reads the native-produced archive for
**s = 1,2,3,7,8,15,44,45** at two independently selected
values `N=cap_s` and `N=cap_s-1`.
Each of its 16 2809-byte binary outputs must match an
independently calculated Python SHA256 reference.

These probes include the 22470-bit full root, fresh
intermediate rows from the 45-month transfer, rows
near both extremes, and the 45th row's base-case
`H_45(N)=1`. The root is also compared bit-for-bit
against the original native SV output.

`scripts/verify_native_H_indexed.sh` first requires
the exact 101594-line/572279002-byte archive layout,
then compiles and runs the SV seek test and validates all
16 external hashes. Its negative control runs with
`+mutate_address`, shifts the first root lookup one
hex digit, and requires an explicit
`NATIVE_H_INDEXED_ROOT_MISMATCH` fatal.

The CI artifact stores lookup/negative logs and small
binary probes, not the 572-MB raw table.

## Next stage-1 engineering dependency

The archive makes arbitrary exact H(s,N) lookup possible
in native SystemVerilog during testing without rerunning
the 45-month transfer for each lexical decision.

A full native lexical unrank must still compute the
started-month ordered-LAST factor A(r), derive every
candidate child count, subtract preceding blocks from
the one-based rank, handle zero/final occurrences, and
reconstruct all 4244 symbols and the word SHA256.
Production ASIC RTL must also implement all five fields
and proper date_valid semantics.

The existing Python-generated 4243-interval ledger
cannot substitute for native candidate-count generation.
Qualified Kalaallisut names remain **0 of 64 approved**.
Stage 1 OPEN, Stage 2 CLOSED, `main` unchanged, QA PR
#20 DRAFT DO NOT MERGE.
