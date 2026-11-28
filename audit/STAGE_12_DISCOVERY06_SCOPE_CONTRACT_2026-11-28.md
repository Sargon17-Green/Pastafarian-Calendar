# Stage12 / DISCOVERY06 — visible-only predecessor, bounded candidate
PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
BASE_SHA=f77d963d3abd2ceed8c9f7a964841f8c1d89b252
USER_AUTHORIZATION=2026-11-28_STAGE12_ONLY
STAGE12_SCOPE=VISIBLE_ONLY_PREDECESSOR_DISCOVERY
STAGE12_IMPLEMENTATION=CANDIDATE_NOT_EXECUTED
STAGE12_NATIVE=NOT_RUN
STAGE12_ACCEPTANCE=NOT_CLAIMED

## Provenance
Stage11 accepted 11/11 on BASE_SHA per register, exact branch HEAD reverified. The original standalone 55-stage instruction was not located. Scope corroborated independently by V history at bdbb4ccbd320176ef538a64a0ce22718c79cc65c and JavaScript history at 6b276f4fffe3b3baf1f98023e295241ca90da6be (SPAGHETTI_DEVELOPMENT_HISTORY.md, semantic sequence only); normative README main blob 74c424b44eadd4ece3f29072ddbf873236557604 sections F/G. No foreign implementation code, tests, fixtures, expected outputs or oracle copied. Existing same-branch Stage10 test oracle remains independent of production.

## Contract
i in 1..46, back in {1,3,7}, prefix of exactly i-1 already completed visible values in 1..M, M=2^127-1. Discrete signed BigInt c,t. Historical lookup slot=i-back; positive slot returns prefix[slot-1], nonpositive slot returns typed MissingVisibleSlot, never hidden data. Normative expected for -6..0 is H(1-slot) from F/G. Runtime guard prevents invalid indexing, not a correction. Do not manufacture actual visible-drop values: candidate receives explicit prefix; test prefixes are synthetic controls for indexing only, not normative dough or visible-drop generation. No full calendar activation, no Stage13 PATCH06.

Candidate real dispatcher route preserves Stage02–11 observations, appends legacy handler after PATCH05. Reject invalid i, back, prefix shape/range, missing prerequisite, duplicate before observation mutation. Historical missing slot is a recorded typed semantic outcome, not a successful normative value. No fake panics. Matrix 46*3=138 cases per signed pair: 11 missing (1+3+7), 127 positive controls. Foundation matrix is authored; fresh signed/reversed/wide pairs, independent raw-output arithmetic replay, exact coverage and additional guard cases are required before acceptance. Separate ignored strict normative equality test at i=1,back=1 must fail for the stated reason with actual MissingVisibleSlot and independently computed positive H1; require exit101, not merely generic failure. Existing Stage10 strict RED preserved.

## Gates and next
This is a pre-transition candidate: DEVELOPMENT_STAGE.md remains 11/11 with historical hold marker until successor-compatible state validators/workflows are authored and reviewed. This avoids claiming acceptance or triggering known-incompatible 12/11 gates. User has authorized Stage12; no additional permission required for routine work. Existing automatic push CI may compile/test candidate but is not Stage12 acceptance. Next: native formatting, own bounded Stage12 workflow, independent raw oracle for full matrix incl signed/wide pairs, separate strict RED (and retained Stage10 RED), Stage04–11 and Names Lock regressions, exact SHA/log/artifact bytes/hash/CRC. Advance state only with successor gate compatibility; LAST_COMPLETED_STAGE stays 11 until full acceptance. No Stage13/main/merge/release.
