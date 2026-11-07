# QA31AX — independently refuted 11-byte counter-gate candidate on the original source route (2026-11-07)

**Project:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**QA branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified preceding HEAD:** `6c95c91e83c79ff62991922e81e52c71a7da12da`  
**Frozen original source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Immutable original signed QA31AI ZIP SHA256:** `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`

## Outcome: candidate falsified, not a Native witness

The source-only 11-byte input hypothesis from QA31AW,
raw hex `3120302030203030302030` (ASCII `1 0 0 000 0`),
**does not reach the intended row32 counter gate via the
canonical source input route**. The crucial omitted original
gate is **j(113,11)**, ahead of the digit-processing ray
on original row14:

```
Original source condition on row11: j_offset = 61 * int(q > 3)
Original q=3 signed digit donor: j_offset=0, enter normal row14
Candidate q=4 after extra SPACE: j_offset=61, jump to (175,11)
Then original source x(235,11) builds vector (-225,+33)
and enters (10,44), the deterministic 7×(-1) and @ rejection ray.
```

The local row26→row14 numerical composition in QA31AW
was correct **only conditional on both rays being traversed**.
It omitted the real original-source row11 q>3 guard and thus
is **NOT** a concrete proof of `q=4,m=1` at row32.

### Signed original donors and independent authenticity

This is NOT a new original Native execution. Two already-signed
original Native traces, independently re-read from the SHA-pinned
original QA31AI→QA31AH→QA31Y→QA31V_SHARD0 archives and manifests,
provide the anchored input-loop transitions:

- `pair_30_30`: original raw input `312030203020303030`,
  SHA256 `7e46069c4c2466d44f5c3e702e0ead2b5dd0d50f441cbe2d65abf66a15c78ea9`;
  original 17,875 STEP HALT trace with gzip SHA256
  `3c6650510eca52dd3614ab136cc4b090c07a8b41520486b1a64e52474f18603a`.
  Its **first 9,597 executed source transitions** have
  `q=3,m=1,n=0,b=48`, a verified empty-stack next `~(13,5)`
  at STEP 9,598. In the actual original signed case STEP 9,598
  is EOF, which reflects to row6 and eventually reaches row32
  with q3. In the constructed candidate it reads the new SPACE.
- `pair_30_20`: original raw `312030203020303020`
  and signed 25,000-STEP-capped HALT receipt; physically
  demonstrates the input-loop SPACE route for q3,m1,n0:
  its last SPACE begins at original STEP 8,758 and
  the next `~` is STEP 10,180 — exactly 1,422 STEP
  transitions later. The source `g/p` dependencies along that
  route are all verified against the candidate's matching
  `b,q,n,m` boundary state, with 12 signed g reads,
  five signed puts at
  `p(60,5)`, `p(152,26)`, `p(248,26)`,
  `p(296,26)`, `p(344,26)`; all write only to y=49.
  They yield `b=32,q=4,n=0,m=0`.
- On the original `pair_30_30` signed final-digit path,
  its digit starts at STEP 8,758; the q-dependent original
  `j(113,11)` is at STEP 9,262, after 504 STEP transitions.
  All earlier reads depend only on the digit or input buffer
  **except g(57,11)**, which reads `q`. Its source-byte
  stack arithmetic determines the first changed IP at that
  gate when q=4. No prior original signed p write or
  newly stitched row26/row5 p write touches the relevant
  source cells y=11 or y=44.

Both original signed gzip receipts were completely traversed;
all original STEP indices, `next→IP` transitions, raw
input SHA256, signed gzip SHA256, HALT states and the
nested archived shard SHA256 were checked. This is **a
two-donor replay**, not a claim to have rerun all 200 traces
during QA31AX (they were checked in earlier phases).

### Exact original source bytes and conditional bounded timeline

The following exact source slices were checked directly from
the original frozen Git blob (not copied from a proposed model):

