# QA31AS — original 200 signed-case stdin parser → initial memory provenance (2026-11-07)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Verified entering HEAD: 498185158443f6636541814424abf58d0717be14
Frozen original production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Original full signed QA31AI source archive SHA256:
9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49

## QA31AS finite findings, **NOT** a global parser proof

The two independent signed-original analyzers re-read all 200
frozen Native cases, all eight QA31V SHA256-pinned source shards, 200
raw-input SHA256/gzip SHA256/HALT receipts and **3,628,390 contiguous
STEP records** with next→IP continuity. They performed **no** new
Native run or new full signed-corpus CI.

All original raw byte sequences are observed at physical `~(13,5)`
in input order; the 200 traces physically consume 1,800 raw bytes
plus 140 EOF reads (EOF represented distinctly from byte 0). All
frozen source byte pins were independently read back at original Git
blob SHA: `~(13,5)`, `p(152,26)`, `p(152,35)`,
`g(198,41)`, `p(384,575)`, `g(195,569)`,
`p(280,860)`, `j(185,8)`, `j(335,17)`,
`g(1347,575)`; all ten exact source opcodes match.

| Original final two raw input bytes | Cases | Physical initial M=(29,1698) |
|---|---:|---|
| ASCII digit, ASCII digit | 100 | p(280,860) puts 10*first_digit+second_digit |
| ASCII digit, TAB/LF/CR/SPACE | 40 | p(280,860) puts first_digit only |
| ASCII digit, NUL (0x00) / FF (0xFF) | 20 | no initial p(280,860) |
| TAB/LF/CR/SPACE, ASCII digit | 40 | no initial p(280,860) |

These are **exhaustive groups of this specific 200-case input
matrix**, not an assertion about other bytes or input lengths.

## End-to-end observed parser value owners

The 180 signed actual puts to staging cell S=(13,49) are:
- 100 at original source `p(152,35)`: two ASCII digit
  suffix cases; all 100 transferred downstream.
- 80 at original source `p(152,26)`: 40 digit+delimiter
  cases transfer downstream and 40 delimiter+digit cases
  write an intermediate zero but NEVER transfer to M.

The fully witnessed 140 signed transfers obey the actual physical
source IP and value chain:
`p(152,26/35) -> g(198,41) -> p(384,575) -> g(195,569)
 -> p(280,860)`.
Every stage target, last-writer identity, put value and g read
value was compared within the exact signed original trace.
There are exactly **140** g reads of S, **140** p puts to
(11,1693), **140** g reads from that staging cell, and **140**
initial puts to M. All 140 values match the corresponding raw-byte
hypothesis for the *observed input class*. The code path for
digit+delimiter transfers the first digit only, whereas a NUL/FF
last byte does not trigger the transfer.

Two source-pinned original control sites are distinct:
- `j(185,8)` executed 1,800 times across these 200 signed
  cases: 1,100 operand 61, 700 operand 0.
- `j(335,17)` executed 700 times: 680 operand 61,
  20 operand 0. The final NUL/FF input cases select zero at
  this gate instead of the observed delimiter continuation.

Four original signed raw-stdin pair comparisons have these exact
FIRST IP/opcode/next differences:
- `pair_30_31` vs `pair_30_09`: j(185,8), STEP 9,118
- `pair_30_09` vs `pair_30_00`: j(335,17), STEP 9,484
- `pair_30_31` vs `pair_09_31`: j(185,8), STEP 8,278
- `pair_30_00` vs `pair_30_ff`: identical IP/opcode/next
  path for the full frozen runs (values may differ)

## Independent gate and reproducible evidence

Source/receipt forward scanner plus a **distinct original gzip
receipt-first auditor** (the latter imports no code from the former)
each independently re-read and hashed the original archive, 200
cases, 3,628,390 STEPs and writer/reader events. The second audit
checked the first report's **all 200 original case identities and
all parser/staging/raw stdin/branch tuples**, rejected **21/21
actual non-no-op synthetic report mutations**, and asserts explicit
global claim false / no new Native. Do not substitute a synthetic
mutant for original-source Native evidence.

Permanent read-only QA evidence archive:
`/Befunge_QA_Artifacts/QA31AS_BEFUNGE98_KYRGYZ_SIGNED_200_STDIN_PARSER_AUDIT_20261107.zip`
32,422 bytes, SHA256:
`f7f4702e84523b852ec40c15cbc59f699f69ae94de2e02c36fd4a1c140aa894e`
11 ZIP entries, CRC 11/11 and ten SHA256 manifest member checks
pass. It contains both complete original-receipt checkers, per-case
raw input/read/put/g/branch tuples for all 200 cases, original-source
byte pins, four divergence checks, standalone CSV+summary, logs,
manifest, and README_HE. The signed 46MB original is not duplicated.

**QA31AS accepted for FINITE 200-case source-pinned original
parser/staging evidence ONLY**. The all-input parser, other bytes,
different EOF sequences, source mutations and physical global
counter-address reachability remain UNKNOWN. The lack of an
independently grounded new natural input producing p to q=(1,49)
or m=(3,49) does not imply global impossibility. No new original
Native action (max 25000 STEP only with independently grounded new
candidate) or GitHub CI, no code production changes, main merge or
Stage2. Stage1 functional/geometric/global gates remain OPEN.

## NEXT — QA31AT

Bound the **original-source byte-validation and EOF gate
predicates** upstream of `j(185,8)` and `j(335,17)`, including the
20 NUL/FF reject routes and 40 delimiter-before-digit early exits.
Use source-pinned arithmetic/branch replays and all 200 signed
raw-input/STEP/stack receipts; derive an independent finite boundary
oracle for byte classes and noncanonical prefix path constraints.
Seek an independently verified concrete new natural stdin that could
reach an original counter-target p, if possible; do not infer one
from a raw-byte substitution or an imagined branch. If no candidate,
retain UNKNOWN and do not run new Native; preserve <=25000 STEP/case
cap for any future justified original experiment. No
main/merge/Stage2; Stage1 remains OPEN.
