# Stage14 / DISCOVERY11 — independent numerical five-field oracle (open)

## Verified predecessor
Stage13 PATCH02 on commit b0e363930f93edfd8aa42e21a5a5d9d5f4b3bae5 was accepted on GitHub Actions run 41222440545 (completed/success, 14/14 jobs including verify and native-stage13-discovery10). GNAT 13 compiled, bound and linked the test programs; the native log contains STAGE13_PATCH01_WEAVE_ASSERTIONS=2595 and STAGE13_DISCOVERY10_ASSERTIONS=25. This accepts the *revised* ticket-directed weaving contract, not equivalence to the abandoned multinomial map or cross-branch matching.

## Objective and explicit independence boundary
Stage14 aims to compare all five numeric outputs of public Ada Calendar_Date with an oracle computed independently from the same calendar inputs. No copying expected results from Calendar_Date, no importing fixtures or algorithms from other language branches, and no promotion of a synthetic projection to end-to-end acceptance.

## Implemented milestone A — compositional numerical oracle
tests/stage14_fivefield_oracle.py is a standalone Python 3 standard-library reference. It consumes explicit numeric structural witnesses (year, gate boundaries, cutlet labels, month lengths and labels, bounded tickets) and independently computes the five output fields. In particular, it uses expanded occurrence removal by index and binary search over gate endpoints rather than the Ada month accumulation implementation. The small 13-day model provides nine literal numeric five-tuples (45 scalar checks), while two 45-month/4230-day rail models provide three five-tuples (15 scalar checks); one out-of-range ticket is rejected, for 61 scoped checks. A successful Python result is **synthetic-only**, not a production differential.

## Required next work and acceptance contract
1. Implement an independent numerical reconstruction from *actual* calculation/target days: gate sequence, year selection, cutlet partition/name unranking, month lengths/names, and bounded ticket weaving, including the sealed streams. Derive all five expected scalars in this separate reference, without invoking Ada Calendar_Date and without copying another branch.
2. Choose at least three bounded target days: Foundation_Day-1, Foundation_Day, Foundation_Day+1, with Calculation_Day=Foundation_Day. For every date compare all five Ada fields exactly with independently calculated expected integers (minimum 15 scalar comparisons), plus repeat determinism and explicit domain checks. Keep duration bounded; add explicit hard timeout and fail-fast diagnostics.
3. Provide native GNAT 13 compile/bind/link and completed/success GitHub CI on a single verified Stage14 HEAD, both verify and native differential job, exact oracle marker and compare counts. If independent expected values cannot be computed, record NOT_RUN rather than manufacturing goldens.

Current status: DISCOVERY_OPEN; milestone A isolated synthetic oracle implemented; numerical full-calendar differential, native GNAT Stage14 and overall Stage14 PASS are NOT_RUN. No main merge or publication.


## Milestone B — real-day independent numerical reference and Native observer (awaiting CI)
The source-only independent reference is tests/stage14_real_oracle.py,
reconstructed from the explicit Ada branch specification and the SHA-verified
local draft. It uses Python big integers, enumerated six-bowl permutations,
table-based bounded compositions, list removal for weaving and direct numerical
counting of the five fields. It does not call Ada or read actual results when
generating expectations. Its numeric mixing rules must match the specification;
this is algorithmic cross-implementation testing, not a claim of formal proof.

A separate Ada observer calls Calendar_Date with Calculation_Day=Foundation_Day
and Target_Day=(Foundation_Day-1,Foundation_Day,Foundation_Day+1); outputs
three strictly parsed numeric records, checks five domains per target, one
year-5000 anchor, and five repeat comparisons: 21 native invariants. Python
then computes independently expected real-day five-tuples and checks all 15
scalar fields; any missing/duplicate target, missing marker or mismatch fails.
The reference selftest checks all 15 provisional regression scalars, repeats,
lexicographic small permutation unranking and small weaving multiplicities.
Known *provisional*, NON-native goldens from the independently executed draft:
- -15055672 -> (5000,10,502,6,58)
- -15055671 -> (5000,10,503,30,52)
- -15055670 -> (5000,14,1,22,33)

CI uses GNAT (Ada 2022), an explicit 600-second Native timeout and independent
60-second Python timeouts, with a 15-minute job bound. Require logs containing
STAGE14_NATIVE_DOMAIN_REPEAT_ASSERTIONS=21 and
STAGE14_REAL_FIVEFIELD_SCALARS=15, completed/success and verify on the **same**
HEAD before accepting Stage14. A Python-only selftest never substitutes for
Native. Past Stage13 acceptance and the separately verified synthetic 61/61
remain unchanged. No production source or main change.

## Acceptance addendum — 2026-11-01
Supersedes the preceding pending status. Run 41283018346 on 648e3e71720e39dabd3871bf5b6aa970ad210ca4
completed/success, 16/16 jobs including verify, synthetic and Stage14 real.
GNAT 13 compile/bind/link succeeded. Actual native log markers:
STAGE14_REAL_ORACLE_SELFTEST_ASSERTIONS=436,
STAGE14_NATIVE_DOMAIN_REPEAT_ASSERTIONS=21,
STAGE14_REAL_FIVEFIELD_SCALARS=15,
STAGE14_SYNTHETIC_FIVEFIELD_ASSERTIONS=61.
ACCEPTED for the explicitly bounded three-real-day scope, not all possible dates.
No main merge or other-branch equivalence is inferred.
