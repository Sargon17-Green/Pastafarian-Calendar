# Stage13 / PATCH06 — bounded successor candidate
PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
BASE_SHA=02bcf3e0a5068ca5ef87e4b23a08e87d22f07e9b
USER_AUTHORIZATION=2026-11-28_STAGE13_PATCH06
STAGE12=ACCEPTED
STAGE13=NOT_ACCEPTED
NATIVE=NOT_RUN
DIFFERENTIAL=NOT_RUN

Contract: preserve DISCOVERY06 immutable historical route. For i=1..46 and b in {1,3,7}, require exactly i-1 visible values, each in 1..M, M=2^127-1. Let s=i-b. If s>0 return visible_prefix[s-1]; otherwise return H(1-s) from the PATCH05 accessor, whose physical backward index is 8-(1-s)=7+s. Validate shape (8 elements with zero sentinel) and range of all seven hidden values before reading. Preserve the prior legacy observation and reject missing/inconsistent predecessors or duplicate application before mutation. This is a bounded subroute, not the full calendar.

Candidate includes 13 signed/wide pairs, 598 synthetic prefixes, 1794 comparisons (143 corrected hidden cases, 1651 unchanged visible controls); same-branch independent integer arithmetic oracle replays raw outputs. Historical Stage12 and Stage10 strict RED remain separately required exit101 with named failure. Exact SHA, native formatting, tests, raw oracle, regressions and Names Lock required. Existing counters remain 12/12 pending successor-compatible validators/workflows and acceptance. No Stage14/main/merge/release.

Raw labels RED and CONTROL in the matrix count historical missing-slot cases and positive controls, respectively; RED count in this successor test is not a failing corrected comparison.
