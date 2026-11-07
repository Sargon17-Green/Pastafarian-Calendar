# Native live Program fault isolation — Stage 1 QA

New finite failure-injection corpus: six real dual-Program executions of
unchanged Stage-1 QA production in the pinned PyFunge-98 interpreter.
Each pair contains two independent live Program objects with AB or BA
step scheduling. An artificial Python-side exception occurs immediately
AFTER the selected first/fifth/twentieth actual native Funge-space.put
in one Program, while its peer remains live.

The peer must survive and terminate with its exact seven-field answer
from independent native Befunge reference programs. On injection the
peer IP/stack/space-bound/IO state and all actual prior p-write targets
are required unchanged. Afterward, the faulty object's abandoned
Funge-space (every observed p-write target plus fixed guard cells) must
remain unchanged as the healthy peer runs to completion. The same faulty
Program object is explicitly reinitialized with new private Funge-space,
native semantics and I/O, then must reproduce its independent Befunge
reference output without mutating the abandoned space or I/O.

Both Program objects' execution-time Funge-space.get, .put and .putspace
are monitored for ownership: put only from active p, no runtime putspace,
and read only from the active private Funge-space. The wrappers are
restored on failure; a separate Python3 auditor verifies each of the
six report cases, exact source hash and native reference equality, and
rejects twelve forged reports.

This is an intentionally bounded failure-injection test. It does NOT
prove all exception families, undocumented mutation interfaces, arbitrary
concurrency, universal semantic ownership or final Stage 1 correctness.
Stage 2 and PR #17 merge remain forbidden; main and the canonical
Befunge+Кыргызча branch are untouched. Exact-head CI required for PASS.
