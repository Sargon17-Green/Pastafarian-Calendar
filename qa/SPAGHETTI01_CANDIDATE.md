# Stage 1 Spaghetti 01, Native revision 2 (QA only)

Source Git blob unchanged: 560d6aa5807a7f766213a33835cce85eab0fa40c
Candidate revision 2: 948cb9332332f6abf35274ecc4be69bbc8c79115
Rejected revision 1, retained: 0aa8220be14be54f2580bf3d6abb3b6ea73d32c2

Why revision 1 was rejected:
Native run 39022876561 showed exact output parity for seven inputs and
the independent reference oracle for valid inputs, but NO effect on final
outcome when g was suppressed or a literal was corrupted (0/5), although
suppressing p caused bounded noncompletion (3/5). The original two-channel
numeric-causality claim failed. Historical evidence remains unchanged.

Revision 2 uses the g-read value, minus ASCII48, *twice*: the original
numeric zero remains on the stack, while ':' duplicates this quantity and
'1x' consumes that duplicate as the horizontal velocity component with
vertical velocity 1. The legitimate read selects vector (0,1). A wrong g
read, missing g, or modified 48 producer produces a different vector and
must be caught by Native route/output/termination tests. The returning west
lane executes an opcode '0' written by p, producing the second original
numeric zero. Source changes: 21 explicit coordinates, source map unchanged.

Native revision 2 acceptance is PENDING and must satisfy both exact output
parity and three *causal* mutant tests. No production source promotion,
no Stage2, no Stage1 completion and no PR merge are permitted on this note.
