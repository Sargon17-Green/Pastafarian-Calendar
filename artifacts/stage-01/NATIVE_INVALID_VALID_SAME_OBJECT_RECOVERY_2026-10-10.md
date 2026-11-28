# Native same-Program invalid-to-valid ownership recovery (Stage 1 QA)

Evidence scope: 42 real PyFunge-98 executions in exactly one and the same
Program object, with an explicit fully fresh initialization before each run:
all six invalid numeric and fifteen invalid lexical inputs from the existing
native rejected-input corpus, each followed immediately by one of three
valid inputs selected cyclically. The valid expected results come exclusively
from nine invocations of three independent test-only Native Befunge
references (one work_counts and two save runs per distinct valid case).

On every transition, native QA demands a new semantics object, new private
Funge-space, new I/O platform and fresh instruction pointer. The prior
completed Funge-space must remain unchanged before and after the next
run at EVERY actually observed p-write target, plus nine source geometry
anchors. Real engine Space.put destinations are observed at runtime, not
predicted from a Python reimplementation of the algorithm.

Separate Python3 audit confirms all 42 cases, native reference stability,
same object identity, old snapshot coverage accounting and eight forged
negative-report rejections.

The test is incremental and finite; it does not approve unsafe in-place
reuse of an unreset Program, prove every memory mutation API, complete
Stage 1 functional/geometric acceptance, authorize PR #17 merge, or
authorize Stage 2. All work is on QA branch only.

Exact-head GitHub Actions evidence is required before marking PASS.
