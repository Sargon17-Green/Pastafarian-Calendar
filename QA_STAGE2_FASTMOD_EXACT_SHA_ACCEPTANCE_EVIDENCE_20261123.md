# PC-BRANCH-LOGO-IDO — Fastmod exact-SHA Native QA verification (2026-11-23)

**Scope:** QA evidence only; not Stage 2 acceptance and not canonical promotion.

- Canonical branch `Logo+Ido`: `ad001c6aeeb6c758f5004b206a656fec5d6fc403` (unchanged).
- Executed QA branch `qa/logo-ido-wide-horner-fastpath-20261123`: `633db2c4c12e7d4ba0872b2c97fdf23439e1bea7`.
- This record is placed on the separate evidence branch `qa/logo-ido-stage2-fastmod-evidence-20261123`, branched from that exact QA source SHA. No production or Native workflow code changes.

## Completed runs and verified Native logs

| Gate | GitHub run | Job(s) | Verification |
|---|---|---|---|
| Exact-width Fastmod | [45087182742](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087182742) | k4=137408365386; k5=137408365475; k6=137408365149; k32=137408365501; k33=137408365432; k64=137408365499 | All six completed/success on source SHA; pinned UCBLogo 6.2.5; independent Python host oracle; Native counter lines and explicit shard PASS |
| Horner regression | [45087182646](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087182646) | k4=137408365153; k64=137408364777 | Both completed/success; actual Native output, independent Python rank, exit code 0 |
| Canonical Names Lock | [45087182592](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087182592) | 137408364684 | completed/success; name-lock step success |

Every Fastmod shard included a separate finite host enumeration: `WIDE_GENERAL_ENUM_CASES 42748`, `WIDE_GENERAL_HOST_ORACLE=PASS`. This enumeration is **host QA**, not Native cases. The actual headless Native shards passed **134 cases / 212 assertions**: k4/k5/k6/k64 each 22/34; k32/k33 each 23/38. Each shard includes 18 invalid-input guard cases and the expected independent Python fixture. The Horner regression passed another five actual Native cases (four at k4, one at k64). All exact-width Native completion markers and case-start counts were found in the artifact logs. No blanket performance guarantee or whole-stage acceptance is asserted.

## Independently rehashed artifact ZIPs

The following eight GitHub artifact archives were downloaded, checked with SHA-256 locally, opened as ZIPs and checked for corruption. The computed SHA-256 matched the GitHub reported digest in every case. File-level Native logs and exact source commit markers were also checked.

| Gate | Artifact ID | Independently computed ZIP SHA-256 |
|---|---:|---|
| Fastmod k4 | 14779503476 | `52933a9f3144352c9ab2d1744397b2934572437c2114321272c0e19de13fef09` |
| Fastmod k5 | 14779947729 | `b45f4950eed3c476c26e3e73ac9612243ac4ea391474a30ef791b60d95a4dce6` |
| Fastmod k6 | 14779652733 | `61539766d265efcfba3b72cf2d55b4e187039946634d0929f10416122f84a45b` |
| Fastmod k32 | 14780033332 | `19a0d7d78f8ed32e758561ea683ef65a9366871fe343159d9ac519d205bae8c8` |
| Fastmod k33 | 14780290983 | `43032c6d428d3d943ece578d54d71bc755452af540d0a9953245254cad80c27b` |
| Fastmod k64 | 14780292592 | `b095c7210fb2fa0ea44287b6f49cb407b37f7191e50758b613244232c29a11d5` |
| Horner k4 | 14779558584 | `0dc1b15cd462a191d0f1674035bae7fb6639691357dbe52d87a476d8b9546ee9` |
| Horner k64 | 14780390681 | `e57fc29ed56d37d17d2d55c2ab96869af9e33c6af0810782190aec8755b2e7e1` |

Fastmod ZIPs include shard commit, source Git blobs, workflow blob, host and Native logs and fixture; all six record the exact source SHA `633db2c4...` and `src/stage02_choose_wide_general.logo` blob `bda23ddc1d0f8a534b20d8391ecc7519fccd57c3`. Horner ZIPs record the same source commit, exit=0, expected case PASS markers. Artifact SHA is the ZIP SHA, not a source commit SHA.

## Gate decision and NEXT

**QA Fastmod exact-width shards: ACCEPTED on source SHA 633db2c4 only.** **Horner re-locked smoke: ACCEPTED on this source SHA.** **Stage 2 remains INCOMPLETE (LAST_COMPLETED_STAGE=1).** This is neither a production code change nor Stage 2 acceptance. No rerun, merge, main update, canonical promotion or user-execution bundle was needed.

**NEXT:** perform an evidence-first Stage 2 integration-gap review against the existing contracts and accepted canonical D21. Identify uncovered wide-k behavior and only authorize bounded new QA after proving a specific gap. Preserve exact SHA identity and avoid duplicating accepted CI/Native checks.
