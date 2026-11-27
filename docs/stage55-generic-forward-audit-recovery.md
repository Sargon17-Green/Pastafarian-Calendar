# Stage55 generic forward audit recovery candidate

QA only. Production and BigInt remain unchanged. The previously certified
forward insertion algorithm is reused via a generic, fixture-free request
interface. Inputs: positive lengths (1..123), 1..47 labels, sum <=5778;
operation count or unrank with canonical decimal 1-based rank. Output exact
decimal count and, for unrank, every symbol in lexicographic order. Worker
uses Python integers, 2 GiB address-space limit, 300 s alarm, atomic response,
nonzero exit on error. Adapter checks exit, exact count, length, multiplicities,
and both endpoint orders. No production fallback. Linux Python 3.11+ is
required for this heavy QA path; unsupported environments fail explicitly.

Preflight before heavy audit: direct recursion over 115 small families,
1335 states, 1697 edges, 1408 words; generic worker count and source-selected
4244-symbol case checked against certified digests; invalid rank rejected.
MATLAB adapter separately compares five small families against the retained
original direct recursion. Existing Stage54/55 assertions unchanged.
Requests, responses, stdout and audit diary uploaded even after ordinary failure.
Runner termination may still prevent artifact upload; do not infer a result.
No PASS until exact-SHA job/log/artifact acceptance.

Actual public converter soak remains distinct: 4244 interior targets in
each of two fresh MATLAB sessions, adjacent-year boundary targets and
repeat queries. Production currently rebuilds its year-chain on each
public call; measure real warm-call cost before choosing soak job budget.
