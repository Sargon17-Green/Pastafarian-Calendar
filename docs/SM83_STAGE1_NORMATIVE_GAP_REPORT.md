# Stage 1 — normative calendar contract and implementation gap ledger

**Branch:** `SM83-Assembly+ግዕዝ` · **Project:** `PC-BRANCH-SM83-ASSEMBLY-GEEZ`

## Evidence and authority

- Canonical public specification (read-only; no cross-branch implementation import): `main` at `56bc4173aae4975ded019ef5ab5a36249f1424df`, `README.md` sections A–D, O–X, AA and **AC.1**.
- `tests/fixtures/sm83_stage1_canonical_vectors.json` is immutable *normative input/expected-output data*, pinned to that source commit, not output calculated by this branch.
- **AC.2 historical rawBowlSum mutant is explicitly excluded** as a conformance baseline. The canonical retained sum for post-stir `S_r` must be used both in the permutation and in `u`.
- `tests/test_sm83_stage1_normative_contract.py` independently validates day-count and five-counter mathematics for signed-32 and out-of-range integers; it also checks schema, 10 authoritative golden vectors, Foundation checkpoint, a 4244-day sample year gate, and mutant exclusion.
- Source-language catalog remains **ግዕዝ**, not Amharic; index-to-name mapping has **not been linguistically reviewed/frozen**, and no invented transliterations have been entered.

## Exact invariant scope

For a discrete integer day `d`, Foundation `F=-15055671`:
`N(d) = 2(F-d)` if `d<F`, otherwise `N(d)=2(d-F)+1`.

For an ordered pair `(c,t)` the five arithmetic work counters are:
`(N(c), N(t), |t-c|+1, N(c)+N(t), direction)`,
where direction is 1 for `t<c`, 2 for equality and 3 for `t>c`.

Retained arithmetic has `M=2^127-1` and `SAVE(x)=1+((x-1) mod M)`.

For the canonical `c=t=F` checkpoint, the gate interval for the selected year 5000 is
`(-15057703, -15053459]`, with length 4244. This gate is *not* generic for other calculation days.

## Acceptance boundaries — do not conflate

| Subsystem | Established at start of this work | Still missing |
| --- | --- | --- |
| Native smoke through 283 | exact SHA `fcea044fbb60518f5436bdaaa1136a9261ccdeb8`, PyBoy A5/283/40; ROM0 allocated16359/free25/maxgap23 | Full normative calendar invocation, not a bootstrap result |
| Foundation and five counters | signed-32 native+Host and source-defined exact arithmetic | arbitrary signed ordinals and sufficient precision for all later calendar intermediate states |
| Canonical vectors | main AC.1 exact 10 five-component outputs and detailed checkpoint | local, independent full calendar oracle computing each five-component result from rules |
| Year selection | rules: variable gaps 42..963; year 252..5778, anchor 5000; NEXT/PREVIOUS | Gate-generation, canonical selection, year walking; no actual executable dispatcher |
| Cutlet/month selection | canonical indices and rules, months 3..47, 4..123 days, interleaved weaving | rank/unrank for compositions, order constraints and wide selection, complete native implementation |
| Names | canonical indices (17 cutlets, 47 months) | reviewed/frozen Ge'ez source-language catalog |
| Time-to-day | discrete `(c,t)` interface is normative | astronomy profile for instant/location mapping (a separate boundary) |

## Next implementation contract

1. Use the pinned AC.1 data to develop a **separate executable full normative oracle**, deriving outputs from the actual state recurrence, not echoing golden vectors. First prove all intermediate checkpoints at `c=t=F`, especially post-stir `S_r` and gate selection.
2. Obtain exact independent five-component parity for all 10 vectors, including reverse/forward gates and `c \ne t`; avoid treating the historical mutant as valid.
3. Implement and exercise bounded native calendar primitives in small stages (prefer ROMX due to 25 measured ROM0 free bytes), then generalized SRAM-backed arithmetic and ownership for required ranges.
4. Freeze the 64-element Ge'ez name catalog only after classical-language orthographic review; semantic ordering always uses numerical canonical indices.
5. Require exact-SHA completed verify and DMG native logs for each accepted increment; **do not mark full Stage 1 PASS, merge, or enter Stage 2** until the actual normative engine, catalog, and full exit gates are proved.

This file records a truthful partial contract, not a declaration of Stage 1 completion.
