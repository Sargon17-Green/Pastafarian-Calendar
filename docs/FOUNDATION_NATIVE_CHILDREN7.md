# Indexed native H lookup and independent A(r) block generator

**Stage 1, 2026-10-25.** Previous archived-state job reached
seven positive achievements but failed only the *negative*
seek-mutation assertion; remediation and an additional exact
native-combinatorial block test are committed, CI pending.

## Actual CI failure diagnosis

[Run 40204884990](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40204884990)
completed **FAILURE overall**, with **7/8 jobs SUCCESS**.
Job `native_H_transfer` completed:

- All 101,594 H(s,N) cells computed natively and exported
  to a 572,279,002-byte fixed-record archive.
- Full 45-month root and four prefix SHA256 checks passed.
- Native indexed lookup passed for all eight selected rows;
  each of 16 sampled 2,809-byte values matched an
  independent full SHA256 reference.

It then failed at `STAGE1_NATIVE_H_INDEXED_MUTATION_FALSE_PASS`.
The intentional mutation shifted a character within a
**fixed-width, leading-zero padded hexadecimal integer**.
A one-character shift can still parse the same integer.
The negative control was inadequate; the actual 16 indexed
goldens and positive lookup logic were unaffected.

The repaired mutation seeks the PRECEDING whole 5633-byte
record, `H_1(113)` rather than `H_1(114)`. Both are valid
native records with independently locked, different SHA256.
The test now expects `NATIVE_H_INDEXED_ROOT_MISMATCH`;
a misleading positive pass remains a hard failure.

## New independently computed old-month A(r)

The original full-year test used independently calculated
Python child blocks. The present new *test-only native
SystemVerilog* fixture `tests/tb_weave_native_H_children7.sv`
instead reads only two values from the **native-generated**
archived transfer:

```text
H_7(746)
H_7(745)
```

After consuming the legal woven prefix `[1,2,3,4,5,6,7]`,
the remaining positive started-month counts are

```text
r = [114,107,118,108,105,80,114].
```

For `R_j=sum(r_1...r_j)` the ordered-LAST count factor is

```text
A(r) = Π_(j=2..7) binomial(R_j-1,r_j-1).
```

The module calculates every binomial **within native SV**
in 864-bit exact integer arithmetic, using checked small
division over 32-bit limbs. It then generates:

```text
parent = A(r) * H_7(746)
old_child_i = A(r - e_i) * H_7(745),  i=1..7
fresh_child_8 = parent - sum(old_child_i)
```

No Python-produced word, rank-interval ledger, or child
completion count is loaded by this test. It rejects
non-exact divisions and a sum larger than the parent.
Each parent/child is serialized in a 2809-byte BE binary.

The nine independent exact-arithmetic golden SHA256 values
are:

```text
parent: c89443f21642a9cbacbc12f4e6d970ab4815806d3b1b6dc836f247c1a4cc8849
next 1: 0b72169fe3c363a5a56b37f225bc1b45ec78793a430eca85419a3700a576f727
next 2: 0f23e693e34c220dcc004ff9c7b02bfd421c957bd4f8a273f3e1e5663b81db17
next 3: 9616b8efa8fadbecc7edf35a9577807f96f46311840a46dac3127a2d9a71fba1
next 4: d38ddf106d30d6cdf6be7cd24015d2ee499dcf149e3d83004c1c6eafe5b1f074
next 5: 66c270cb320cf87e59e93216273279c2eba4a8509c71b3028897c793610671ef
next 6: d563dfc476051de9f88006796f71cb4fe5614a546f77da485912ff3ec427cfaf
next 7: bbdfde541270cc68fe80e726546e220c34c0e5dfe918f5a5d2f5e4ec3b8dd2c7
next 8: 002b3835ca88649360d71268823385c79d12d5ff1f9950e2bd4fd77eb3e2b1fb
```

A second local independent exact Python check recomputed
all nine hashes in this session and confirmed
`A(r)*H_7(746)=sum_{i=1..8}child_i`.

The fixture is integrated into
`scripts/verify_native_H_indexed.sh` and the existing
bounded `native_H_transfer` CI job. A compact 9-file
evidence bundle and execution log are archived; the
572-MB H table remains CI-temporary.

## Next contract gate

Successful CI would certify one complete seven-started-month
lexical partition computed **entirely in native SV**.
It would still not constitute the all-day native lexical
unrank, a production hardware date converter, or qualified
Kalaallisut lexical review. Stage 1 remains OPEN,
0/64 names approved; do not merge QA PR #20 or edit main.
