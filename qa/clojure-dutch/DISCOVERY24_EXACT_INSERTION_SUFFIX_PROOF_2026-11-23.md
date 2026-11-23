# DISCOVERY24 — independent exact insertion suffix proof (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: `Clojure+Nederlands`
Scope: **TEST/QA ONLY**. No production or API edit. Stage2 remains **OPEN**.

## Exact source and bytes

- Canonical source commit: `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84`; production `src/pastafari/maandrang.clj` blob `62f304dc013a9a9f70475bb0d34f186838b27318` checked through GitHub.
- Existing completed run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365. `verify` job 137340625261 SUCCESS; isolated DP job 137340625561 SUCCESS **with DP_FEASIBILITY_UNPROVEN**; full Clojure Native job 137340626593 SKIPPED.
- Existing immutable artifact 14770898411 ZIP sha256 `eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5` (12,468 bytes); its normative true flags are **prior source-locked CI assertions, not independently rerun**.
- New independent QA script: `qa/clojure-dutch/discovery24_exact_insertion_qa.py`; Git blob `a36fc46d80db5b4b14d979dc028bb654c9999364`, local SHA256 `55da8a1032e591d0c428448591e168d391e829fca891b6dbc4693cc2ad4b4210`, 13,991 bytes. GitHub blob/readback equals local Git blob and length; commit `c8ff3a023ed3b4112a766d0b4a49b665906ab4df` [skip ci].

## Mathematical contract, proof and limits

Input: counts of remaining distinct month labels, the highest first-opened index and number of lowest consecutively last-closed labels. Valid legal suffixes satisfy ascending first openings for **unopened** labels and ascending last closings for **all live** labels. Output: exact integer suffix count or exact lexicographic rank path, with **production bounded-prefix shared-group charge**.

Proof by deletion/insertion of the largest label: Any legal completed word ends in its largest live label. Deleting every copy of that label gives a unique legal smaller-label word. Reinserting `k` copies into `N+1` gaps must put at least one at the terminal gap. For a fixed first insertion gap `a<N` there are `C(N-a+k-2,k-2)` possible gap multisets; for `a=N` exactly one. For an unopened label whose predecessor was also unopened, require `a >= first_position(previous label)`. For the **first** newly opened label after already-opened labels, there is no such restriction; this distinction matters for partially consumed suffixes. The resulting first-position DP is exact without recursion, and normalizes by each fixed legal active-only base word. Active-only last-closure sequences contribute the exact independent interleaving factor `product_j C(S_j-1,k_j-1)`. This yields a 1D iterative DP using unbounded integers, independent of production `tel-rest` and of any borrowed oracle/fixture.

Production cost **must** follow `prefix-op-rang-begrensd` and `prefix-gedeelde-raming`, not the separate per-candidate `raming` used by `weving-op-rang-groot`. For each position, a nonempty group of already-opened legal candidates incurs `1 + (m-opened)*remaining_days` **once**. Only if all that group's candidates are skipped is a new month charged separately at `1 + (m-opened-1)*remaining_days`. The initial forced month 1 is uncharged. The QA model independently enumerates exact lexicographic candidate blocks and charges in that order. Its output is a **model proof**, not an observed Clojure Native result.

## Executed evidence

Commands:

```bash
python -m py_compile qa/clojure-dutch/discovery24_exact_insertion_qa.py
python qa/clojure-dutch/discovery24_exact_insertion_qa.py --artifact-zip /path/to/github-actions-artifact-14770898411.zip
```

Local Python syntax exit 0, standalone QA exit 0, elapsed 10.248 seconds (run 2026-11-23). Exhaustive independent multiset brute oracle: six small profiles, 59 legal words, 69 unique reachable partial-state exact counts, 10 extra opened-state checks, 436/436 rank-prefix checks, 436/436 cost-boundary accepts (including free initial prefix), and 377 cost-minus-one refusal checks. Modified canonical ZIP rejects at SHA guard, process exit 1.

Exact artifact input: 33 months, 3,569 days, 5,288-digit rank; computed legal-word count is **exactly equal** to the prior frozen Clojure total (also 5,288 digits). First month is forced to 1; the suffix count for candidate `1` at position 2 has 5,286 digits and is smaller than the source-locked rank. The independent rank path therefore selects 2 at position 2, not an undecidable 9..5358-digit interval.

For **both** p82 and p520 under the unchanged `5_000_000` shared-cost budget:

- Exact certified prefix length = **81**; comma-joined prefix SHA256 = `2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a`.
- At position **82**, before testing the first active candidate (month 1): already billed **4,995,675**, mandatory next shared charge **6,977**, so total would be **5,002,652 > 5,000,000**.
- Observed independent QA status: **BUDGET_REFUSAL**, active group; opened=31, closed=0, tested=1,173 exact candidate blocks, skipped=1,093, active shared-charge groups=80, new-month shared-charge groups=30. The certified prefix stops before the charge. This is **not** a production Native output and proves **no** five-field equality or full Stage2 acceptance.

## Gate classification and next

- Independent Python QA, syntax, artifact SHA, Clojure source blob identity, exact tiny-oracle checks: **PASS**.
- Canonical suffix count / rank path until first mandatory budget exceedance: **QA-PROVEN**.
- Canonical p82 and p520 within the unchanged bounded-prefix budget: **CERTIFIED BUDGET REFUSAL**, not a successful full prefix or a production regression.
- New CI **NOT_RUN**, new Clojure Native **NOT_RUN**, five-field differential **NOT_RUN**, Stage2 **OPEN**.
- NEXT (authorized TEST/QA only): use a second independent small-profile cost oracle to assert the exact shared-group charge schedule against the literal production formulas, exhaustively test first-open/last-close transition edge cases and independently verify the canonical 81-symbol prefix fingerprint and first refusing charge. Record a focused model-vs-source audit before considering any new CI/Native authorization. Do not change production/API, search 128N, budget 5000000N, main, merge, publication or policy. Do not dispatch duplicate accepted same-SHA CI. No pending-execution cleanup without newly received execution results.
