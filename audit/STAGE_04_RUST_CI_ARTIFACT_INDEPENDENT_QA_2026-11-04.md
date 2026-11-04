# Stage04 Rust+Azərbaycan-dili — independent CI artifact QA (2026-11-04)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: `Rust+Azərbaycan-dili`
Verified CI source HEAD: `01978f0d04e2c6cc3ceab54b96ccbe4871c7e00e`
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41713417136
Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41713417340
Artifact ID: `13269310853` (`rust-az-stage04-discovery02-baseline`)
Artifact byte length: `20105`
Independently recomputed ZIP SHA-256: `f644ea41e20919d62d38ba07b52a7c7d99ffcd09e586f3614dd2ba98f3ce1026`
GitHub-reported artifact digest: `sha256:f644ea41e20919d62d38ba07b52a7c7d99ffcd09e586f3614dd2ba98f3ce1026`

## Evidence-first acceptance

Both workflow runs have `status=completed`, `conclusion=success`, on the exact verified source SHA; the named GitHub workflow log, steps and archived ZIP were inspected, **not rerun**. The ZIP contained 17 distinct members and passed an independent CRC check. The archived `sha.txt` equals the verified checkout HEAD; `exit.txt=0`.

Independent offline evidence audit: **21 of 21 assertions passed** (Python stdlib, read-only ZIP parse). This independently recalculated rather than copied the archive's key classifications:
- Nine callability unit controls: 9/9, no skips, failures or errors; one native Rust executed positive uses **synthetic historical Git fixtures**, not production history.
- Historical provenance unit controls: 13/13, no skips, failures or errors.
- TSV contract unit controls: 6/6, no skips, failures or errors.
- Rust native regression totals read from `stdout.txt`: `16+3+4+2+3+3+3=34`, 0 failed.
- The strict four-field TSV contains exactly 15 rows, indices 0..14; every integer day, oracle result and Rust candidate field agrees with the direct-runtime JSON case at the same index.
- Independently recalculated the numerical oracle from the date offset `d-F` with `F=-15055671`: `2*abs(d-F) + (1 if d>=F else 0)`. The archived **Python** old-rule result is `2*abs(d-F)`; exactly 8 RED and 7 CONTROL, 0 unexpected. All 15 archived-patched results and all 15 current Rust candidate results equal the independent oracle. These RED cases **do not establish a historical Rust RED**.
- The pinned historical Stage3 `src/lib.rs` blob `8a813ba020c9101276007148c93cb00ae7836644`, commit `716e5a6f335b1a15464029b446edb468f3a8482c`, is source-eligible, but the actual archived callability verdict is `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`. `callable_day_tag_route_verified=false`, `observed_runtime_red=false`.

## Decision and NEXT

QA of the specific completed CI and independently downloaded artifact: **PASS**. This does not prove the existence of a callable pre-Stage4 Rust production day-tag or its numeric mismatch. **Stage04 remains OPEN; CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; closure NOT_CLAIMED.** No Stage05, main, merge, or production publication.

NEXT: Preserve the verified evidence and inspect a genuinely new, provenance-eligible pre-Stage4 Rust production day-tag witness only if new source evidence appears. If such evidence appears, compile/execute that exact pinned function and compare its observed outputs against the independent oracle; otherwise retain the evidence-first Stage04 OPEN verdict. Do not re-run already completed CI on the old SHA or repeat exhausted history searches.

This file is a new evidence audit, not a code change, a fresh Native run, or a Stage04 closure declaration.