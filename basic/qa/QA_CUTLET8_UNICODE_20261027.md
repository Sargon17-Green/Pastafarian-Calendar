# BASIC + ਪੰਜਾਬੀ — Cutlet8 / Punjabi Unicode targeted QA
Date: 2026-10-27
Project: PC-BRANCH-BASIC-PUNJABI
Branch: `BASIC+ਪੰਜਾਬੀ`
Inspected HEAD: `8c977fa2c4b9e52f8907ceff19e6f123727fcf55`

## Scope and evidence
This is a **static targeted QA record**, not a StarBasic execution result. No source code changes or stage transitions were authorized/performed.

Exact files inspected at the recorded HEAD:

- [Correction note](../../CANONICAL_NAME_CORRECTION_NOTE_PA.md), blob `c8b81038c2789902da2e0d93c07ebc299f2ecfe4`
- [Catalog](../Standard/Catalog.xba), blob `d211dd28ab4a4bf4da5f9b16c35942aef4b6eb24`
- [Tests](../Standard/Tests.xba), blob `3782a00085bb1489faf310272a99892eb2c625a2`

## Targeted checks (11/11 static checks met)
1. Later owner adjudication in the correction note supersedes historical cutlet-8 spelling.
2. `cutletNames(8) = "ਮੋਥਾ"`.
3. `CATALOG_CUTLET_8` asserts `CatalogCutletName(8) = "ਮੋਥਾ"`.
4. Catalog/test agree: month index 8 = `ਕਰਸ਼ੂਮਵ`.
5. Catalog/test agree: month index 31 = `ਦੀਵਾ`.
6. Catalog/test agree: month index 36 = `ਸੂਸਾ`.
7. Exactly one `CATALOG_CUTLET_8` test-code occurrence.
8. `Tests.Main` includes `OVERALL=PASS`, `OVERALL=FAIL`, and `OVERALL=ERROR` output branches.
9. Four adjudicated Gurmukhi literal values are already NFC-normalized.
10. All catalog cutlet/month literal values are NFC-normalized.
11. The catalog defines 17 cutlet and 47 month indexed literals.

Check method: targeted regex assertions against retrieved UTF-8 source text; NFC checked by JavaScript `String.prototype.normalize("NFC")`. These checks do **not** prove StarBasic compilation, execution, I/O, or the entire Unicode repertoire contract.

## Native execution: not verified
The expected next step remains execution of `Tests.Main` from this exact branch and saving the raw `/tmp/pastafari_basic_stage1_test_results.txt` output. Required acceptance lines are `CATALOG_CUTLET_8=PASS` and `OVERALL=PASS`. **Neither line has been observed in actual program output.**

A Linux runtime has LibreOffice 25.2.3.2 and Python UNO, but the isolated runtime cannot resolve `github.com` for source checkout. GitHub connector can inspect source files, but it does not directly populate that runtime's filesystem. Two linked Desktop Commander devices are offline. Do not retry the same inaccessible git-clone or remote-desktop execution paths without an actual connectivity/source-access change.

**Release condition:** provide a runner with the existing branch checked out and working LibreOffice StarBasic, or make the seven `basic/Standard/*.xba` modules available to an executable LibreOffice runtime. Then run the existing `Tests.Main` and attach the complete raw output to this branch or Google Drive; report failures without calling the run PASS.

**Single NEXT:** execute existing `Tests.Main` at the verified branch HEAD in a source-accessible LibreOffice/StarBasic runtime, preserve its raw output, and verify both required lines. Do not open stage 2 without authorization.

## 2026-10-27 targeted independent re-verification

- Branch HEAD independently read back as `fee09b9799b2bd36db809cd7733506c09e50ad30` before this note update.
- Exact inspected blob identities were unchanged: correction note `c8b81038c2789902da2e0d93c07ebc299f2ecfe4`, `Catalog.xba` `d211dd28ab4a4bf4da5f9b16c35942aef4b6eb24`, and `Tests.xba` `3782a00085bb1489faf310272a99892eb2c625a2`.
- Direct static re-check confirms `cutletNames(8) = "ਮੋਥਾ"` and the sole `CATALOG_CUTLET_8` assertion expects `"ਮੋਥਾ"`; month literals at canonical indices 8, 31 and 36 match both catalog and tests. All four inspected Punjabi target strings are NFC.
- The prior adjudication `ਪੈਪੀਰਸ ਸੇਜ → ਮੋਥਾ` is retained in the source note. The test writes to `/tmp/pastafari_basic_stage1_test_results.txt` and contains an `OVERALL=PASS` code branch, **which is not execution evidence**.
- A separate local runtime confirms LibreOffice 25.2.3.2 and system-Python UNO are installed, but no `Tests.xba`/`Catalog.xba` source checkout is available in its mounted working directory. Existing failed Git DNS and offline remote-desktop paths were **not retried**. No native `Tests.Main` output was generated.
- **Still blocked:** run `Tests.Main` in a source-accessible LibreOffice/StarBasic runtime; save the entire raw output in GitHub or Google Drive and inspect actual `CATALOG_CUTLET_8=PASS` and `OVERALL=PASS`. No stage 2 authorization.

## 2026-10-28 native evidence closure and source-to-output reconciliation

**Superseding current status:** The earlier "Native execution: not verified" and native-access blocker in this historical QA note are now closed by a separately preserved genuine LibreOffice/UNO run. Do not interpret the older sections as the current project status.

- Native run provenance (as preserved in the project handoff): LibreOffice 25.2.3.2/UNO, all seven StarBasic modules from original source commit `16c341b8c43060cd894cdbebe23c92d83ee35009`; [complete raw result](STAGE1_NATIVE_TESTS_20261028.txt) stored on the same branch at `fb3ad7eb8e2a70e3c22a56e3ccf492c1e4b6b25d`.
- Additional **read-only source-to-output reconciliation** on 2026-10-28: `Tests.xba` blob `3782a00085bb1489faf310272a99892eb2c625a2` and native result blob `06db5e2471f576aeb1515aa4d1e3886ec19eb0e3` were fetched directly from branch HEAD `fb3ad7eb8e2a70e3c22a56e3ccf492c1e4b6b25d`. Expanded the four counted test loops (6 + 6 + 17 + 47 iterations) and the individual assertions; compared every expected result label in program order to every actual output line.
- Reconciliation result: **144 individual assertions + one `OVERALL` line = 145/145 unique `PASS` lines, in exact source-defined order**; 0 missing, 0 unexpected, 0 duplicate, 0 FAIL/ERROR lines. Both `CATALOG_CUTLET_8=PASS` and `OVERALL=PASS` occur in the preserved output. This check validates the *recorded result's completeness against the source*; it is not a fresh Native execution or an independent re-computation of calendar results.
- `CalendarSpaghettiStage() = 1` and the production entrypoint deliberately raises `E_STAGE_01_ONLY` under the Stage 1 contract. The Native pass completes the Stage 1 gate; it does not attest to a finished production date converter.
- **NEXT:** no Stage 2 authorization established for this current continuation. Obtain a concrete authorization decision before implementing `DISCOVERY 01`. No Stage 2 code, main change, or merge was performed by this reconciliation.
