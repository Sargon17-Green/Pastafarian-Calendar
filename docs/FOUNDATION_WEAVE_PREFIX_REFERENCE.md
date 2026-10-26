# Foundation weave — independently reproduced lexical prefixes

**Scope:** only the Foundation year for `c=t=-15055671`,
45 canonical month lengths and the test-only 177-base-M-digit
selected rank. This is a checkpoint, **not a final date oracle**.

## Reproducible validated prerequisites

Icarus-12 CI [39842311226](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39842311226)
completed SUCCESS for the whole 45-month full-root calculation
and selected wide rank. Both SHA256 checks passed:

- 45-month valid-word count: **22470 bits**, SHA256 of minimal
  big-endian integer `925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da`.
- Selected rank: **22469 bits**, SHA256
  `2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06`.
- Icarus root and rank job outputs were stored as
  `stage1-full-weave-root-qa` artifact in this exact run.

## Independent first-symbol lexical calculation

A legal woven word must begin with month ordinal **1**.
Its second symbol can only be 1 or 2.

After fixed legal prefix `[1,1]`, month 1 has **113**
remaining appearances. Every subsequent month remains fresh.
The exact completion count (C([1,1])) is evaluated by
initially inserting month 2 into these 113 month-1 letters
subject to the required last-occurrence order and then
applying the first-occurrence transfer for months 3..45.

Independent arbitrary-precision arithmetic gives:
- `bit_length(C([1,1]))=22465`;
- minimal big-endian length `2809` bytes;
- `SHA256(C([1,1]))=642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac`.

Since the selected **one-based** rank is larger than this
first lexical block, its first two month ordinals are
**`[1,2]`**. The remaining zero-based ordinal is obtained
by subtracting the `[1,1]` block size.

This result is **independent arithmetic research** only until
the SystemVerilog `+prefix11` job and `tb_weave_prefix2` pass.
The 22528-bit test-only module has been extended with an
exact prefix count path, with a bounded additional run and an
external SHA256 verification. It does not assume that months
are consecutive blocks.

## Exploratory longer prefix, NOT SV verified

A sequential independent arbitrary-precision prefix calculation
recovered the first **11** monthly ordinals:

```text
[1, 2, 3, 4, 5, 6, 7, 4, 8, 9, 10]
```

Do not present these as an approved calendar calculation. The
general suffix-query algorithm became expensive during that
experiment, and an attempt to extend far beyond the initial
prefix exceeded the permitted bounded local execution window.

Resource profiling, memoization, bounded computation and an
equivalent independent SystemVerilog oracle are prerequisites
for further unranking.

## Separate month-name permutation

Independently, bowl 5 with seal 33 selects 45 distinct
**canonical month-name indices** out of 47 via a two-digit
`47P45` selection. The 45 index sequence is recorded in
`FOUNDATION_MONTH_NAME_45_INDICES.csv`.
Unused indices are 21 and 47. This has no relation to
sorted natural-language names or their approval status.

The month-name sequence is **written in SystemVerilog** as
`tb_foundation_month_names.sv` but its new CI verdict
remains pending. It cannot yield the final month name until
the woven ordinal at the target day is known.

**Stage 1 stays OPEN**, the full 4244-step word and the
canonical month index 20 / occurrence 56 remain unverified,
and qualified Kalaallisut approvals remain **0/64**.

## Follow-up research witness: prefix [1,2,3]

An independent Python arbitrary-precision calculation (using the
same normative last/first-occurrence transfer, without HDL) gives:

| Fixed prefix | bit length | SHA256 of 2809-byte big-endian integer |
|---|---:|---|
| `[1,2,1]` | 22465 | `0a29d31d02e980a1ae807575c85a908bd31a05eb73b521a80f7ee3f2e925f1a7` |
| `[1,2,2]` | 22465 | `50064b46e82a20681a0e100e8a1516e0b4c151398231dd2f898be22f07bb9866` |
| `[1,2,3]` | 22470 | `a89a9799db0649b78a5b24bf150f57dc11e549ce2d0d42088929974237762dde` |

A simple exact identity reduces compute:
`C([1,2,2])/C([1,2,1])=C(219,114)/C(219,113)=53/57`.
The first two prefix blocks together are strictly below the
remaining selected rank after `[1,2]`, so the next ordinal is
**3**. The third-block remainder lies inside the selected
block, not at a boundary.

These figures are **research witnesses**, not native CI PASS.
`tests/tb_weave_full_root.sv +prefix121` and the companion
`tests/tb_weave_prefix3.sv` now implement an executable
check requiring all three binary SHA256 matches.
