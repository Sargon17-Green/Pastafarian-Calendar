# QA31T — bounded Native delimiter/EOF frontier matrix

Project: PC-BRANCH-BEFUNGE98-KYRGYZ  
Branch: qa-befunge98-stage1-order-isolation-20261008  
Parent HEAD: 990d53a2d8362229eccaeda101dfc588e4001398  
Source blob: 560d6aa5807a7f766213a33835cce85eab0fa40c

## Evidence driving this stage

QA31S completed successfully on its exact HEAD. Twelve original-source Native traces and 104,644 physical steps were independently audited; all 18 hostile controls were rejected. The finite matrix found one input with m(3,49)=1 and q(1,49)>=3: raw bytes b'1 0 0 0' without a line terminator. The same four-token input with LF did not produce that m value. None of the three tracked frontier IPs (286,5), (235,23), (235,32) was visited in QA31S. These are finite observations only.

## Hypothesis under test

The observed gate combination may depend on the exact whitespace bytes between the four tokens and on how the final token is terminated. QA31T tests this narrow delimiter/EOF neighborhood. It does not assume that any input should reach a frontier IP.

## Fixed input matrix

Exactly twelve byte strings, in this order:

1. The eight space/tab combinations for the three separators in `1 _ 0 _ 0 _ 0`, without a final line terminator. Bit 0/1 means space/tab respectively: `sep000_no_lf` through `sep111_no_lf`.
2. `space_lf`: `1 0 0 0\n`.
3. `space_crlf`: `1 0 0 0\r\n`.
4. `space_trailing_space`: `1 0 0 0 `.
5. `space_trailing_tab`: `1 0 0 0\t`.

No input is synthesized from observed values. No source bytes, instruction pointer, initial Funge-Space, or runtime semantics are modified.

## Bounds and independent oracle

- Exact original source Git blob pin above; original PyFunge 0.5-rc2 archive SHA256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac.
- Exactly 12 fresh original Native runs, each capped at 25,000 physical STEPs; total cap 300,000; process timeout 840 seconds.
- Record exact raw stdin hex/SHA256, all read/readline byte offsets and EOF reads, per-step IP/delta/op/stringmode/pre/post stack, p/g/j/x events, output, status, trace SHA256 and step count.
- Independent Python 3 auditor checks source Git blob and 2,015 splitlines rows, receipt/input/trace hashes, every tick and IP/delta transition, physical opcode against original source plus prior p writes, p and g stack semantics, stdin byte provenance/EOF, j/x observations, and physical visits to the three frontier IPs.
- Reject 18/18 forged receipt and in-memory trace controls.
- Report per-case m/q values and last writers, j operands, x edges, frontier hits, and whether m=1 with q>=3 was actually observed. A finite miss is not proof of unreachability.

## Acceptance boundary

Accept QA31T only on exact-HEAD completed/success, all 12 complete receipts, ZIP digest/CRC verification, all 12 full traces independently audited, and 18/18 hostile controls rejected. STEP_LIMIT/RUNTIME_ERROR remain explicit observations and do not count as a completed Native case.

QA31T is finite evidence only. Stage1 remains OPEN. No Stage2, main, merge, release, global reachability, input ownership, functional PASS, or geometric PASS.
