# 完整日历生产集成：重新开放（2026-11-27）

PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
User explicitly reopened this branch for a production-ready bidirectional Gregorian/Pastafarian converter. The prior bounded Stage55/QA51-B acceptance and decision A remain historical, with true OS OOM/internal FREE-A/internal HEAP-LIVE NOT_TESTED. No Stage56, main, merge or release authorized. This is a distinct post-Stage55 integration track.

## Inventory at closure SHA a29604176bddcf22fd83820a98616a2f419dd7cc
Production: BigInt, frozen catalog, bootstrap dispatcher, legacy and patched day tag/distance/remainder. No five-field production API. The test-only normative oracle calls NORMATIVE-YEAR, gates, sauce/selection, families and weaving. It is not a production fallback. Input includes calculation day and target day; do not silently default calculation day. Canonical epoch and inverse semantics need authoritative specification before implementing civil-date interface.

## Integration checkpoint INT-01: work counts
New production module CALENDAR-WORK-COUNTS accepts two valid BigInt day owners (inputs may share a read-only value), four distinct canonical-empty result owners, direction byte, status. All output slots and input/output storage must be disjoint; inputs are valid ABI values, not arbitrary pointers. Status 175 rejects occupied output before touching it or direction; invalid sign returns 22. On normal success, outputs are caller-owned and input untouched. On ordinary operation failure cleanup is attempted, original failure retained; internal FREE-A failure and true OOM remain untested. No test-only source is linked into the production test executable.

For foundation F=-15055671, count(d)=2(F-d) for d<F, otherwise 2(d-F)+1; distance=abs(t-c)+1; connection=count(c)+count(t); direction 1/2/3 for t<c/t=c/t>c. Existing PATCHED-DAY-TAG and PATCHED-DISTANCE are reused, plus ADD and CMP. Independent scalar expected values derived directly from the normative formula, not from production; 15 pairs include foundation/equal/order/zero/sign/chunk/30-digit cases. Test checks four outputs, two unchanged input values, occupied output rejection, final heap zero for each pair. Native gate: strict GnuCOBOL compile, all 15 cases, exit 0 and marker, bounded 60s. Fixture generation is external QA only; runtime is COBOL only.

## Next gates
1. Accept INT-01 only after exact SHA native job/log/artifact. Add targeted occupied-slot/pointer ownership/ordinary failure coverage if needed.
2. Obtain authoritative Appendix A and civil-day epoch/inverse contract; map all normative subcomponents to independent production implementations with bounded complexity and caller-owned ABI. Implement gate/year, selection, family count/unrank, weaving and composition without production calling test oracle.
3. Define full five-field API and inverse validation, including calculation-day dependence, ambiguity/nonexistence and supported range. Implement Gregorian boundary and canonical naming; no silent truncation or approximation.
4. Full independent differential and round-trip tests; calendar 2026 sweep and signed extended-year random cases where contract permits, boundary/year/month/cutlet witnesses, resource bounded performance/soak, build and distribution documentation. Production readiness only after all applicable gates are accepted.

INT-01 is implemented, not Native accepted. No new claim about full calendar readiness. The three decision A exclusions remain.