| Source slice | Original length | SHA256 |
|---|---:|---|
| `y=11, x=10..113` (gate) | 104 | `570dc07da27206e51eab0548078c10e21a1f54633e62040df5b4cd6a588eb61b` |
| `y=11, x=175..235` (reject vector) | 61 | `090341ac93738bad7a395dbe86fed93e2283786f8879b96960fb83714f058afd` |
| `y=44, x=10..179` (reject output/HALT) | 170 | `bd392e166c108ecab5fb6334f9ab298554e69f0a311cbc930725e2e96dcba57a` |

The first original byte ray produces
`61*int(q>3)`. Its `q=3` branch value 0 is
corroborated by the signed original donor. For q4
it computes 61 and jumps to (175,11). The second
source ray comprises 47 nonblank executed opcodes,
constructing x vector (-225,+33). The third comprises
170 instructions, outputting seven times the integer
-1 and finally executing `@` at (179,44).

The following **STEP timeline is a SOURCE-DERIVED CONDITIONAL
PREDICTION; NONE of these are new physical Native receipts**:

| Synthesized STEP | Source IP | Derived effect |
|---:|---|---|
| 9,598 | (13,5) | consume appended SPACE |
| 11,020 | (13,5) | consume appended digit `0` |
| 11,524 | (113,11) | j offset61, enter (175,11) |
| 11,571 | (235,11) | x delta(-225,+33)→(10,44) |
| 11,741 | (179,44) | seven preceding `-1` prints, HALT |

The terminal prediction is within the 25,000-STEP
experimental cap, but **no actual original Native run is
justified for this already-disproved counter-target candidate**.
The first buffered `readline` event's metadata in a future
11-byte original trace would differ from the 9-byte signed
donor; the state-equivalence proof concerns the ordered
consumed characters under ordinary Funge-98 `~`
semantics, not byte-for-byte equality of host read metadata.
The proof is restricted to unchanged original source regions,
normal input dispatch, and the concrete 11-byte candidate.
No global unreachability is asserted.

## Verification, adversarial tests, artifact

Two complete standalone Python source-and-signed-receipt programs:
the forward source/donor-state-stitch verifier and a second
independent original archive/gate interpreter that does **not**
import the first. Both were executed **again from the final
ZIP** successfully with the exact original QA31AI input
archive, and the independent program rejected **25/25
non-no-op synthetic report mutations**. No synthetic mutation
was mislabeled as original Native evidence.

Permanent Library artifact:
`/Befunge_QA_Artifacts/QA31AX_BEFUNGE98_KYRGYZ_SOURCE_ROUTING_NEGATIVE_20261107.zip`.
SHA256 `71276d49be1156cb58a5e568519ee4c8b70fe1a95d7149f9f15d2a8e0efde97e`,
19,245 bytes, 13 ZIP members with CRC 13/13 PASS,
12/12 manifest-member SHA256 PASS.
The original 46MB signed archive is referenced by exact
digest, not included. Contains both complete Python programs,
original Git source pins, full source/donor event-state
ledgers, negative-candidate and conditional timeline fixtures,
actual replay logs and README_HE. This is QA research evidence,
**not a Windows user-execution package**.

**QA31AX PASS for finite source-conditional candidate
REFUTATION**, NOT a positive Native counter witness, NOT
Stage1 global, functional or geometric acceptance.
No source production edits, no new Native run, no new
full-corpus CI, no main/merge/Stage2. Stage1 remains OPEN.

## NEXT — QA31AY

Treat the q>3 guard at original `j(113,11)`
as a now-proven local precondition on the standard
digit route. Analyze all original source-gates and
memory-write ownership that might make q>3 and m=1
reachable at row32 through **different legitimate
natural-input IP routes or source self-modification**.
Start with exact source Git blob and authenticated
signed cases; use separate source/receipt oracles,
adversarial controls, and explicit UNKNOWN where
no path has been proven. Do not propose or run a
new Native case without independent concrete raw stdin
and <=25,000 STEPs/case; no main/merge/Stage2.
