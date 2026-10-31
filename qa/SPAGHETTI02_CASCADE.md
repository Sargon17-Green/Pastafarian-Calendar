# Spaghetti 02: two linked runtime-executable memory gates
Stage 1 QA-only candidate; **not promoted to production**.
Current exact-head requirement for the Native runner: real PyFunge-98, pinned archive.
Baseline QA candidate blob: 948cb9332332f6abf35274ecc4be69bbc8c79115
New QA candidate blob: 471e45cfec818d432cbb8e810204a865f8f04a97
Production blob remains: 560d6aa5807a7f766213a33835cce85eab0fa40c

The previous scanner inserted gate at (14,4) begins blank, is written with
ASCII 48 by a source 'p', is read by 'g' to determine the vector heading,
and later executes the freshly written opcode to push one zero.

The second cascade replaces **two further original source zeros** at (59,2)
and (60,2). At its start, it explicitly reads first-gate (14,4), uses its
numeric result as the opcode value written via a second 'p' into (63,4),
reads that second cell back with 'g', subtracts 48, uses ':' to retain the
zero, and uses '1x' to derive the downward IP vector. On row 4, the westbound
IP executes the freshly stored second zero opcode and rejoins east at x60.

The new source changes 29 physical source cells compared with the prior
QA candidate; map dimensions are unchanged. Both gate locations are SOURCE
BLANKS, to be populated during Native execution. The intended causal graph
is first p -> first g -> second p -> second g -> x -> execution of gate2.
Separate adverse Native mutants inhibit first p/g and second p/g, 4 families.
A bounded Python micro-replay passing is NOT a native acceptance.

Explicit limits: domain is finite, individual IP-g/p chronology across all
input families and fault/reentrancy ownership remain open. No final Stage1
functional or geometry acceptance, no Stage2, no PR merge.
