# Stage12 DISCOVERY06 — evidence and successor-state audit
PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
HISTORICAL_EVIDENCE_SHA=706aff42918c0654864d229e494a5365cf5c6c92
SUCCESSOR_GATE_SHA=5fe050e3290e664b0649b95d1cb382445142d92e
STAGE11_CLOSURE=ACCEPTED
STAGE12_CLOSURE=ACCEPTED
CURRENT_STATE=DISCOVERY06_STAGE12_ACCEPTED_HOLD_NO_STAGE13
NO_STAGE13=YES
NO_MAIN_MERGE_RELEASE=YES

## Historical evidence SHA 706aff42918c0654864d229e494a5365cf5c6c92

All 13 automatic push workflow runs on this exact SHA are completed/success; all 13 jobs are completed/success and all 13 decoded job logs were inspected. The four logs noted in the earlier audit were rechecked, and the other nine were inspected in this pass. Two workflows intentionally have no artifact: Canonical Names Lock and Stage01 Native. The remaining 11 artifacts were downloaded and independently checked.

| Stage/workflow | Run ID | Job ID | Artifact ID | Bytes | ZIP SHA-256 |
|---|---:|---:|---:|---:|---|
| Stage02 | 46132354465 | 140940080568 | 15258621342 | 75415 | efa9a512113fc85488c13a035f6dffd679d8d604d8114892a825cfc5072ce60f |
| Stage03 | 46132354480 | 140940080624 | 15257558532 | 75480 | bb98430e330b41f58f189fba1998640db77ba0bcec84d4ab3b363bbf8fdc158f |
| Stage04 | 46132354571 | 140940080716 | 15257644783 | 91368 | 225a7dfaad5a03be0836ab2dd231f5197461d9e524d21ef002ef6f7a0db24f0f |
| Stage05 | 46132354456 | 140940080549 | 15257742744 | 75445 | a960c62982fdefe947c98db6454a948710d4b91a4e74339a4252f553b5da2173 |
| Stage06 | 46132354576 | 140940080825 | 15258378035 | 75910 | a4b7870367150adfdba69c68b58f14cdbb2f66976732c369f094d65476f16edc |
| Stage07 | 46132354454 | 140940080409 | 15258313260 | 75850 | 327f5162702ff4ee9b63e5dd316301f36dc704fbb8eabaa1c5ca64b238f17913 |
| Stage08 | 46132354461 | 140940080296 | 15258438136 | 76334 | 855bc3866174be062a6772134a3132a58b7cf7aa7026129cab87471b5be17b7c |
| Stage09 | 46132354475 | 140940080469 | 15257857534 | 76554 | 817e9ad9118beb1344b3ef6b15948008e6fb7aa5163e43995a2f0b6bdd77f303 |
| Stage10 | 46132354453 | 140940080348 | 15258586689 | 77549 | aeaf86abbeef3e257d4a2dbbb2d5ce1e6283493ac66efd0ac991edecc3ffa2b9 |
| Stage11 | 46132354468 | 140940080560 | 15258686097 | 77903 | a07ffcfcdd7fdc19773b7127e0a1cf0656116f6fb3ce741a817e92037ea19fa9 |
| Stage12 | 46132354660 | 140940081146 | 15257528538 | 21946 | 7e276544eec422688f9ed3f42c0332bcd355df1219c08c4cf00b2fe53038980c |

Every downloaded historical ZIP matched its upload-log SHA-256 and byte count; every CRC check passed. All 11 contain the exact PROJECT_ID and historical SHA in sha.txt and exit.txt=0. The Stage04 whole-stage verifier artifact on this historical SHA reports 17 tests, OK.

## Independent Stage12 raw replay

The historical Stage12 ZIP and the successor-HEAD Stage12 ZIP were each replayed independently. Parsing deliberately searches within each line because the first STAGE12_INPUT record is prefixed by Cargo's test-harness text; a start-of-line-only parser is incorrect.

The independent replay re-derived SAVE modulo 2^127-1, signed day tags, stone rows, and the seven hidden values; it did not use the log's expected field as its oracle. It verified every input, prefix, slot, actual value, expected value, and pair total.

STAGE12_RAW_REPLAY=PASS
INPUT_PAIRS=13
PREFIX_ROWS=598
RAW_ROWS=1794
RED=143
CONTROL=1651
PER_PAIR=11_RED_127_CONTROL
HISTORICAL_AND_SUCCESSOR_HEAD_REPLAYS_MATCH=YES

