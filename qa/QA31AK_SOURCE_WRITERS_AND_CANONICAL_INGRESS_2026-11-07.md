# QA31AK — source-pinned original ingress and q/m writer inventory (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Existing branch: qa-befunge98-stage1-order-isolation-20261008
Verified pre-change HEAD: b465e1b8131ce4cb3aa40fe01b6ef16cb4ba3efb
Frozen original production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Prior accepted finite QA: QA31AJ, exact-head CI 42297366147.
No production code is changed, no main/merge, no Stage2.

## Scope and reasons

The original source has 57 literal p opcode glyphs: 13 in the
control prologue rows 0..44 and 44 outside. The 44 outer glyphs are
reported with their exact source coordinates; they are NOT claimed
non-executable, nor is their memory destination inferred from
bare glyph positions.

The forward verifier uses the complete SHA-pinned original source
and a bounded implementation of only the visited row-local opcodes.
Each row is entered at (10,row) with fresh empty stack, an explicit
q=(1,49), m=(3,49) premise and modeled nonnegative stdin-byte return.
Every modeled row must leave with empty stack and a strictly verified
destination (x,y); no claim is made about arbitrary IP or preexisting
stack entries. No new Native run or prior Native replay is performed.

Conditional row-entry coverage:
- For row5, row8, row17: all byte values 0..255, 768 cases.
- For rows11,14,20,23,26,29,32,35,38: seven q states (0..6)
  and two m states (0/1), 126 cases.
- One original row2 initialization segment.
Total 895 independently inverted source-condition cases.
The exact original source p-site to memory-coordinate pairs are checked.
Conditional q writers: p(106,2), p(248,26), p(248,35).
Conditional m writers: p(202,2), p(248,14), p(344,26).
Other writes in the prologue may affect other cells. Outside prologue
writer targets and alternative stack/IP ingress remain UNKNOWN.

Within those normalized row-entry probes, incoming transitions to
row20 originate at row17, to row23 at row20, and to row32 at row29.
No modeled nonnegative-byte row entry reaches row29. These are
conditional edges, NOT a global predecessor graph.

## Independent state-closure experiment

A separate bounded experiment follows original-source row5-entry
cycles under all 256 possible nonnegative byte return values.
Starting from q=0,m=0, q/m state discovery uses three representative
input classes (ASCII digit, TAB/LF/CR/space, other), then verifies
every class's equivalence independently for all 256 values at every
discovered canonical state, 9 states x 256 = 2304 source walks.

Expected reachable state set:
(0,0), (0,1), (1,0), (1,1), (2,0), (2,1),
(3,0), (3,1), (4,0).
No (4,1) state is reachable *within this assumed canonical
state-transition system*. The result is a finite-state inductive
claim conditioned on original source, canonical empty-stack vector
entry, modeled nonnegative input byte returns, and no noncanonical
self-modification/IP entry. It is not an unqualified property of
the complete original Funge-98 program.

An independent reverse oracle imports no forward source code. It
checks separate opcode coordinates, independently computes each
conditioned row exit, exact target writer coordinates/values,
the 895 conditional records and all 2304 state-byte paths and
q/m transitions. It separately reconstructs the nine-state closure.
Seven altered source-site controls are caught forward; 16 altered
report variants are rejected independently. All 16 are synthetic,
not original Native perturbations.

## Acceptance contract

Required before finite QA31AK acceptance:
1. GitHub checkout of exactly the submitted branch SHA, source Git
   blob check equal to 560d6aa5807a7f766213a33835cce85eab0fa40c.
2. Both Python 3.10+ standard-library scripts compile and execute.
3. All raw source p glyphs enumerated (57/13/44); 44 outer coordinates
   preserved and designated UNKNOWN for memory targets.
4. All 895 conditional source probes and 2304 full state-byte cases
   audited against independent inverse/source site checks.
5. Nine-state conditional closure only, exact q/m owner-site sets,
   explicit conditional predecessor list for rows20/23/29/32.
6. Forward 7/7 source mutations caught and independent 16/16 hostile
   report mutations rejected. No source opcode or structural mismatch.
7. Completed exact-commit CI/job logs and uploaded JSON evidence.
   A committed workflow or locally built code alone is not PASS.

Do not promote finite conditional non-reachability into global
unreachability or claim functional/geometric Stage1 acceptance.
No natural stdin candidate for q>3,m=1 has been established.
No new Native run is justified absent a concrete source-derived
candidate, independent checks and <=25000-STEP/case bounds.

## Engineering follow-up

NEXT QA31AL: investigate whether any of the 44 outer p glyphs or
noncanonical IP/vector/stack predecessors can physically influence
q=(1,49) or m=(3,49), with a bounded origin/target ownership check.
Do NOT infer physical execution from a glyph, and do not manufacture
a historical expected-red. If source-only filtering cannot resolve
these outside-region writers, keep their dynamic targets UNKNOWN
and design a bounded signed original-Native trace comparison from
existing accepted evidence before new Native execution.
Global functional/geometric Stage1 remains OPEN.
