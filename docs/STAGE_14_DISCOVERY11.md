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
