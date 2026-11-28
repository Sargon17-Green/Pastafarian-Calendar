# Production §Q streaming contract
Authorized branch only; no numbered stage, merge, release or change to A/default.
Input calculation serial day c, foundation F, exact signed gap source §O,
maximumGapCalls in 1..400000 (default 400000). Each gap is in 42..963.
Strict left gate < c-5778, strict right gate > c+5777; retain nearest such
gates and all gates between. Interior span 11555 permits floor(11555/42)+1
interior gates plus two sentinels, hence at most 278 retained positions.
Each gap evaluated once; signed ordinal is nonzero. Total calls bounded,
failure before selection on budget or invalid gap. A preflight rejects
far unreachable targets even at maximal gap. Candidate ordering and
selection unchanged. Old bounded preview/sentinelSearch remain available
for historical regression and intentionally incomplete previews.
QA-only full-prefix oracle enumerates exact pairs with independent nested
loop; compare signed ordinals, positions, ordered eligible pairs, strict
sentinels, bounds, budget exhaustion, malformed gap and near/far cases.
Real §O differential checks Foundation and 2026-11-28; shared §O provider
means this verifies traversal, not independent §O arithmetic. Separate
20-minute CI job and 1000-second process timeout, exact SDK format/analyze,
marker and artifact required. No claim that modern dates meet production
latency or that §R/public API/inverse/distribution are complete.
