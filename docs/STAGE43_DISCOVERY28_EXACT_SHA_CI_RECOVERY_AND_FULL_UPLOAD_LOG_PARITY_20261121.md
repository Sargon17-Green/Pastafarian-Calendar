# Stage43 / Discovery28: exact-SHA CI recovery and full artifact upload-log parity (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Audited SHA: 7305adb11d62c367b231071d7f0e2648df7d7fad
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904726367

Disposition: 17/17 returned jobs completed/success; 17/17 artifacts uniquely matched to decoded upload logs and GitHub digests; 14/14 in-memory envelope classifier cases matched. STAGE43_NOT_ACTIVATED / NOT_SEALED.

## Scope and provenance

This is a docs-only audit on a verified branch HEAD. The audited predecessor commit changed only the preceding discovery report. DEVELOPMENT_STAGE.md blob a3f53b67e4445bdc835179cd484fe27b3e2648f7 retains CURRENT_STAGE=42, CURRENT_DISCOVERY=27 and LAST_COMPLETED_STAGE=42. Compare from 6b01759e5b7315076f89cb3d5bb0c0d96e2de2c6 to the audited SHA was ahead 1 / behind 0, affecting only the previous docs path.

The connector returned 17 jobs, all status=completed, conclusion=success and run_id=44904726367; it also returned 17 current artifacts associated with the exact branch, run and SHA. All 17 decoded per-job logs were retrieved by job ID. The available connector action does not independently provide a run-level conclusion or run_attempt; neither value is asserted here. No rerun or dispatch was requested.

## Gates directly seen in decoded job logs

- Job 136847744689, hosted Windows PowerShell 5.1 Stage29/Stage30 and regressions: initial Stage01 73 passed / 0 failed, RESULT=PASS. The prior Hebrew-prose violation no longer occurs. Stage30 96/96, failed 0, seal recheck PASS.
- Same job, Stage23 finalizer twice: SHA256_BEFORE=0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF. Runs 1 and 2 both exit 0, stderr length 0, ALREADY_FINALIZED=True and unchanged SHA256. RESULT=PASS. Finalizer artifact 14706997928, reported ZIP digest sha256:35e200b720a8394611f575feb115cc06c4ae14bbbf9e8393acadb51ae8e0ef53.
- Job 136847744912, Stage43 Windows preflight: 240 endpoints, 160 target pairs, 216 seal pairs, 23 structural guards; 2215 passed / 0 failed, BOUNDED_ORACLE_PASS, NOT_ACTIVATED, NOT_CLAIMED. Artifact 14707487831, digest sha256:7fa8a7934ff51305c7d3eea0be31b27070f566053f7bd72b68aa5cc2b83dd575.
- Job 136847744852, Stage42: 1657 passed / 0 failed, SEALED_RECHECK_PASS. Artifact 14706983814, digest sha256:afa33b33a3f52ddd6db901b43bd4de1b5b47200e554144010ee7943d5381c649.
- Job 136847744883, Stage41: 481 passed / 0 failed, SEALED_RECHECK_PASS. Artifact 14706623950, digest sha256:8b97bcc7a4e7364db5f28e43a2a6c8e29d857a9c7e8ac942de1b071527658802.
- Job 136847744803, canonical verify: completed/success.

Other completed/success jobs by ID: Stage32 136847744502 (239/239); Stage35 136847744757 (896/896); Stage34 136847744768 (448/448); Stage31 ordinal 136847744788 (309/309); Stage31 normative boundary 136847744799; Stage38 136847744810 (680/680); Stage40 136847744813 (425/425); Stage33 136847744824 (560/560); Stage31 ordinal extension 136847744872; Stage39 136847744902 (379/379); Stage37 136847744919 (516/516); Stage36 136847744973 (1004/1004). The precise counters not listed for the two Stage31 sub-jobs were not inferred.

## Exhaustive metadata-to-upload-log parity

For every one of the 17 current artifacts, the API reported expired=false, workflow_run.id=44904726367, workflow_run.head_branch=PowerShell+Tagalog, workflow_run.head_sha=7305adb11d62c367b231071d7f0e2648df7d7fad and a sha256:64-lowercase-hex digest. Exactly one of the 17 decoded job logs contained the artifact's ID, ZIP name and the identical SHA256 upload digest. Zero anomalies.

