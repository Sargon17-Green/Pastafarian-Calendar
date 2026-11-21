# QA31AT — source-pinned byte-class branch and EOF gates over 200 frozen original Native traces

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ  
Branch: qa-befunge98-stage1-order-isolation-20261008  
Date: 2026-11-07  
Verified previous HEAD: d3edbc36a8d94786792dcbf7c7f0e5304e44f8de  
Original production source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`  
Immutable original QA31AI signed ZIP SHA256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`

## Exact original source predicates (CONDITIONAL)

The source rows were fetched by original Git blob and each exact literal
source ray was SHA256-checked independently of the local study scripts:

- Row y=8, x=11..185 inclusive (175 original source bytes, 168 nonspace
  executed opcodes): SHA256 `828c1224365bcf41b07be0822ea3adb14d1e5cdc5da882449874c145f13fc41d`.
  Original source g(57,8) and g(151,8) read memory M=(0,49). The
  stack-symbolic expression at j(185,8) simplifies to
  **61 * int(C>47) * int(58>C)**, where C is the value in M.
  Thus j185 operand = 61 iff C is ASCII 48..57, otherwise 0.
- Row y=17, x=11..335 inclusive (325 source bytes, 318 executed
  nonspace opcodes): SHA256 `8987907dd936ad0795ebef2c228810ed6a837ab49325fd011f603a95666062e5`.
  Four original-source g reads at x57, x129, x202, x275 all target
  M=(0,49). Original arithmetic computes
  **61 * int(C in {9,10,13,32})** at j(335,17).
  These are TAB, LF, CR and SPACE. No other integer value passes
  the original unchanged-source source-ray predicate.

All source expressions were derived through a stack-structural AST
with an initially empty symbolic stack (no prior-stack dependence)
and tested numerically over all 256 possible byte values and selected
negative/boundary integer values. The proof is local, conditional on
traversing that exact source suffix without modifying it or entering
its middle; it is NOT a proof of global execution reachability.

## Fully signed original physical evidence

Two INDEPENDENT source/receipt readers each re-read:
8 original QA31V shards, all original signed raw-stdin/gzip SHA256
and HALT receipts, 200 case identities, **3,628,390 STEPs** with
strict next→IP continuity, and **all 2,500 physical byte-class gate
visits** including exact original opcode, IP, Funge stack pre/post
and memory-read ownership through the entire source suffix (not
only the final j instruction).

There were exactly:
- 1,800 original `~` input byte reads. All 1,800 wrote the same byte
  to M=(0,49) through signed `p(60,5)` and reached j(185,8).
- j(185,8): 1,800 physical events; 1,100 operand=61 (digit) and
  700 operand=0 (nondigit).
- j(335,17): 700 physical events (all 700 nondigits); 680
  operand=61 (620 space, 20 TAB, 20 LF, 20 CR) and 20
  operand=0 (10 NUL byte=0 and 10 byte=255).
- M=(0,49) had exactly 2,000 signed puts: 200 from p(58,2) to
  initialize it and 1,800 from p(60,5) for individual bytes.
- 140 signed `~` attempts at EOF. For each, the source IP at
  (13,5) had an empty post-stack and next IP (12,5) (reflection).
  EOF did **not** enter either digit/delimiter gate as a synthetic
  byte in the observed corpus. Evaluating source predicates on
  hypothetical C=-1 is a MATH simulation, NOT an observed EOF
  memory write.

### Source-conditional class table vs observed values

| Input byte group | Source j185 | Source j335 if reached | Original observed j185 / j335 |
|---|---:|---:|---:|
| ASCII digits 48..57 | 61 | 0 | 1,100 / 0 |
| TAB=9, LF=10, CR=13, SPACE=32 | 0 | 61 | 680 / 680 |
| NUL=0 and 0xFF=255 | 0 | 0 | 20 / 20 |
| all other 240 byte values | 0 | 0 | 0 / 0 |

IMPORTANT: the table class 'all other 240' refers to remaining
byte values after the 16 witnessed values, not a claim about global
input routing. The full `source_byte_domain.csv` in the evidence
archive distinguishes conditional math from physically witnessed
events in 256 rows, and marks unwitnessed bytes zero observations.

## Independent adversarial tests and durable artifact

The second oracle imports no forward code, reconstructs all 200
original signed gzip traces and original memory owners, compares
all 2,500 complete source corridor events, and rejects **28/28
synthetic non-no-op corruptions**, including source/opcode changes,
wrong branch values, fake SHA, truncated cases, fictitious EOF
bytes, and fabricated Stage1/Native success.

Reproducible read-only evidence:
`/Befunge_QA_Artifacts/QA31AT_BEFUNGE98_KYRGYZ_SIGNED_BYTE_EOF_GATES_20261107.zip`
SHA256 `b0cd81b8239197831704fdcf23bc1bec67b621daddcc045e0ce1e8a76c567447`,
41,645 bytes, 11 ZIP entries, **11/11 ZIP CRC** and **10/10
manifest-member SHA256** PASS. The ZIP includes both full independent
Python audit scripts, original source-byte pins, all 200 per-case
j185/j335 signed event ledgers, raw-stdin/EOF receipts, 256-byte
conditional source truth table, complete logs, and summary. It
references (does not duplicate) the immutable 46MB QA31AI archive.

No NEW Native run and no new GitHub CI run over the large corpus.
No production changes, no main/merge/Stage2. This is QA31AT
**FINITE ORIGINAL-SIGNED QA PASS + CONDITIONAL SOURCE PREDICATE
PROOF only**. It is NOT all-natural-input correctness or Stage1
functional/geometric/global PASS; physical alternative input IP
paths, self-modifying paths and counter-target reachability remain
UNKNOWN. No concrete independent natural input is derived that
targets q=(1,49) or m=(3,49).

## NEXT: QA31AU

Investigate the **pre-byte owner / EOF-reflection and re-entry
state machine** around the original `~(13,5)`, `p(60,5)`,
and the two source-constant conditional gates. Source-pin any
finite alternate ingress from the branch after EOF and the
input-byte owner chain into original counter-write corridors;
use original 200 signed STEP/stack receipts as physical anchors
and independent source/byte oracle with hostile controls. Do NOT
label hypothetical input bytes or artificial states as original
Native witnesses. Only an independently proved concrete new raw
stdin is eligible for a fresh original Native experiment capped
at <=25,000 STEP/case. Stage1 OPEN; no main/merge/Stage2.
