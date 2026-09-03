# JavaScript + Interlingue — normative name correction

Expected base HEAD when prepared:
`a1a0bfabd60326b592a87977eea8a13872dd6d23`

Normative corrections:
- cutlet canonical index 7: `Palgursh` -> `Palgurash`
- month canonical index 8: `Karshumb` -> `Karshumab`

No canonical index, ordering, selection rule, calendar arithmetic, or public API shape is changed.

Files:
- `src/source-language-catalog.js` — corrected replacement
- `tests/source-language-normative-names.js` — focused regression test

After copying into the branch, run:
`node tests/source-language-normative-names.js`

The existing `tests/run-tests.js` should also receive these two exact assertions when convenient:
- `textByCanonicalIndex('cutlet', 7) === 'Palgurash'`
- `textByCanonicalIndex('month', 8) === 'Karshumab'`

This delta intentionally does not touch `.github`; the all-branch audit workflow is delivered separately.
