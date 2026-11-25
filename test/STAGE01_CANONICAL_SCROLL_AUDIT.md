# Stage 1 — canonical Hebrew Scroll audit

**Project:** PC-BRANCH-FORTRAN-ENGLISH  
**Baseline before correction:** 6f1be87ebcf4769710bd5891086760a2e7f67cd4  
**Component correction:** a855ec194ff90eb580fcbdfd50dad915fc3b1ec5  
**Disposition:** the twelve-post-stir component is corrected and independently checked; Stage 1 remains open.

## Normative authority

The governing source is the Hebrew Scroll snapshot:

- File: `Megilat_HaItim_Yehuda_FINAL_2026-09-18.md`
- SHA-256: `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b`
- Chapter: `לוח ארבעה עשר: לבלול שתים עשרה פעמים אחר הטיפה האחרונה`
- Snapshot lines: 831–885

The Hebrew source governs; the English translation and implementation consensus cannot override it.

## Exact twelve-post-stir rule

For stir number i=1..12, let b[1..6] be the six bowl values at the beginning of the stir.

1. Compute rawBowlSum = b[1]+...+b[6].
2. Compute savedOrderValue = SAVE(rawBowlSum + 149*i).
3. Select the lexicographic permutation of the six bowl IDs with one-based rank 1 + ((savedOrderValue - 1) mod 720).
4. For bowl o[p] at position p, with circular predecessor o[p-1] and successor o[p+1], compute:

```text
subtotal = b[o[p]]
         + 3*b[o[p-1]]
         + 5*b[o[p+1]]
         + rawBowlSum
         + i
         + p*p

newBowl[o[p]] = SAVE(subtotal*subtotal
                     + 7*b[o[p-1]]*b[o[p+1]])
```

All six updates read the same beginning-of-stir vector and are installed together. The saved value selects the order only; it does not replace rawBowlSum in the update formula.

## Defect found in the baseline

Both the Fortran routine `test/normative_oracle_core.f90::post_stir_12` and the SHA-pinned Python reference `tests/normative_reference.py` at blob `d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53` used the saved value in the update subtotal as well as in permutation selection. This contradicts the Hebrew Scroll's separate instructions.

The previous Fortran/Python differential therefore established agreement between two implementations sharing this defect. It did not establish canonical conformance.

## Correction and component evidence

- Commit `a855ec194ff90eb580fcbdfd50dad915fc3b1ec5` changes Fortran to retain both rawBowlSum and savedBowlSum.
- `test/stage01_scroll_stir_reference.py` is a standalone arbitrary-precision transcription of this rule from the Hebrew Scroll; it does not import or copy the pinned Python calendar implementation.
- `test/stage01_scroll_stir_probe.f90` invokes the actual Fortran `post_stir_12`.
- CI run `44959203482`, job `137014022296`: self-test 17/17; five vectors; 30/30 final bowl values exact.
- Artifact `14728313661`: SHA-256 `1986584cca056b0a8a922a415492a794cfe8dc521ddddcec07afef7491bce6c4`; downloaded and verified; ZIP CRC clean.

This is component-level evidence only. It does not independently prove the gate sequence, year selection, cutlet partition, month count and lengths, month weaving, name selection, or complete five-field date.

## Foundation-Day diagnostic contract

The diagnostic captures the corrected Fortran output for calculationDay=targetDay=Foundation Day, without treating it as an expected answer.

- Input: the actual Fortran `foundation_day()` used as both calculation day and target day.
- Output: the five date fields, selected year gates, cutlet partition and names, month lengths and names, and the complete month-weaving sequence.
- The five projected fields contain canonical **name indices** for cutlet and month, not their positional indices. The probe separately identifies the containing cutlet position and woven month ID before checking the projection.
- Internal checks: array dimensions, cutlet partition across gate intervals, contiguous calendar-day boundaries derived from the gate days, month bounds, exact weaving frequencies, first/last occurrence ordering, and projection-to-structure consistency.
- Cutlet partition values count gate intervals, not days. For a cutlet beginning at gate index g and containing q gate intervals, its first calendar day is gate_day(g)+1 and its last calendar day is gate_day(g+q). The day span is the sum of the q intervening gate gaps, not q itself.
- The artifact is explicitly candidate-only. It records no canonical expected tuple and cannot accept Stage 1.

The legacy actual-weave artifact's 45-month/4,244-day metadata came from the Python reference structure, not from the corrected Fortran structure. The legacy full-year Fortran probe stops at its hard-coded 45/4,244 assertion before reporting the actual structure.

