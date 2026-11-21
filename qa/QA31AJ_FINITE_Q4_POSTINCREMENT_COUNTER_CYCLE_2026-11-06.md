# QA31AJ — bounded source-pinned postincrement q=4 cycle (2026-11-06)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ / Befunge-98 + Кыргызча.
Branch: qa-befunge98-stage1-order-isolation-20261008.
Verified pre-change HEAD: 06fc1804bc6dbdf1a631768e52ba5f5c2b5ce9fa.
Frozen production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c.

## Scope and result hypothesis
At source row23 with q=3 the canonical route enters row26. At p(248,26) it
sets q=4, at p(344,26) it resets m=0, and then goes to row5. In addition,
row35 can increment q from 3 to 4 but exits to row38, not row32.

The exact-source forward Python walker and an independently written inverse
opcode-predicate oracle check all 256 nonnegative byte values at the next
canonical row5 entry, each using <=549 STEP per row segment. The independent
inverse predicates are row8 digit membership, row11 q>3 termination, row17
whitespace membership, and row20 m=0 return-to-row5.

Expected local partition: 10 digits via row11 to row44; 4 whitespace values
via row17/row20 back to row5; 242 other values via row17 to row44. No modeled
case enters row23/32 with q=4,m=0. For four whitespace cases that cycle,
q=4,m=0 is preserved for the next such canonical segment. This is a
local source-only finite result, NOT a global source reachability proof.

## Acceptance contract
Original Git source hash verified, 16 forward and nine independent site pins,
256/256 exhaustive byte cases, row26 p(248,26), p(344,26) writers,
row35 postincrement boundary, eight forward source/premise controls,
12/12 independent mutated-report rejections, complete output JSON,
and completed exact-SHA GitHub Actions CI are required to accept finite
QA31AJ. Creation of a commit does not imply CI passed.

No historical Native corpus is replayed and no new Native executed.
Self-modification, alternative row20/23/29/32 ingress, noncanonical
IP/stack entry, and other unbounded original paths are UNKNOWN.
The Stage1 global/functional/geometric gates remain OPEN; no main/merge/Stage2.

NEXT: source-pinned inventory of alternative predecessor edges and other
original-source writers to q=(1,49), m=(3,49), with an independently
witnessed natural-input candidate before any new Native probe (max
25000 STEP per case). Investigate the exact failing assertion if CI fails.
