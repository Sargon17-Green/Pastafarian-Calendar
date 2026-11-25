# Stage10 / DISCOVERY05 — backward hidden-drop storage expected-RED contract

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE=10
KIND=DISCOVERY05
CURRENT_PATCH=PATCH04
STAGE10_SCOPE=BACKWARD_HIDDEN_STORAGE_DISCOVERY
PREREQUISITE_STAGE09=ACCEPTED
STAGE10_ACCEPTED=NO
STAGE11=NOT_STARTED
PATCH05=NOT_STARTED
FULL_CALENDAR=BOOTSTRAP_ONLY
CONTRACT=FROZEN

## Cross-implementation contract sources

- V branch V+አማርኛ, commit 17febb8bd36edc85d92ac44d15583d243db9464e: docs/STAGE10_DISCOVERY05.md, pastafari/discovery05_expected_red_test.v, pastafari/discovery05_witness_test.v.
- Kotlin branch Kotlin+Cymraeg, commit 7e944531680950e31c4f402e5a55e7b73c930af4: docs/AUDIT_STAGE_10.md, src/main/kotlin/pastafari/LegacyHiddenDropAdapter.kt, src/test/kotlin/pastafari/Stage10Tests.kt, src/test/kotlin/pastafari/Stage10BigIntegerTests.kt, src/test/kotlin/pastafari/Stage10StrictRedTests.kt.

The branch-specific evidence is used as a mathematical/behavioral contract, not as a substitute for Rust implementation or Rust Native execution.

## Inputs and formula

DISCOVERY05 must use:
- corrected PATCH02 action and target day tags;
- corrected PATCH03 inclusive chronological distance, not the Stage06 legacy distance still retained in work_counts_observation;
- connection = action + target;
- direction = 1 when target < calculation, 2 when equal, 3 when target > calculation;
- the corrected 46-row PATCH04 snapshot stone table. Never use the Stage08 sequential legacy table as the hidden-drop stone input.

For logical hidden index k=1..7, coefficient rows are:
1: [3,4,6,8]
2: [5,7,10,12]
3: [7,10,14,16]
4: [9,13,18,20]
5: [11,16,22,24]
6: [13,19,26,28]
7: [15,22,30,32]

Let S_k=(w,b,s,m,r) be corrected PATCH04 stone row k. Compute:
x = SAVE(action + target*c0 + distance*c1 + connection*c2 + direction*c3 + w+b+s+m+r)
Then for grind g=1..7, using stone kinds [w,b,s,m,r,w,b]:
x = SAVE(x*x + 3*x + S_k[kind(g)] + g)
The production implementation uses arbitrary-precision BigInt and the real normative_save; the test oracle is independent.

## Historical physical storage defect — preserve it

The historical physical vector has length 8, with slot 0 as sentinel:
physical[0]=0
physical[8-k]=logical_hidden[k], for k=1..7.

Thus physical slots 1..7 contain hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1. The Stage10 accessor deliberately reads physical[k] directly for logical k, without reversing the index. Do not add PATCH05 or translate the index in this stage.

At foundation day F=-15,055,671, the independent logical values must be:
hidden1=119390830530032782664128530203002080344
hidden2=11877236279154673426874867061566696749
hidden3=24217814924229232987463457533828175476
hidden4=166629231917547214614573522551290204247
hidden5=81202913407267092008896220686064041568
hidden6=73551520026920072430116213847585486272
hidden7=6164285870955721082771365327359496898

For all seven logical indices, the direct physical read has six RED and one MATCH (k=4). Cross-implementation subsets must also be preserved: Kotlin's tested indices {1,2,4,6,7} produce 4 RED/1 MATCH; V's tested indices {1,2,3,4,7} produce 4 RED/1 MATCH.

## Production route and context

The actual route is:
PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04 -> PATCH04 -> DISCOVERY05.

DISCOVERY05 atomically stores:
- the corrected PATCH04 stone rows and its 45 legacy-mutator call count;
- the 8-slot backward physical hidden storage;
- hidden count 7, requested k, and the intentionally wrong direct-read value.

It records DISCOVERY05_BACKWARD_HIDDEN_DIRECT_ACCESS, increments discovery05.builds and discovery05.legacy.direct.read once, and rejects duplicate invocation, missing prerequisite observations, malformed storage, and k outside 1..=7 without mutating context. Separate invocations own separate storage. calendar_date_spaghetti remains BootstrapOnly.

## Required Native and independent checks

- Verify all seven physical positions and the sentinel, plus the exact foundation fixtures above.
- Five signed day-pairs, seven logical values each: 35 arbitrary-precision hidden values.
- Across those five invocations, verify 175 corrected PATCH04 stone components.
- Verify six RED/one MATCH over all seven positions, plus the Kotlin and V subsets.
- A separate strict GREEN assertion for k=1 must fail for the intended value mismatch. The main Native suite excludes that one deliberately failing test; the workflow runs it separately and accepts only the specific expected assertion failure.
- Rerun Stage05 through Stage09 regression oracles on the Stage10 exact SHA.
- Python oracle parses all 35 raw Native values and all 8 physical slots, independently recomputes all values and classifications, and rejects missing/duplicate/malformed lines.
- Artifact acceptance requires exact checkout SHA, completed/success run and job, artifact digest match, ZIP CRC, PROJECT_ID/SHA, exit 0, Native pass, strict RED confirmation, and raw-cell replay. Only then may LAST_COMPLETED_STAGE advance to 10.

Stage11/PATCH05, main, merge, release, and full calendar activation are not part of Stage10.