## Remaining full-date oracle gap

The pinned Python reference is not suitable as a canonical full-date oracle until its other rules are independently checked against the Hebrew Scroll. After the correction, the legacy full-date comparisons fail against that reference; these mismatches are not canonical expected values.

The next acceptance-quality step is a complete independent implementation derived from the Hebrew Scroll, with separately verified intermediate results for the sauce, gates, year selection, cutlets, month count and lengths, weaving, and names. No full-date tuple or full-year differential is promoted to canonical acceptance before that work is complete.

**Acceptance flag:** `full_stage1_accepted = false`.

 
## 2026-11-25 — Independent full-date differential, bounded adjacent contexts

- Source SHA-256 corrected and verified: `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b` (64 hex characters).
- Branch commit tested: `d6613037b43163a7d866f28af92fa9ffeaef9d8b`.
- GitHub Actions run: `45673365685`; job: `139414918492`; both completed SUCCESS.
- Source-pin check: 8/8; independent oracle self-test: 14/14.
- Full-date differential: 5/5 cases and 25/25 exact fields:
  - calculation offset 0, target offsets -1, 0, +1;
  - calculation offsets -1 and +1, target offset 0.
- Artifact: [fortran-stage01-scroll-full-date-context-diff](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45673365685/artifacts/15049779556), artifact ID `15049779556`, 2,405 bytes.
- This is bounded QA evidence only; it does not accept Stage 1. Next: run the independent wide-context suite, covering the remaining distant calculation-day offsets and additional year crossings.

 
## 2026-11-25 — Independent Scroll year-boundary differential

- Tested commit: `56699815137a28aa26887ade86b34e8690b5bf82`.
- GitHub Actions run: `45674348982`; job: `139418351498`; completed SUCCESS.
- Source pins: 8/8; independent oracle self-test: 14/14.
- Differential: 9/9 cases and 45/45 exact fields.
- Cases covered target offsets -1/0/+1; calculation offsets -1/+1; and four year-boundary targets in years 4999/5001 (-2033, -2031, 2212, 2214).
- Artifact ID `15051426902`, 3,018 bytes; ZIP SHA-256 `fee86d82941fa7dcbb396866f6c834a8e8a6a60a07b40e8f4a92281e93717b1b`.
- Artifact URL: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45674348982/artifacts/15051426902
- This remains bounded QA, not Stage 1 acceptance. Next suite covers nine wider calculation contexts, including ±8192 and year crossings.

 
## 2026-11-25 — Wide-suite selection correction

- The first commit introducing `--suite wide` did not route the comparison loop to `WIDE_CONTEXT_CASES`; the parser accepted the option, but the loop still used `BOUNDARY_CASES`.
- The automatic run `45675469692` on commit `cd6f6e4a734c713fc2decfb35074d2e07c231b00` is therefore not evidence for the wide suite. Do not count its output as a wide-context result.
- Corrected the dispatch to select the case tuple by `args.suite`, and changed all result totals/acceptance comparisons to use the selected `cases` sequence. The next run is the first valid wide-suite execution.

 
## 2026-11-25 — Independent wide calculation-context differential

- Tested commit: `f90fd83afba7df755f8f8289905c8aa5875987a4`.
- GitHub Actions run: `45675704650`; job: `139422977304`; run and job completed SUCCESS.
- Source SHA pins: 8/8; independent Scroll oracle self-test: 14/14.
- Wide-context differential: 9/9 cases and 45/45 exact fields. Cases explicitly included calculation offsets -8192, +8192, +137, -2048, +2048 and the four ±2032/±2213 year-crossing contexts.
- Artifact ID `15051049683`, 3,585 bytes; ZIP SHA-256 `5a05d9d9a5776d9a08ca7b36443bac6788bc95045a7dcaf78c56d8d26071be0a`.
- Artifact URL: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45675704650/artifacts/15051049683
- Combined with the prior boundary suite: 18/18 independent full-date cases and 90/90 exact fields, including all 14 original calculation contexts and four extra year-boundary neighbors.
- This remains bounded QA, not full Stage 1 acceptance. Next: same-process cache sequence testing, with warm-cache and reset-before-each modes, against the same independent Scroll oracle.


## 2026-11-25 — Exact Scroll snapshot recovered and byte-verified

This section supersedes the earlier statement that the canonical Scroll snapshot was unavailable. An exact-name search located the source in the user's Library; the raw file bytes were materialized and hashed without text normalization.

