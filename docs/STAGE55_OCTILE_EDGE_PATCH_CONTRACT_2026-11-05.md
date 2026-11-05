# Stage55 / PATCH27 — exact half-open octile-edge equality repair

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Source parent: c158f20f076974c419919b44fee17491e8737cb6
Gate: Stage54 CI run 41869837512 completed/success, 83/83 jobs. Native Lua 5.3 job 126738867846 success, 3 PASS lines, exit 0, empty stderr, all Lua files compiled. Artifact 13347087450 (six evidence files); reported SHA256 e18b8a57f706d16c07c31ae9a8feae3ed27682a04e2a963ec381efee0090f7a7.

## Input, output, defect and independently evaluated oracle

The input remains a signed BigInt day and exactly 17 strictly ascending {index,day} records indexed -8..8, with successive gaps 42..963. The requested day must be in [G(-7),G(7)). The output is the eighth-of-interval label E1..E8. Stage54 introduced a diagnostic-only, sticky-left legacy misclassification at exact internal eighth boundaries. Stage55 first executes Stage54 unchanged, authenticates its 17-commit trace, and adds an eighteenth semantic commit with a corrected label. Historical Stage54, Stage53 quartile, Stage52 quartile legacy and earlier snapshots remain owned and visible.

For a=opening gate, b=next gate, 0 <= u=d-a < v=b-a:
  right = E_(floor(8u/v)+1);
  legacy = E_(rightOrdinal - 1) only if u>0 and 8u mod v == 0, else right.

Production cannot divide huge integers, normalize, use float or invoke the normative test oracle: it repeatedly adds signed BigInts and assigns the first k in 1..7 satisfying 8u < k*v to E_k, else E8. The test independently converts only bounded u and v (<=963) to native integers and uses integer division and modulo. Never use the same classifier in tests and production.

## Acceptance

- 15 canonical opening E1 MATCH, 14 canonical closing E8 MATCH, historical diagnostics and 18 exact trace commits, no pending semantic transaction.
- 96 alternating-sign streams around +/-2^127, 17 gates, divisible-by-8 gaps 48..952: 7 exact internal boundaries each = **672 proven Stage54 mismatches repaired** by Stage55, plus 1344 matching flanks (one day either side).
- Nine invalid/out-of-range inputs rejected; two independent nonaliased replays; Stage54 legacy returns original wrong result on every equality witness; Stage53 corrected quartile and all earlier snapshots stay independently owned; no oracle import in production; lock 17 predecessor source modules by blob SHA.
- GitHub Native Lua 5.3 on exact branch HEAD: 84/84 jobs, including lua_stage55_patch, compile all src/test files via luac5.3, timeout <=1200 seconds, exactly three expected PASS stdout lines, empty stderr, exit=0, six-file evidence artifact with SHA256.
- Do not claim Stage55 PASS until run/job/log/artifact checked; no main/merge, publication, year5000, postStir12, sixth calendar field or calendarDate.

This is final planned Stage 55 of TOTAL_STAGES=55, but that count is not proof that the whole product is complete or publishable.