| Artifact ID | Name | GitHub-reported ZIP SHA256 |
|---|---|---|
| 14707812360 | powershell-tagalog-stage36-dual-gate-evidence | a7f49a76c702d3c12357efb410868424a1bc35e1cc970f7d0b061a65295c4ee9 |
| 14707661896 | powershell-tagalog-stage39-cross-context-preflight | 9aa7e2ab0b832e9465afc86282f6e45e950015db1823ff122c058e8c13171c76 |
| 14707582436 | powershell-tagalog-stage37-nonunit-seal-native | a87689cdf28e21aedddac31eaf4e39d486515e840b38dc9553a015a5e0987fa7 |
| 14707487831 | powershell-tagalog-stage43-neighbor-year-preflight | 7fa8a7934ff51305c7d3eea0be31b27070f566053f7bd72b68aa5cc2b83dd575 |
| 14707451469 | powershell-tagalog-stage31-extension-evidence | b62580c9ffcd731a1c063e1700f871bc1c3d460da9fc253438f0aee7e54d4d14 |
| 14707433348 | powershell-tagalog-stage35-anisotropy-evidence | 3172b8be756bb8bcc55f0f2ae1f9043b9247401899a039ace159dd72acc9f621 |
| 14707321800 | native-powershell-tagalog-stage22-metadata | 83a79c99a81e6c583f279c2b004126d8096721f83c065d9ff25c50e36c906ce2 |
| 14707316908 | powershell-tagalog-stage40-calculation-gate-preflight | fff12c2907407634c4a77e38d42640fcd90f51357e585b537cffdca76cc7ea4a |
| 14707308166 | powershell-tagalog-stage34-cubic-evidence | fd538d4eaf52f16f0af0bdcf8de7d41236c0f39adbb90f0eeac5958726243062 |
| 14707253125 | powershell-tagalog-stage31-ordinal-evidence | dfcbf848626b6dc6184e577dea87ee7d50fe7c8707b1ac93feca570cf69e0b86 |
| 14707099507 | powershell-tagalog-stage33-grid-evidence | 39ae6e5aabc256967c2ec4e6339903561cdfb742a9446d40cdb5226b34511bfc |
| 14707099009 | powershell-tagalog-stage38-full-seal-native | 17ed22b2b5d8e6af4d3c9560a6f275671c745af3106a89aa5ce2a682b99e2142 |
| 14707042501 | powershell-tagalog-stage31-year-boundary-evidence | 6728a17f789b5ebeaa4ade31bee927ee52ec8128d2beaf4f7dc42a6e3ada4ce5 |
| 14707024497 | powershell-tagalog-stage32-canonical-evidence | 109d3426d13751055dbf6815aed7c42b7187a839ef4341050609d9eae685799d |
| 14706997928 | native-powershell-tagalog-stage23-finalizer-idempotency | 35e200b720a8394611f575feb115cc06c4ae14bbbf9e8393acadb51ae8e0ef53 |
| 14706983814 | powershell-tagalog-stage42-all-seals-preflight | afa33b33a3f52ddd6db901b43bd4de1b5b47200e554144010ee7943d5381c649 |
| 14706623950 | powershell-tagalog-stage41-coupled-gates-native | 8b97bcc7a4e7364db5f28e43a2a6c8e29d857a9c7e8ac942de1b071527658802 |

These are GitHub-reported ZIP hashes corroborated by GitHub upload logs, not independent ZIP downloads, extraction or locally recalculated SHA256 values.

## Independent in-memory classifier: 14 of 14

A separate JavaScript envelope classifier tested the live baseline and 13 isolated deep-copied synthetic mutations. A valid envelope must have exactly 17 unique jobs, all from the pinned run and completed/success, exactly 17 unique artifacts and 17 logs; each artifact must have matching run/branch/SHA, non-expired status, valid sha256:64-hex and exactly one log with matching ID/name/digest. Every invalid envelope fails closed.

V00 actual live envelope ACCEPT; V01 missing job REJECT; V02 job failure REJECT; V03 duplicate job ID REJECT; V04 foreign job run ID REJECT; V05 missing artifact REJECT; V06 expired artifact REJECT; V07 foreign artifact SHA REJECT; V08 malformed digest REJECT; V09 wrong branch REJECT; V10 duplicate artifact ID REJECT; V11 changed logged digest REJECT; V12 missing log REJECT; V13 changed logged artifact ID REJECT. Expected and observed matched in all 14 cases.

This classifier was executed in memory. The deliberate negatives were synthetic mutations, not live failures, PowerShell execution or an algorithmic differential oracle.

## Remaining limits and next gate

Stage43 remains research-only, NOT_ACTIVATED and NOT_SEALED. Existing duplicate/mixed B-H state and parser acceptance gaps, plus warning-only artifact-missing behavior, are outside the authorization for executable remediation. Do not change tests, workflows, production source, normative oracle, lifecycle state, protected main or merge as a consequence of this report.

This docs-only commit itself creates a new SHA. The successful Native run above belongs to the **audited** SHA only. A subsequent automatic workflow on the new documentation SHA is a separate pending result until jobs, logs and artifacts are checked. Do not dispatch a duplicate CI run.
