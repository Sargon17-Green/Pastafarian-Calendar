# Stage4 — signed remainder / large BigInt differential and metamorphic contract (2026-11-06)

Project: `PC-BRANCH-BASIC-PUNJABI`, branch `BASIC+ਪੰਜਾਬੀ`.

## Accepted prerequisite
- Stage3 source HEAD/lock: `74aa087b81094f34eab9a0e04e395cc693dd83b1`.
- GitHub Actions run `41878744368` completed/success; Stage3 actual raw native checks: **148 unique PASS / 0 FAIL / OVERALL=PASS**.
- Historical Stage2 v17 145 PASS + 3 deliberately RED accepted; **do not repeat Stage2**.
- The Stage3 suite and its canonical names remain BYTE-IDENTICAL; no production logic, BigInt, Catalog, or canonical-name-lock modifications.

## Independent oracle
- Modulus `M = 170141183460469231731687303715884105727` (2^127 - 1).
- Python arbitrary-precision integer reference:
  - `r(x) = x % M`, with `0 <= r < M`, including negative `x`.
  - `SAVE(x) = 1 + ((x - 1) % M)`, with `1 <= SAVE <= M`.
- Live StarBasic `BI_Normalize`, `BI_RegularMod`, `BI_Save`, `oldRemainder`, and `CalendarSpaghettiDiscovery01Remainder` must match the independent oracle.
- Fixed seed `0x20261106`; exhaustive small offsets about `-3M..3M`, signed powers of 10 up to 256 digits, sign/zero-prefix normalization, 24 seeded large-number families, and `x-M`/`x+M` metamorphic relationships. Every input and output is recorded in `cases.tsv`.
- Any single mismatch, missing output, duplicate input, missing UNO invocation, or metamorphic inconsistency is a FAIL.
- The probes are injected into **a private temporary copy** of `Tests.xba`; the actual 148 Stage3 tests and source files are not edited.

## CI gate and evidence
- The `stage4-bigint-differential` job is restricted to push events on `BASIC+ਪੰਜਾਬੀ`; it depends on both `verify` and `stage3-native-green`. Thus canonical-name and 148-native-test gates must be green first.
- Fresh isolated LibreOffice/UNO profile from a CI temporary directory; no legacy `D:/v17` paths, no machine-wide cleanup, no main/merge/publish.
- Emit `status.txt`, `cases.tsv`, `assertions.json`, `lo-startup.log`, and `error.txt` on exceptions. Retain GitHub Actions logs and artifact. **ACCEPT Stage4 only after completed/success native job and raw evidence verification**; queued or in_progress is neither PASS nor blockage.
- Do not claim that Stage3 historical Windows v17 workspace was cleaned or that the full five-field calendar engine works.

Source SHA and evidence are kept in the two designated tracker rows; while CI is pending, retain D=פתוחה and G=READY.
