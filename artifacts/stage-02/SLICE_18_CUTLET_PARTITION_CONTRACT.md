# SQL+தமிழ் — Stage 2 Slice 18: cutlet partition selector contract

Date: 2026-11-01. Proposed contract is based on the exact same-branch normative function in sql/test/10_normative_reference.sql, lines 1317-1342, plus the just-accepted Slice 17 selector. This is a new *planned* slice, not an accepted implementation.

## Preconditions and scope
- Slice 17 accepted on commit c13209e05602b1706fd6ce97533d7b62d33e7df4, run 41350490055, 28/28 (20 Native, four production isolation, four differential) with six ZIP SHA-256+CRC and four generated SQL hashes verified; permanent Slice 17 report at artifacts/stage-02/POSTGRESQL_NATIVE_CUTLET_COUNT_41350490055.md.
- Output only an integer array partition of the number of gate gaps. Do not introduce or claim a sixth date component, cutlet names, months, or the final five-component calendar.
- Function signature: pastafari_sql_tamil.choose_cutlet_partition(p_calculation_day numeric, p_sauce pastafari_sql_tamil.sauce_result, p_year pastafari_sql_tamil.year_rec, p_k integer) RETURNS integer[].
- Production dependencies already in branch: choose_cutlet_count (Slice 17), exact_gate_index / gate_day (Slice 12), ask_bowl (Slice 9), choose_rank (Slice 10), year_rec (Slice 14), sauce_result (Slice 8). Production shall NOT reference pastafari_sql_tamil_test, dynamic SQL, mutable tables, caches, or a pre-computed partition.
- Function is STABLE STRICT due to exact_gate_index (STABLE), and read-only; never mark it IMMUTABLE when it calls STABLE dependencies.

## Normative exact input / output
Define g = close_gate_index - open_gate_index (integer, positive), k = p_k. Require integral input day and all five year fields; ordered day and gate boundaries, g >= 6, 6 <= k <= min(17,g), and k equals the accepted choose_cutlet_count(p_sauce,p_year) for production-valid paired inputs. The latter equality is a safe domain guard and is not a new normative random rule.

Let j = exact_gate_index(p_calculation_day). If and only if j is an exact gate strictly inside the chosen year's (open_gate_index, close_gate_index), require r = j-open_gate_index as an internal cutlet boundary (1 <= r < g). Otherwise no required boundary. An exact gate at either endpoint is not internal and imposes no constraint.

Define P(g,k,r) = all positive-integer arrays a of length k, sum(a)=g, ordered lexicographically ascending. When r is present, retain only arrays with an internal prefix sum exactly r. Let C=|P|. Require C>0 and exact integer count, even when it exceeds PostgreSQL int64. Obtain q = choose_rank(ask_bowl(p_sauce,2,21),C) (1 <= q <= C) and return element q of P (one-based).

Fail closed with SQL NULL on NULL arguments, nonintegral day/index/year fields, inverted or nonpositive year span, impossible g/k, invalid bowl/order, mismatched k, invalid child result, or unrepresentable integer-array elements; no partial arrays or silent truncation. Supported g must fit PostgreSQL integer for array lengths and bounded candidate enumeration; initial Native fixtures g=6..18 with explicit stress before enlarging the computational envelope. No intentional arbitrary 320-gate product cap is introduced without test evidence.

## Independent algorithm and oracle separation
- Production: use a dynamic-programming count of suffix completions indexed by remaining total, remaining slots, current cumulative sum, and whether the required boundary has already been reached. Counts are exact NUMERIC, not floating point. Unrank by iterating candidate positive first parts in ascending order and subtracting DP block sizes, until the one-based rank falls within a block; then recurse/iterate to construct the array. In production do NOT call the normative reference's binomial_exact, cutlet_partition_count or unrank_cutlet_partition functions and do not transplant their SQL.
- Independent QA oracle: enumerate combinations of k-1 separator positions among 1..g-1 in a separate Python fixture generator for bounded small g, convert separators to positive parts, filter by required prefix, sort tuples ascending, and derive expected counts and 1-based rank-to-array mappings. This combination-enumeration method is algorithmically distinct from production suffix-DP and the normative reference's combinatorial rank implementation.
- Differential: separately load the untouched same-branch normative schema in the comparison database. Convert sauce_result and year_rec explicitly field by field. For valid identical input day/year/k/sauce, compare full integer arrays (not only lengths/counts). Do not import test-schema functions into the production-only database.

## Small-case independently enumerated goldens
- g=6,k=6, no internal requirement: exactly one array [1,1,1,1,1,1].
- g=7,k=6, no requirement: six arrays; lexicographic first [1,1,1,1,1,2] and last [2,1,1,1,1,1].
- g=7,k=6, required internal prefix 2: five arrays (one of six compositions lacks the cut at 2).
- g=8,k=6, no requirement: 21 arrays; first [1,1,1,1,1,3], last [3,1,1,1,1,1].
- g=8,k=6, required internal prefix 3: 15 arrays.
- g=9,k=7, no requirement: 28 arrays; required internal prefix 3: 21 arrays.
These values were independently enumerated from separator combinations (not derived from production SQL). They do not specify the random rank unless the answer stream is also fixed and checked.

## Measurable acceptance gates for Slice 18
1. Source: production SQL plus one bounded standalone Python fixture generator, Native assertion SQL, separate differential SQL and dedicated PostgreSQL 17 workflow; commit/compare all exact blobs and branch identity before accepting.
2. Native: at least 32 individually named positive/negative assertions covering sum/length/positivity; lexicographic ranks at boundaries; no internal gate vs interior exact gate; both endpoints; negative/fractional days; invalid year fields, incompatible k and corrupt sauce; count total and 1/0 failing gate. Include independently generated small fixtures and [6..18] g envelope. Require actual Native execution, not static presence.
3. Production isolation: four or more checks for test-schema absence, signature/existence, STABLE/STRICT property, and no test-schema dependency in function body (plus no mutable state).
4. Differential: at least eight independently named comparisons of entire arrays (for g=6,7,8,9 and selected larger g), split across four finite matrix jobs, including interior exact-gate cases. Require actual=expected full arrays and output validity.
5. Dedicated CI: PostgreSQL 17 with distinct production-only and reference-loaded databases, exact source HEAD, deterministic fixture seed, bounded per-job time, immutable expected check counts, artifact ZIP+full SQL/versions and SHA256; verify each job completed/success and logs, independently hash each ZIP, CRC-test it, and independently match each generated SQL SHA256.
6. Gate: Slice 18 ACCEPTED only after all completed/log/ZIP evidence on an exact HEAD. No manual rerun of Slice 17 PASS, no main/merge/publication. If CI remains queued/in_progress, record run ID/HEAD and perform independent static QA; never classify that alone as a blocker or PASS.

## Implementation choice and NEXT
Use suffix-DP with lexicographic unranking rather than copying normative binomial recursion. First implement and locally validate the separate Python composition oracle for g=6..9; then SQL production under bounded assertions, dedicated Native/differential workflow, exact blob readback, and GitHub completed/log/ZIP acceptance. Opening this contract is not a claim of a Slice 18 runtime result or Stage 2-wide acceptance.
