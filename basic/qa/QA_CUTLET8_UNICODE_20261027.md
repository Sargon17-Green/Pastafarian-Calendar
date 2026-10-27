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
