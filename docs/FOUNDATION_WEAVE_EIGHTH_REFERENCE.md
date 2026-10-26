# Foundation woven month: eighth-symbol checkpoint

**STATUS:** exact independent arithmetic completed; test-only
SystemVerilog source written; **new CI result not yet verified**.

## Verified native prerequisite

[Run 40125682591](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125682591)
completed SUCCESS in all **five jobs** on implementation
`ec22b0487f1426a1bba5c549880a55a1ef7813d4`.
The real Icarus log contains:

- `STAGE1_SEVENTH_THREE_SOURCE_MERGE_SHAS_PASS`
- `STAGE1_SEVENTH_ALL_21_INPUT_SHA256_PASS`
- `STAGE1_SEVENTH_FULL_PRECISION_BLOCK_SHA256_PASS`
- `STAGE1_FOUNDATION_WEAVE_LEX_PREFIX7_PASS ordinals=1,2,3,4,5,6,7`
- `STAGE1_FOUNDATION_SEVENTH_ORDINAL_SHA256_PASS`

Older stage-1 arithmetic, lengths and indexed month-name tests
remained green. Only seven of 4244 physical month ordinals
have native acceptance.

## Independent exact eighth choice

The selected seven-symbol prefix is `[1,2,3,4,5,6,7]`.
Every one of the seven started month ordinals has remaining
occurrences, specifically `[114,107,118,108,105,80,114]`.
The first fresh index is 8. The reference count for
`[1,2,3,4,5,6,7,1]` has 22464 bits and SHA256
`0b72169fe3c363a5a56b37f225bc1b45ec78793a430eca85419a3700a576f727`.

The seven already-started-label blocks have exact ratios
relative to the first block:

```text
1 : 1
2 : 53/57
3 : 330/323
4 : 306020/328491
5 : 132658240/146835477
6 : 365288495/533244627
7 : 2917684055/2982394728
```

The last ratio **does not fit a signed 32-bit `integer`**.
The new `tb_weave_prefix8.sv` explicitly uses **unsigned 64-bit
numerators and denominators**, performs exact 64-bit
limb-serial division of a 22528-bit integer, and verifies the
multiply-back identity.

The eighth choice (the first fresh month 8) block is
computed as `C([1..7])-sum(C([1..7,i]),i=1..7)`.

Exact independently computed SHA256 over the fixed 2809-byte
big-endian representation of the eight child counts:

```text
next 1: 0b72169fe3c363a5a56b37f225bc1b45ec78793a430eca85419a3700a576f727
next 2: 0f23e693e34c220dcc004ff9c7b02bfd421c957bd4f8a273f3e1e5663b81db17
next 3: 9616b8efa8fadbecc7edf35a9577807f96f46311840a46dac3127a2d9a71fba1
next 4: d38ddf106d30d6cdf6be7cd24015d2ee499dcf149e3d83004c1c6eafe5b1f074
next 5: 66c270cb320cf87e59e93216273279c2eba4a8509c71b3028897c793610671ef
next 6: d563dfc476051de9f88006796f71cb4fe5614a546f77da485912ff3ec427cfaf
next 7: bbdfde541270cc68fe80e726546e220c34c0e5dfe918f5a5d2f5e4ec3b8dd2c7
next 8: 002b3835ca88649360d71268823385c79d12d5ff1f9950e2bd4fd77eb3e2b1fb
```

All eight add exactly to the selected seven-symbol parent.
After subtracting earlier lexical siblings from the
original 177-digit selected root rank, the remaining rank
falls in **next month ordinal 4**. Thus the independently
researched prefix is `[1,2,3,4,5,6,7,4]`, in agreement
with the previously reported first 11 symbols. This
is **not an SV PASS** until the new CI run proves it.

`tests/tb_weave_full_root.sv +prefix12345671` now produces the
full-width independent block. `tests/tb_weave_prefix8.sv`
derives the remaining seven blocks and checks their partition,
exact ratios, lexical rank and expected eighth ordinal.
`scripts/verify_weave_prefix8.sh` validates 28 prior
hashes from **four immutable successful CI jobs**, then all
eight new expected hashes. The isolated QA job has an
explicit 22-minute / 4-GiB memory budget.

## Scope boundary

This eighth-symbol fixture is a narrow TEST-ONLY checkpoint,
not a solution to efficient 4244-symbol unranking. The
full-word reference hash has been derived in independent
research, but not by native SV. Source language qualification
remains 0/64 approved Kalaallisut labels. Production RTL
still intentionally has no valid calendar output. Stage 1
is OPEN; no Stage 2 or `main` merge is authorized.
