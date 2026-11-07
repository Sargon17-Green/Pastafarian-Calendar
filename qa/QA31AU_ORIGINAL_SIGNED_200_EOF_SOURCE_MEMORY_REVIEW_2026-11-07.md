# QA31AU — original signed 200-case EOF reflection, input-memory ownership and bounded re-entry proof (2026-11-07)

**Project:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Exact preceding HEAD:** `7f1dfbf70a9bc0362219136e825f1f2c3f14b156`  
**Original production Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Immutable original 200-case QA31AI ZIP SHA256:** `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`

## 200 original signed Native traces, NO new Native

Two independent standalone original-receipt readers checked the exact 8 nested
QA31V shard hashes, all 200 signed raw stdin/gzip trace SHA256 and HALT
receipts, and **3,628,390 contiguous original STEPs** with actual next→IP
consistency. No original Native runner was started; no new full-corpus
GitHub CI was performed; source production unchanged.

All 200 cases have exactly one initialization put at `p(58,2)` to
`B=(0,49)`; the 1,800 physically consumed input bytes each have
a corresponding `p(60,5)` write to the same B. Thus exactly **2,000**
writes to B in the original 200 cases; no third physical writer
was observed. All consumed bytes subsequently traversed the pinned
first byte gate `j(185,8)` (1,800 events), and its 700 non-digit
cases traversed `j(335,17)` (700 events).

### What a real EOF does

Exactly **140/200** cases execute `~(13,5)` at EOF; the other 60
HALT before a physical EOF. Original EOF `~` has **empty pre/post
stack**, next IP `(12,5)`, and reflected next delta `(-1,0)` in
all 140 receipts. Crucially, EOF is NOT a synthetic byte `-1`
written to B.

For these same 140 natural stdin cases, the *preceding* input
return-to-loop vector is source IP:

| Source x IP, before EOF | Actual x vector | Cases |
| --- | --- | ---: |
| `(309,14)` | `(-299,-9)` | 100 |
| `(405,26)` | `(-395,-21)` | 40 |

Both physically redirect the IP to `(10,5)` then source
`>(10,5)` → `#(11,5)` skipping source `v(12,5)`
and entering `~(13,5)` with an empty stack. The two x origins
and their pre-stack, target, arrow and trampoline `#` were
independently verified in every EOF case. These ingress owners are
**finite observations**, not a global uniqueness theorem.

### Conditional original-source exit theorem and physical replay

Original source cells `(12,5)=v`, `(12,6)=>`, and the original
62-byte source corridor y=6, x=12..73 inclusive:
`>00a*0+a*0+a*0+a*6+a*3+-       00a*0+a*0+a*0+a*2+a*3++       x`

Original-source pin SHA256 for that exact 62-byte row slice:
`3e77526e07f663323ef4450860368929f3a2c114747f9a8bf766b9a67dbd5050`.
The row6 `x` opcode is physically at `(73,6)`. Independent
arithmetic stack analysis (no input stack values required) proves
the vector `(-63,23)`, hence next IP `(10,29)`,
**conditional on traversing the unchanged original corridor
without alternate ingress or self-modification**.

All 140 original signed physical EOF events execute exactly
**49 source opcodes from (12,5) through x(73,6)**, each verified
against the immutable original byte, exact executed IP,
pre-/post-stack and next→IP; the 50th original STEP is
`>(10,29)`. No original physically observed EOF event returns
to `~(13,5)`; no input byte gate ray (row8 10..185 or
row17 10..335) is visited after EOF. The compressed opcode
sequence from EOF to x is identical at all 140 events (SHA256
`488ac8fcdf4c0869cd3324e42bbe7eb1cf7d5a1861fdd782902031603f588354`).

### Memory and code-modification bounds

Among these 140 signed post-EOF tails there were **zero**
writes to B=(0,49), **zero** reads from B via `g`,
**zero** re-entries to `~(13,5)`, and zero visits to
the two input-gate source corridors. The last B writer at
the EOF step is physically `p(60,5)` from the previously
read last input byte. Last byte observations among the 140
EOF cases: ten occurrences each of digits ASCII 48..57
(100 events) and TAB/LF/CR/SPACE (40 events).

Across **all 200** original signed traces, there were zero
original physical `p` writes targeting the protected source
cells `(10..13,5)`, `(12..73,6)`,
`(10..185,8)`, or `(10..335,17)`. This **does not**
exclude source mutations or alternative IP ingress in other,
unobserved natural inputs.

## Independent adversarial evidence and artifact

The independent receipt-first validator shares no implementation
code with the forward scanner. It independently re-read all
200 original gzip traces, recomputed the 49-opcode EOF
stack states via a separate static source automaton, checked
source byte hashes, origin of pre-EOF x and memory owners,
and compared all 200 cases back to the forward per-event
evidence. Its synthetic hostile suite rejected **28/28
non-no-op corruptions** (including fake source bytes,
last-memory writer, reflected delta, predecessor x,
counter-witness claims, and false Stage1 PASS).

**Permanent QA31AU evidence ZIP, ChatGPT Library:**
`/Befunge_QA_Artifacts/QA31AU_BEFUNGE98_KYRGYZ_ORIGINAL_200_EOF_MEMORY_REENTRY_20261107.zip`

- ZIP SHA256: `08cb07c88b9fbc26b99d8efc2d80c911fe5278894c0e677bddfe665119ed6e58`.
- ZIP size 47,843 bytes; 11 members ZIP CRC 11/11 and
  SHA256 10/10 manifest-member verification.
- Contains both complete independent Python 3.10+ reader scripts,
  full original signed 200-case SHA receipts and 140 EOF
  source-path/stack evidence, per-case CSV, source byte pins,
  full logs, JSON summary and SHA manifest. The original
  ~46MB input ZIP is retained separately, not duplicated.
- The source scripts are reproducibility evidence and **are not**
  a new Windows user-execution package. No user computer
  activity is needed for this acceptance.

Local preflight initially used the wrong expected instruction
count (50 rather than 49 source opcodes between EOF and x);
the QA-only assertion was corrected and both final independent
full-corpus checks completed successfully. It was not a
production-source error.

**Acceptance:** QA31AU PASS only for finite original 200-case
signed receipt/EOF re-entry and exact **conditional source**
corridor proof. No new natural-input counter-target `p`
witness to q=(1,49) or m=(3,49). Stage1 global,
functional and geometric gates remain **OPEN**. No
production changes, main/merge, Stage2, or Native experiments.

## NEXT QA31AV

Use the 140 exact original signed EOF→(10,29) entries and the
two witnessed pre-EOF ingress `x` sites to analyze bounded
post-EOF `q/m` gate and writer provenance: source-pin row29
and row32 decision/stack operations and distinguish q/m
canonical writes from possible alternate `p` ingress.
Recheck original Native receipts for the post-EOF
counter memory owners and identify a **concrete**
independently proved new natural stdin candidate if one
exists; otherwise preserve UNKNOWN and do NOT invoke Native.
Any future independently grounded original Native case must
have <=25,000 STEPs. No main/merge/Stage2;
Stage1 global/functional/geometric OPEN.
