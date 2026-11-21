# Stage03-anchored reconstruction: intentionally wrong Rust day-tag (2026-11-21)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: reconstruction/rust-az-stage03-daytag-red-20261121
Historical root: 716e5a6f335b1a15464029b446edb468f3a8482c (accepted Stage03 closure).
Status: RECONSTRUCTION_NOT_HISTORICAL_ORIGINAL; Stage04 on original Rust branch remains OPEN/NOT_CLAIMED.

## Purpose
The spaghetti development sequence requires an actual Rust production mistake before its correction. The accepted Stage03 source never implemented a numeric day-tag in production; it returned BootstrapOnly for five calendar fields. We therefore fork the exact Stage03 source without rewriting it and add an intentionally erroneous native day-tag behind MonsterManager/MonsterDispatcher/MonsterContext.

## Newly created bug
For foundation F=-15055671, reconstruction legacy(day)=2*abs(day-F)+1 (unconditional +1). This is wrong when day<F. The correct independent integer specification is tag(day)=2*(F-day) if day<F, else 2*(day-F)+1. Hence:
- day=F-2: legacy=5; independent=4 (RED);
- day=F-1: legacy=3; independent=2 (RED);
- day=F: legacy=1; independent=1 (CONTROL);
- day=F+1: legacy=3; independent=3 (CONTROL);
- a 256-bit negative offset is RED, and a 256-bit positive offset is CONTROL.

## Contract
Input: signed, arbitrarily large BigInt day. Output: native Rust BigInt produced by the actual legacy route, with call-specific observation and log/metrics. Oracle: independently coded piecewise integer function in test only, with fixed small boundary examples. Native test must compile original Stage03 plus new production module and call it via MonsterDispatcher, compare six cases and assert 3 RED, 3 CONTROL, 0 unexpected; preserve Stage01-03 regressions. Rust format and Cargo tests must succeed, while the deliberate mathematical discrepancies are recorded as expected-red observations (not test crashes). A CI run must preserve GITHUB_SHA, toolchain, stdout/stderr, exit code, and artifact before any Native PASS is claimed.

## Evidence and limitations
This is a *new bug intentionally implemented in 2026*, not a previously existing historical Rust error. It is not admissible under the original Stage04 pre-introduction witness gate, whose original ancestor must not be retroactively forged. It creates an honest new developmental lineage in which the bug will exist before the corresponding future fix. No source or history is rewritten on Rust+Azərbaycan-dili, main, or a protected ref. No Stage04 or Stage05 acceptance is claimed.

Next: run real native Rust on this exact reconstruction SHA; if observed expected-red matches the independent oracle, make a separate subsequent correction commit and compare the two actual executed versions. Do not promote this reconstruction to original historical provenance.
