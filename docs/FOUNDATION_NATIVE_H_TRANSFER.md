# Native SystemVerilog rolling transfer for woven-month completions

**Stage 1 implementation test, NOT production RTL. Current status:
committed source, CI still pending.**

## Independent native H(s,N) calculation

A fully independent native-SystemVerilog test-only implementation
now computes the exact mathematical transfer used by the
15-second full-year Python oracle. It does **not** read or
use the Python word, 23.8 MB rank ledger or block witnesses.

Let v be the length of the first not-yet-started month.
The count after s started labels and N remaining occurrences
among them is the integer

```text
H_45(N) = 1
H_s(N) = H_s(N-1)
       + C(N+v-2,N) * H_(s+1)(N+v-1)
H_s(-1) = 0.
```

Only these arrays are retained:

```text
logic [22527:0] later [0:4244]
logic [22527:0] current [0:4244]
logic [863:0]  binomial_coefficient
```

The transfer uses **two rolling rows**, avoiding memory
for all 101,594 huge integers simultaneously. Every
binomial division is explicitly exact through a 32-bit
limb-serial algorithm; wide Icarus `/` is not trusted.
The state loop checks each addition for overflow.

## Bounded independent checks

**Fast preflight:** compile the same SystemVerilog module
with `WIDTH=2048, NMONTHS=6`. It must compute the
independently pinned 1,602-bit six-month root, agreeing
with the older first-position transfer test.

**Full native benchmark:** compile with `WIDTH=22528,
NMONTHS=45`, calculate all 101,594 transfer cells,
and compare these SHA256 witnesses on its own binary
outputs (not copied from the Python artifacts):

| Native SV derived quantity | SHA256 of 2809-byte BE integer |
|---|---|
| `H_1(114)`, full root | `925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da` |
| `H_1(113)`, suffix after `[1,1]` | `642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac` |
| `A(r)*H_2(220)`, suffix after `[1,2,1]` | `0a29d31d02e980a1ae807575c85a908bd31a05eb73b521a80f7ee3f2e925f1a7` |
| `A(r)*H_3(338)`, suffix after `[1,2,3,1]` | `b66cf4cc1afb8b2b604e574ff0ba1d788b0eb83bb7dbfc67a103a08ef220d340` |
| `A(r)*H_7(745)`, suffix after `[1,2,3,4,5,6,7,1]` | `0b72169fe3c363a5a56b37f225bc1b45ec78793a430eca85419a3700a576f727` |

The independent exact-Python H recurrence reproduced the
same five hashes in this work session. **This is a
mathematical precheck, not native CI PASS for this new code.**

The `native_H_transfer` QA job has a 31-minute overall
cap, a 240-second six-month preflight, a 1,450-second
full benchmark and a 3 GiB virtual memory ceiling.
It preserves all outputs and evidence logs even if a
resource cap is reached.

## What is and is not achieved

If successful, this establishes a **natively computed
SystemVerilog exact 45-month completion transfer** and
specific independent block counts, rather than merely
replaying Python-produced ranks. That removes one major
algorithmic obstacle to native full-year unranking.

It still does **not** implement 4,244 lexical choices
natively: a big-integer started-label factor `A(r)`,
branch enumeration, exact rank subtraction at all 4244
positions, edge cases with exhausted month counts, and
word SHA comparison must be integrated independently.

Separately, the production ASIC module currently outputs
no asserted calendar date, and qualified native speaker
approval of 64 Kalaallisut names remains 0/64.

No edits to `main`, no merge of draft QA PR #20, no
Stage-1 signoff and no Stage-2 launch.