Both Stage12 archives report the normal test group as 3 passed, 0 failed, 1 ignored; the ignored strict witness was run separately. Stage12 strict RED exits 101 and fails specifically because the observation is MissingVisibleSlot while the independently computed normative value is Visible(H1). Stage10 strict RED also exits 101 for its preserved named assertion. These are expected RED witnesses, not Native failures. Stage12 closure remains NOT_CLAIMED at this point.

## Successor-gate HEAD 5fe050e3290e664b0649b95d1cb382445142d92e

All 10 automatic push runs on this exact branch HEAD are completed/success; all 10 jobs are completed/success and their decoded logs were inspected. Canonical Names Lock has no artifact. The other nine artifacts were downloaded and independently checked.

| Stage/workflow | Run ID | Job ID | Artifact ID | Bytes | ZIP SHA-256 |
|---|---:|---:|---:|---:|---|
| Stage04 | 46142297944 | 140970697590 | 15262665483 | 91392 | 5a2216dd49938db7a5662c6a177f51a1e8a4f8947cb9603bef9a1a56494e89b4 |
| Stage05 | 46142298130 | 140970698003 | 15261932977 | 75448 | e7bdbd596201687260d45818e29477529f24a5f9b6195f68299775db1c6691df |
| Stage06 | 46142297984 | 140970697695 | 15262092289 | 75909 | cc4a3b85698ec60408daf3beddbbd901a0acb0ff53cdcc3df77cafa47fe81b01 |
| Stage07 | 46142297951 | 140970697557 | 15262685527 | 75879 | b39cc23a0742b8eb2514ff0206a1b3c7e8bc2a5c3ffc1554fdd9c75095218360 |
| Stage08 | 46142297948 | 140970697639 | 15262142059 | 76393 | ac8c11772766db5f2f9aa5693b5a2c7e8c43f973beb3e63ef94580433b480daf |
| Stage09 | 46142297950 | 140970697626 | 15261913578 | 76627 | 52b434673fed0ecd2bf50a84e5c2405ad42588fa7ba100b619659375dbac7325 |
| Stage10 | 46142298053 | 140970697886 | 15262436567 | 77549 | 10d50d574b541f75ac3bf9191a35fc73c3f81a2c358d22a7abea7c61152b89ed |
| Stage11 | 46142297945 | 140970697742 | 15261962705 | 77924 | c8220b99f7db9364ae28f3f6ec11d6ddeff375ad9fd1d90c7359f93435f248b2 |
| Stage12 | 46142298020 | 140970697707 | 15262142053 | 21946 | 444c3a5716f23313d247911745ae6bc0ca66d7e8fdc83164bd743687dedcbb03 |

Every downloaded successor ZIP matched its upload-log SHA-256 and byte count; every CRC check passed. All nine contain the exact PROJECT_ID and successor SHA in sha.txt and exit.txt=0. The Stage12 raw replay and both strict-RED checks were repeated on this HEAD and matched the historical results.

Stage04's successor-gate self-test reports 20 tests, OK, including explicit Stage12 pending support, Stage12 accepted-hold support, and fail-closed rejection of inconsistent Stage12 tuples. The prior Stage04 self-test count was 17. The nine Stage04–12 workflows now encode the exact 12/11 pending and 12/12 accepted-hold-no-Stage13 states; the Stage04 verifier independently tests these tuples.

## Transition and next gate

The evidence audit is complete. DEVELOPMENT_STAGE.md now enters:
CURRENT_STAGE=12
CURRENT_KIND=DISCOVERY06
CURRENT_PATCH=PATCH05
LAST_COMPLETED_STAGE=11
EXPECTED_REPOSITORY_STATE=DISCOVERY06_STAGE12_PENDING_NATIVE

This is only the 12/11 pending-native state, not Stage12 acceptance. Next: validate the new commit's exact-SHA completed CI runs and their logs/artifacts. Only after those gates pass may the state advance to 12/12 with DISCOVERY06_STAGE12_ACCEPTED_HOLD_NO_STAGE13. No Stage13, main merge, protected-branch change, or release is authorized.


## 12/11 pending-native CI result and Stage12 acceptance

