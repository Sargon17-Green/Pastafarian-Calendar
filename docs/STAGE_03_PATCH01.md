# Stage 3 / PATCH01 — విస్తృత ర్యాంక్ తిరస్కరణకు నేరుగా పరిష్కారం

## Gate and exact scope

Stage 2 DISCOVERY01's previously recorded CI run 41040439434 finished
3/3 jobs successfully at 3a569e95488f7cc8f95a804d91a2954d4fcd0f51,
including eight bounded synthetic properties. The original Stage 2
counterexample and its code history are preserved unchanged in
docs/STAGE_02_DISCOVERY01.md. Stage 3 changes only the existing **test-only**
Normative_Oracle.Choose_Rank_Wide; Monster_Bootstrap (production skeleton),
canonical name lock, and Stage 1 fixtures remain untouched.

## Mathematical equivalence for Ask_Bowl streams

Let Space=M**Places, 1<=Wide<=Space, and
L=floor(Space/N)*N. Rejection is exactly Wide>L.

* For Direction_Step=-1, the historical update is one step downward.
  Because L>=1, the first accepted value is exactly L, after Wide-L
  steps. Return (L-1) mod N + 1 (equal to N).
* For Direction_Step=+1, the historical update increments to Space,
  wraps to 1, then accepts (L>=1). The first accepted value is 1.
* For Wide<=L, no change occurs.

Ask_Bowl emits only ±1. A synthetic Direction_Step=0 remains valid as
a record value: when accepted it is unchanged, but when rejected it
historically loops forever. This patch replaces only that nonterminating
case with an explicit Constraint_Error. No accepted rank is altered.
The API distinction is documented rather than concealed.

## Evidence and limits

Stage 3 PATCH01 native runner: sh ./run_stage03_patch01.sh.
The suite exhaustively compares the original cyclic stepping to the
closed-form endpoint on 1,456 mini-model cases, compares two bounded
historical wide-oracle paths (one and two steps), exercises both
astronomical synthetic rejection directions, checks the M+1 boundary,
the stationary-stream accepted/rejected behavior, and runs two real
Sauce/Ask_Bowl streams against independent algebraic expectations.
The original 1,469-assertion suite passed GNAT Native on 2026-10-30 at
commit 1bc99774bdc118b19683dabd7a6052c767a808e5, run 41086786610
(4/4 jobs successful). This update adds two explicit three-position
radix-M rejection cases, one per direction. An independent BigInt
preflight confirmed that both synthetic candidates exceed their
acceptance limit for N=floor(M**3/2)+1. The new expected assertion count
is **1,471**, requiring a fresh native CI result for this new SHA. Compilation and all actual Ada
assertions must be confirmed by the stage03 native GitHub Actions job.
No intentional huge loop is executed.

This is not a completed Calendar_Date verification, nor proof that the
Stage 2 hostile synthetic stream is reachable from Ask_Bowl. Stage 3 acceptance remains pending until native, verify, and other
required jobs finish on the exact new branch HEAD. No main merge.
