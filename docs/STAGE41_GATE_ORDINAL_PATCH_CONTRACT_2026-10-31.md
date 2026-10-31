# Stage41 / PATCH20 — correct gate ordinal to one-based
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 23c02d413cb6bbd2eb194cddd7a3ee55ac220bcc
Gate: Stage40 run 41184002636 completed/success 69/69 jobs; lua_stage40_discovery job 124496234667 completed/success; Lua 5.3 native three PASS markers, stderr empty, exit 0, verified 15 exact + 14 interior expected RED, 96 signed 2^127 chains, 9 rejects, two independent replays. Evidence artifact 13037670304, SHA256 67a916fd4c6d1af9947e9f9265c4ce5de8739765e2fbb8b72d13175b16639379.
Status: OPEN; Stage41 Native NOT RUN / NOT VERIFIED.

## Contract
Inputs: same caller-provided strictly increasing signed gate records -8..8 from PATCH17/PATCH18; target day in half-open interval [Gate(k),Gate(k+1)) with k=-7..7; allowed gaps 42..963. Use authentic Stage38 strict-LT, Stage39 corrected LEQ and Stage40 historical zero-based ordinal, keeping all three previous semantic commits and states immutable. Append exactly one fourth semantic commit: ordinal = day-Gate(k)+1. At exact gate, result=1; at day=Gate(k)+1, result=2; at last day of interval, result=gap. Historical zero-based value remains separately observable and unchanged. No normative oracle in production; independently computed oracle in test. No year5000, postStir12, calendarDateSpaghetti, full calendar or main/merge.

## Measurable acceptance
- 15 canonical exact gate corrections (0 -> 1), 14 interior corrections (1 -> 2).
- 96 deterministic positive/negative 2^127 synthetic chains with valid 17 signed gates and gaps; 5 -> 6 ordinal repairs; independent one-based check.
- Nine malformed or out-of-range inputs must fail closed; two independent replay contexts with mutation isolation.
- Historical source Git blob locks for src/legacy_gate_index_lookup.lua, src/gate_index_patch.lua, src/legacy_gate_ordinal.lua, src/positive_gate_patch.lua and src/negative_gate_patch.lua; Lua5.3 syntax for src/test; exactly three PASS lines in test/stage41_tests.lua, exit=0, stderr empty.
- CI must complete, verify run head SHA, job total and lua_stage41_patch result; record separate source SHA/interpreter/stdout/stderr/exit/result artifact. Stage41 not PASS until completed evidence.