- File: `Megilat_HaItim_Yehuda_FINAL_2026-09-18.md`
- Size: 82,877 bytes
- Modified date: 2026-09-18
- Raw-byte SHA-256: `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b`
- Result: exact match to the source hash pinned in the independent oracle.
- The source file was not copied into this public repository. Only its name, digest and audit crosswalk are recorded here.

### Source-to-oracle crosswalk

The independently authored components were reviewed against the corresponding Hebrew source tables:

| Source section | Lines | Independent implementation |
|---|---:|---|
| Day numbering, question/distance/direction, arithmetic and SAVE | 31–268 | `stage01_scroll_gate_independent.py` |
| Stones, hidden drops, 46 visible drops, bowl initialization, permutations and pouring/stirring | 269–830 | `stage01_scroll_gate_independent.py` |
| Twelve post-stirs | 831–894 | `stage01_scroll_stir_reference.py` and gate oracle |
| Bowl answers and unbiased selection, including wide ranks | 895–1164 | `stage01_scroll_gate_independent.py` |
| Gates and year 5000 / adjacent-year selection | 1165–1376 | `stage01_scroll_gate_independent.py` |
| Cutlet partition and cutlet-name selection | 1377–1508 | `stage01_scroll_cutlets_independent.py` |
| Month count, month lengths and first/last-occurrence weaving | 1509–1660 | `stage01_scroll_months_independent.py` and `stage01_scroll_weaving_reverse_endpoint.py` |
| Canonical month-name selection | 1661–1805 | `stage01_scroll_month_names_independent.py` |
| Five-field date projection | 1806–1885 | `stage01_scroll_full_date_diff.py` |

The source's twelve-post-stir table (831–885) was checked line-by-line: the saved value selects the permutation; the update subtotal uses the raw six-bowl sum; every bowl update reads the same pre-stir vector; and all six new values are installed together. No further Fortran correction was indicated by this source check.

The source-byte verification is an out-of-band Library verification, not a GitHub Actions result. The full-date and reverse-endpoint scripts now report `source_bytes_verified` truthfully: true only when `--scroll-file` is supplied. The GitHub runners do not possess the Library file, so their artifacts correctly remain false for that field. The workflow's source-pin count checks literal SHA pins, not raw source bytes.

### Legacy Python-reference failures are non-canonical

Run `45551382647` contained eight failed diagnostics: `stage01-mixed-cache`, `stage01-expanded-real-date-diff`, `normative-real-date`, `stage01-actual-weave-diff`, `stage01-calculation-context-diff`, `stage01-boundary-neighbor-diff`, `stage01-cache-reset`, and `stage01-actual-45-full-year`. All eight jobs are explicitly named `LEGACY diagnostic only` and have `continue-on-error: true`. They compare against the old pinned Python Git blob `d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53`, which shares the pre-correction post-stir defect; the 45/4,244 full-year diagnostic also hard-codes that obsolete year structure. These red diagnostics are retained as historical evidence, not treated as canonical failures or silently converted to passes. The source-based Hebrew Scroll differential is the canonical replacement.

### Exact-HEAD evidence before this audit commit

- Branch HEAD: `0840528966cefecc963c1917e941a1d30e91d49c`.
- Run `45677479740`, exact HEAD SHA, completed successfully:
  - job `139428783100`: component/stir/gate/cutlet/month/name and component-differential gates passed, including `37/37` exact component comparisons and `304` suffix shapes / `4,770` ranks (conditional suffix only).
  - job `139429303310`: wide full-date differential `9/9`, `45/45` exact fields; resource log `299.41s`, peak `690,900 KiB).
  - job `139432593578`: same-process cache differential `48/48` calls, `240/240` exact fields; resource log `756.22s`, peak `690,372 KiB).
- Artifacts `15051723545`, `15053211658`, `15054435545` were downloaded; ZIP CRC and embedded JSON were checked against the run/job/SHA.
- The boundary suite `9/9` previously passed on SHA `56699815137a28aa26887ade86b34e8690b5bf82`, not on this HEAD. The unrestricted `44)-month/`4,399)-day seal32 full unrank previously passed `4,399/4,399` IDs and `5/5` Foundation fields on an older SHA, not on this HEAD.

### Next gates

This commit adds the missing reverse-endpoint source pin and schedules both boundary and wide full-date suites on one exact HEAD; changing the reverse-endpoint oracle also triggers the unrestricted 4,399-ID full-unrank workflow on that same HEAD. Until those completed run/job/log/artifact results are inspected, Stage 1 remains open.

**Acceptance flag:** `full_stage1_accepted = false`.
