# QA31L — single-byte zero control-boundary probe (2026-10-31)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ  
Branch: qa-befunge98-stage1-order-isolation-20261008  
Immutable source blob: 560d6aa5807a7f766213a33835cce85eab0fa40c  
Stage 1 remains OPEN. QA31K CI is a separate pending bounded audit; its queued state is not a blocker or PASS.

## Evidence that selects this probe

The signed QA31G single-byte input b'1' reaches j(89,29) at STEP 1254 with operand 61 and successor (151,29). In the original source, (151,29) contains ASCII 0.

The signed two-byte inputs b'1 ' (space), b'1' followed by LF (hex 310a), and b'1' followed by TAB (hex 3109) reach the same source gate with operand 0 and successor (90,29). The source cell (150,29) is the distinct x opcode; (151,29) is the 0 digit.

Choose one new natural input: the single ASCII byte b'0' (hex 30), with EOF immediately after it. This holds the one-byte/EOF condition constant while changing only the digit from 1 to 0. A candidate hypothesis is operand 60 and successor (150,29), which would expose the x opcode. This is a hypothesis for measurement, not an expected result and not an expected-red claim.

The four unvisited g sites on source row 41 are a secondary frontier. Straight-line stack evaluation of that source row gives read addresses (10,49), (11,49), (12,49), (13,49) at IPs (57,41), (104,41), (151,41), (198,41). None is present in the five signed QA31G/QA31J traces. Do not add these as extra Native cases in QA31L.

## Measurable execution contract

**Input:** exactly one new raw stdin buffer, b'0' / hex 30 / SHA-256 5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9.

**Execution:** reuse the original QA31G PyFunge-98 observer from this same branch solely as the Native execution probe. Pin the original source blob above and the existing PyFunge 0.5 rc2 archive SHA-256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac. Maximum 7,000 physical STEPs; outer timeout 360 seconds. No source edit, IP relocation, injected memory, or changed interpreter behavior.

**Do not rerun:** QA31G empty, digit, digit_space; QA31J digit_lf, digit_tab.

**Required output:** one receipt, one compressed full-STEP JSONL trace, exact raw input SHA/hex, trace SHA-256, ZIP CRC, native status (HALT, STEP_LIMIT, or RUNTIME_ERROR), read events including EOF, all j gate operands/successors, all p/g events for (0,49), (1,49), (3,49), and whether (150,29) / (151,29) were actually executed. Preserve the observed terminal state; do not assume HALT.

## Independent oracle and negative controls

A new Python 3 auditor must be independent of the Python 2 Native observer. It must verify:

1. Git blob SHA-1 of the original source and source-cell bytes at (150,29) and (151,29).
2. Exact raw stdin bytes and SHA-256, compressed trace SHA-256, ZIP CRC, and case/receipt identity.
3. Every physical STEP tick, IP/delta continuity, source-or-overlay opcode, and exact input read slice.
4. Physical p/g stack semantics and last-writer values for the three target cells.
5. The j successor formula at every observed j, including (89,29) and (113,32) if reached.
6. Any observed x transition as recorded physical evidence; do not infer its semantics from its character alone.
7. At least eight hostile mutations rejected: wrong source pin, wrong raw byte, wrong raw digest, deleted STEP, altered p value, altered g result, forged j successor, zero IP delta, and fake Stage1 PASS.

If a newly reached opcode or execution mode lies outside the independent oracle, preserve the trace and mark oracle coverage incomplete with the exact boundary. Do not fabricate a defect or force an expected-red result.

## Acceptance boundary

A successful QA31L audit means only that this one bounded Native trace and its evidence were independently checked. It does not prove global source ownership, FULL_FUNCTIONAL_QA_PASS, GEOMETRIC_SPAGHETTI_QA_PASS, or Stage 1 acceptance. No Stage 2, main, merge, or publication. After evidence is complete, choose the next original-source frontier from the actual trace; if (150,29) is not reached, investigate the row-41 four-read frontier before selecting another input.
