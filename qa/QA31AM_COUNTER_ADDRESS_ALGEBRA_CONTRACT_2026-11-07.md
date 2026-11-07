# QA31AM — original-source conditional counter-address algebra and two-p path

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Verified preceding HEAD: 535eaa8f27e849f57fcdb2477e390c415108b298
Original source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Previous original-source QA: QA31AL, exact-head run 42343966029.
Production source remains unchanged; no main/merge/Stage2/Native.

## Scope

Inspect all 32 formerly unresolved-y original source corridors from QA31AL, using
exact original source bytes and at most 60 cells between an explicit cardinal
direction arrow and a p opcode. All intervening opcodes must be deterministic
arithmetic/stack manipulation; model an arbitrary 8-cell preentry integer stack.
The prior source ray model showed at most 4 external stack pops; eight preseeded
values suffice to represent any non-underflowing incoming stack for this local
ray. Underflow/shorter stacks only reduce the set of values and cannot negate a
universal *exclusion* proved over arbitrary integers.

For a conditional pure ray with linear y = c + sum(a_i * u_i), the Diophantine
equation y=49 has a solution iff gcd(|a_i|) divides (49-c). For two source rays
with nonlinear y, give concrete independent integer-stack examples rather
than treating linear arithmetic as a sufficient proof. All put arguments follow
Funge-98 p's value, x, y stack order (pop y, then x, then value).

Expected partition of 32 QA31AL unknown-y sites:
- 22 linear affine expressions categorically exclude y=49 within the specified
  unchanged-source ray for every incoming integer stack.
- 8 linear affine expressions permit y=49 and have constructed incoming-stack
  witnesses also setting x=1 and x=3.
- 2 nonlinear expression sites (96,480) and (575,959) permit y=49 and have
  source-checked constructed incoming-stack witnesses setting x=1 and x=3.
- 10 distinct hypothetical source-ray sites, 20 conditional q/m target stack
  witnesses, but ZERO demonstrated natural inputs or physical reachability.

In addition, inspect the formerly no-simple-anchor p(369,575):
source at (385,575) heading west consists of "<p71a*6+a*9+a*2+p",
with p(384,575) before p(369,575). Under an unmodified-source straight
two-put path, the second p writes at x=7,y=1692, independent of incoming
stack. The first put may write to arbitrary coordinates and thus could modify
source; preserve global target UNKNOWN. Two benign first-put example stacks
must be checked independently. This addresses the local no-anchor corridor
without asserting global non-reachability.

For each counter-row at (10,20),(10,23),(10,29),(10,32), inspect the 12
nearest original-source cells in north/south/west directions to document a
bounded raw-byte predecessor neighborhood. Any physical IP arrival, modified
code or natural-input witness is UNKNOWN; do not infer execution from
adjacent blank source bytes.

## Quality gates and bounds

- Exact original Git source blob hash; do not accept a historical commit
  as HEAD without ref readback.
- Forward affine symbolic implementation plus numeric source-ray interpreter.
- An independent polynomial-monomial interpreter re-extracts the source rays
  and checks all 32 original coordinates and equations without importing the
  forward interpreter, including 22 modular exclusions and 20 target witnesses.
- Independently reconstruct both writes of the compound westward path.
- 15 synthetic tampered-report controls must be rejected by independent oracle.
- Assert NO Native runs, NO global Stage1 PASS, NO falsely claimed natural input.
- Exact code-commit CI must finish completed/success and persist forward/inverse
  JSON plus logs before finite QA31AM PASS. Failed CI requires targeted repair.
- No unbounded searches, arbitrary IP reachability theorem, or new Native probe.

## NEXT after finite QA31AM

QA31AN: investigate whether a *natural input* can establish any of the ten
constructible conditional incoming stacks and enter the corresponding source
rays, or can modify a source corridor. Start with existing signed original
Native trace evidence and a bounded backward source-predecessor and memory-
writer ownership contract; do not claim physical witness without a replayable
input, source SHA and signed execution log. A new Native run is justified only
when a concrete, independently checked input exists, <=25000 STEP per case.
If source-only predecessor analysis cannot establish reachability, preserve
UNKNOWN. Stage1 global/functional/geometric remains OPEN.
