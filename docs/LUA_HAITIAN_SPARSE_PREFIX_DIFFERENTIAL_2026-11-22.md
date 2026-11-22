# Independent sparse-prefix differential QA — 2026-11-22

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent source commit: f887035b733c94afe06037c303aa151e42b08189
Scope: QA only. No normative implementation changes, real weaving, full date, Stage56, merge/main, or release.

## Independent algorithm and oracle

The existing test/lua_haitian_sparse_path_qa.py enumerates opening/closing endpoint paths and extracts generating-function coefficients. The second implementation, test/lua_haitian_sparse_path_independent_qa.py, instead memoizes remaining multiset-word states (remaining multiplicities, next first occurrence, next last occurrence) and counts legal next-label transitions. The third oracle independently enumerates multiset words and tests strictly increasing first and last positions; the three must agree in their common bounded domain.

Contracts: integer multiplicities >=2; exact Python integer counts; prefix may be impossible, returning zero; lexicographic rank is one-based; no modulo/floating arithmetic. The independent DP has an explicit 250000-state resource limit, which does not imply normative invalidity.

## Executed local Python-only preflight

Command: python3 test/lua_haitian_sparse_path_independent_qa.py --standalone
Observed: 43/43 count, 290/290 prefix, 122/122 lex rank, 2/2 mutants (remove first-order or last-order acceptance gate), 5/5 negative/boundary checks.
Measured states for lengths=(3,)*m:
m4 L12=57; m6 L18=247; m8 L24=1013; m10 L30=4083.
Trivial 47-month (2 copies each, L94): 1176 DP states. This synthetic case is **not** the frozen normative 47-month/5294-day input. Timings are machine-dependent and printed into CI artifact.

## CI gate

.github/workflows/lua-haitian-sparse-prefix-qa.yml is a workflow_call scoped QA-only gate, invoked once by the existing canonical workflow on the Lua branch. It runs the original sparse polynomial script and the independent DP/differential test under time/resource caps; separate stdout/stderr/exit codes and exact source SHA are retained as an artifact even on failure. Until a completed exact-SHA run, this is authored code, not CI PASS.

## Limits and NEXT

Although a length-94 synthetic 47-month count is exact, no polynomial-time/general fixed-parameter reduction for actual m47/L5294 has been established. The existing memo method remains resource-unsupported for that witness. Do not invoke chooseRankWide, actual weaving or fullDate on approximate/rationed counts. Next: review exact-SHA CI log/artifact and pursue provably scalable exact conditional coefficient/counter before implementation.