PENDING_NATIVE_SHA=103e9a4a23c8f78a7e9543abf82f34357449be07
PENDING_NATIVE_RUNS=10/10_COMPLETED_SUCCESS
PENDING_NATIVE_JOBS=10/10_COMPLETED_SUCCESS
PENDING_NATIVE_ARTIFACTS=9/9_VERIFIED
STAGE12_CLOSURE=ACCEPTED
STAGE12_ACCEPTANCE_BASIS=Native+independent raw differential+expected strict RED witness+all Stage04-11 regressions+successor state gates

All ten automatic runs on the exact 103e9a4a23c8f78a7e9543abf82f34357449be07 HEAD completed successfully, run_attempt=1. All nine Stage04–12 jobs passed the exact checkout check; Canonical Names Lock completed successfully and intentionally has no artifact.

| Workflow | Run ID | Job ID | Artifact ID | Bytes | ZIP SHA-256 |
|---|---:|---:|---:|---:|---|
| Stage04 | 46147847673 | 140987706088 | 15264243698 | 91347 | e16fc162f4c2a0670f247a81095cdb368578c27d6904e16dab48d1eaa4f78cc9 |
| Stage05 | 46147847724 | 140987706140 | 15264013062 | 75449 | d3664f088489d3877768266673be63783050c8775d5c28edf9bc12ccb66bb7be |
| Stage06 | 46147847619 | 140987705757 | 15263733698 | 75907 | e6f20834208291ddc96c010a59ce7e278d4f3ed1bfe075d06cbf886ea945fb47 |
| Stage07 | 46147847615 | 140987705883 | 15264596771 | 75888 | 354f94538a6820344d64568d771d8c2cfc7169e65ee12e98a3c60495b30abd90 |
| Stage08 | 46147847622 | 140987705773 | 15264641617 | 76353 | 6a476599c6407c0834d597671b8a689aacd01d44b7f75cfb79dcbf4ad3512605 |
| Stage09 | 46147847669 | 140987706100 | 15264661558 | 76544 | 72bf14cf56776e30a97df436181722264b3813ee66cea59bb97972a8453ef45c |
| Stage10 | 46147847632 | 140987706859 | 15264078095 | 77514 | 3b05d1e52088787c13407d8ab962a8ab432519d2da84948992b42e3feaee6cd4 |
| Stage11 | 46147847612 | 140987705814 | 15264078086 | 77902 | e65620a72aa50996ef1e5a11bb34e08bb228fbf73450e03cb54263d0185e0b2f |
| Stage12 | 46147847607 | 140987705829 | 15264038045 | 21945 | c2c8bb8a76aea985941706f00318198e9a74fe5d37dde8576f4e9014c235d611 |

Every downloaded ZIP matched the upload-log size and SHA-256, passed CRC validation, contained the exact PROJECT_ID and pending-native SHA, and recorded exit.txt=0. Stage04 whole-stage verifier: 20/20 tests, OK. Stage12: normal Native test group 3 passed/0 failed/1 ignored; independent oracle PASS for 13 inputs, 598 prefixes, 1794 rows (143 RED/1651 CONTROL); isolated Stage12 strict RED exit 101 with MissingVisibleSlot versus independently computed Visible(H1); preserved Stage10 strict RED exit 101. Stage12 raw ZIP independently replayed again on this exact pending-native SHA with harness-prefix-aware parsing; all observations and pair totals match. All Stage04–11 regressions and their independent oracles passed.

Across the three audited SHAs (706aff historical, 5fe050e successor-gate candidate, 103e9a4 pending-native): 33 automatic runs completed/success, 29 ZIP artifacts verified, and three Stage12 ZIPs independently replayed with identical complete coverage. The prior 24-run figure was a counting error; the first two SHAs total 23 runs, then this pending-native SHA adds 10.

Pending_User_Execution was listed completely after completed results: one page, four files, no next_page_token. All four are PC-BRANCH-POWERSHELL-TAGALOG; no Rust package exists in the folder, so no file was trashed or deleted.

## Accepted state and hold

DEVELOPMENT_STAGE.md advances to:
CURRENT_STAGE=12
CURRENT_KIND=DISCOVERY06
CURRENT_PATCH=PATCH05
LAST_COMPLETED_STAGE=12
EXPECTED_REPOSITORY_STATE=DISCOVERY06_STAGE12_ACCEPTED_HOLD_NO_STAGE13

Stage12 is accepted on the evidence above. This is a hold before Stage13; no Stage13, main merge, protected-branch change, or release is authorized.
