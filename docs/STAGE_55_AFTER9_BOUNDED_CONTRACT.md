# Stage 55 — bounded AFTER8 → AFTER9 differential contract

Project: PC-BRANCH-MATLAB-POLSKI; branch `MATLAB+Polski`. This is an incremental test, not final Stage 55 acceptance.

## Immutable input / predecessor
- Native/Python predecessor GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199709414 (completed success; original ZIP artifact 13042074117).
- `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_8.json` SHA-256: `76873d9ec945eb2e3de8d67606f5ee61994049b03dff7796c9f29b632c3442d3`.
- 45 month lengths, year 5000, first_day -15057702, 4244 source days. Original rank/count are decimal strings, parsed exactly.
- Opening prefix `[1,2,3,4,5,6,7,4]`, openedUpTo 7, closedUpTo 0, steps 8; parent remaining total 4236; remaining[i] = original[i] - (i < 7) - (i == 3) for zero-based i.

## Outputs / oracle
1. MATLAB R2026a performs exactly one bounded unrank transition using the production generalized suffix cursor; checks exact count by independent MATLAB recount; writes UTF-8 AFTER_9 JSON and Native five-field row.
2. Independent Python insertion-count oracle enumerates 22 bounded brute-count controls from seven small length families, then all eight legal child blocks `j=1..8`. It must verify positive child counts, block sum equal to parent count, selected child's count equal to Native, and `sum(blocks[1:j-1]) = parentRank - childRank` with a strict rank interval.
3. Checkpoint must have steps 9, remaining 4235, exactly one unit removed, openedUpTo 7 except when next letter is 8 (then 8), closedUpTo 0, and exact persisted rank/count in [1,count].
4. Projection must agree byte-for-byte across Native and independent Python: `POSITION=9 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=9 MONTH_INDEX=<fixture index> MONTH_DAY=<occurrence>`, five components represented by year, cutlet name `Akad`, cutlet day, month name and month day. Require negative rejections at target positions 0 and 10.
5. GitHub workflow uses `matlab-actions/run-command@v3`, timeout 30 min, SHA-pinned predecessor, always uploads 7 files in PASS/FAIL, and must not start the 180-minute heavy audit.

## Acceptance / limitations
Accept AFTER9 only on completed workflow success for the intended commit, successful log markers, validated ZIP digest and checkpoint SHA256, all eight independent blocks, 22 brute controls, five-field row diff and two negative rejection tests. Do not assert full-year Appendix-A canonical five-field oracle, cross-engine Soak, or Stage 55 PASS. Last completed remains Stage 54.
