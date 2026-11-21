# QA31N — signed original three-gate expression provenance (2026-11-01)

Project PC-BRANCH-BEFUNGE98-KYRGYZ. Existing branch qa-befunge98-stage1-order-isolation-20261008. Stage1 OPEN; no main/merge/Stage2.

**Input:** original source Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c; exact previously executed QA31L Native artifact 13057227833, run 41238968158, outer SHA256 7de4556fda1b3d0b746c5b08e1600e029abb8d3a3565b976ddff804b9d4043b7. Only original b'0' (hex30), 2046 physical STEPs. No new Native.

**Oracle:** New Python3 model replays all post-read arithmetic STEPs for three original lanes, independently checking numeric stack pre/post, source-pinned last-write/read ownership via existing QA31M auditor, symbolic expression tree, and `j` successor. The limited opcodes are digits 0-9/a-f, +, -, *, greater-than (backtick), ! and j; no unsupported instruction can silently pass. Full-source check is delegated only to the separately accepted QA31M auditor; the arithmetic oracle is new.

| Original source row | last p | g tick / read | Expression | j tick / result / next |
|---|---|---|---|---|
|29|1082 at (248,14), writes (3,49)=1|1229 / 1|g(3,49) × 61|1254 / 61 / (151,29)|
|32|146, writes (1,49)=0|1349 / 0|(g(1,49)>3) × 61|1398 / 0 / (114,32)|
|38|1684 at (248,35), writes (1,49)=1|1779 / 1|!(g(1,49)−4) × 61|1829 / 0 / (115,38)|

Row38 original trace: tick1803 computes 1−4=−3; tick1804 computes !(-3)=0; tick1827 constructs 61; tick1828 produces 0×61=0. Three expressions cover 25+49+50 = 124 post-g signed physical steps. The QA31M x-lane crossing route (1301, 1445, 1731, 1876) remains a separately checked dependency.

**Acceptance:** exact original source blob/ZIP SHA/CRC, all 2046 physical STEP records checked by the previously accepted owner checker, 124 independently replayed arithmetic steps, three exact ASTs and signed next IPs, plus 13/13 targeted negative-control mutations of reads, opcodes, stack values and successor. CI outcome and artifact require independent readback. Do not label QA31N PASS before completed exact-SHA run and checked artifact.

**Limitations:** only one finite original Native trace; not proof of other input streams, source global reachability or complete full functional/geometric QA. Stage1 remains OPEN. After QA31N acceptance, investigate source row41 g sites without inventing a Native reachability witness.