# Stage 1 spaghetti 01: unpromoted QA candidate

Baseline source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Candidate source Git blob: 0aa8220be14be54f2580bf3d6abb3b6ea73d32c2

A locked 19-cell experimental change to the lexical scanner at x11-12,y2
replaces two source zero literals with two causally linked runtime values.
The first is computed via Funge-space p -> g -> subtraction, the second
via execution of an instruction written by p at (14,4) in the return lane.
The ^ -> > path restores the original eastward direction. The original
production src/interleaved_work_counts.b98 is unchanged.

Purely bounded local micro-replay across seven initial stack configurations,
with three targeted causal disruptions each, passed in normal and optimized
Python. No PyFunge Native execution or whole-program oracle result has yet
been verified for this candidate. Candidate MUST NOT be promoted on the
strength of that small interpreter; it may collide with other scanner paths.

CURRENT_STAGE=1; LAST_COMPLETED_STAGE=0;
GEOMETRIC_SPAGHETTI_QA_PASS=NO; STAGE2_STARTED=NO.
