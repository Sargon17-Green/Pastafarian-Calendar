# Stage55 / PATCH27 — विणलेल्या महिन्यातील अचूक सदस्यत्व

Branch: TypeScript+मराठी. Parent Stage54/DISCOVERY27: 748024f131997405027c9847dc0bc430bf4e4a70.
Actions 41179302001 completed/success on parent SHA; both verify and TypeScript Native jobs succeeded.

## Measured motivation and scope
The Stage54 synthetic historical model treated every day between a month's first
and last occurrence as a member. On the *real* Year5000 full Stage53 Native
weaving, month 44 has 123 actual members, 4,989 internal holes, and its first
observed internal gap is day 239. The historical guess accepts that day but
the direct legal weaving does not. This is proof that the deliberately
introduced diagnostic model is inaccurate on real calendar data, **not**
proof that a previously deployed production feature contained this bug.

Define the derived correction for valid w[1..N], month m in 1..47 and day d:
  actualMember(w,m,d) = (w[d] == m).
The old span guess and full Stage54 result remain immutable. Reject forged
historical span bounds or membership fields. No sixth canonical date component,
no recomputation of the canonical date, no added Native predecessor query.

## Implementation and independent oracle
Patch27DirectMembershipChecker implements constant-time membership after input
validation; Patch27FullHandler invokes the entire Stage54 chain through a
separate owner and commits only its own trace and metrics after successful
predecessor completion. Preserve 58 shared writes per Native predecessor call.
The test-only oracle independently compares w[d-1] to m, including absent
months and holes; it does not invoke the production corrector. Historical
diagnostic must be a superset of direct membership, so any false rejection is
a contract failure.

Acceptance:
- 13-day interleaved witness: 39 queries, 8 old false accepts, 31 equal,
  zero false rejects.
- 256 deterministic 47-day shuffles x five queried months x 47 days:
  60,160 checks; all historical false accepts repaired; zero unexpected
  corrected mismatches. Independent member conservation.
- Real Year5000 full chain: query month 44, day 239, confirmed rejection
  against erroneous historical acceptance; 123 true members, 4,989 holes;
  preserve 61 Native calls, 3,538 shared writes, zero additional Native calls.
- Bounds, absent months, forged/stale historical data, deep Native fault
  rollback, retry, duplicate owner rejection and final calendar-date gate.
- npm run typecheck, npm test, verify Names Lock, TypeScript Native CI jobs
  completed/success on the exact new commit and log markers
  STAGE_55_PATCH_27_GUARDS_PASS and STAGE_55_PATCH_27_PROPERTIES_PASS.
  Stage54 native expected-red remains verified on the same tree.
- No main merge, no final-date enablement and no PASS until completed logs.
