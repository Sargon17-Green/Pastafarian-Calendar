# QA20 — natural input-driven Native geometry coverage of 21 unobserved source glyphs

**Stage 1 remains OPEN; no natural-reachability result has yet been established.**

Motivation: QA18 classified 21 possible control glyphs with zero observed physical contact across 49 traced Native executions. QA19 proved conditional effects of three source x glyphs using deliberately forced IP relocation. QA19 does NOT prove ordinary reachability. QA20 corrects this by running **48 new input-driven Native BF98 Program instances without IP relocation or Funge-space mutation**.

Deterministic corpus: 27 legal sign/magnitude tuples varying zero, sign direction, Foundation neighbors and very large integer boundaries; 21 previously accepted invalid numeric/lexical patterns selected to exercise rejection gates. Four independent Native CI shards process 12 cases each. Every valid numerical result is checked using three freshly executed *independent Befunge-98 reference programs*; every malformed input must yield exactly seven -1 sentinels.

Each real Native program records every actual instruction pointer (tick, coordinate, direction, fetched opcode, string mode) in a compressed source-anchored execution trace. Each trace is SHA-256 pinned. The parallel Python 3 verifier independently decompresses and replays these raw records to recompute, for each of the 21 original QA18 source cells: physical execution hits and nearest observed Manhattan distance. A fifth job combines all 48 case receipts and rejects missing or duplicate cases.

The immutable QA production source Git blob is 560d6aa5807a7f766213a33835cce85eab0fa40c. QA18 prior independent roles file must match SHA-256 263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7. No Python implementation of calendar arithmetic and no cross-implementation oracle are permitted.

**Acceptance limits:** A hit supports natural reachability for that one input; a nonhit does NOT prove any candidate unreachable, dead, unnecessary or inert in every possible input. No production source, main, canonical Befunge+Кыргызча, signed older QA sources or Stage 2 modifications. All final Stage 1 gates remain open.

Status at creation: CI Native execution PENDING.
