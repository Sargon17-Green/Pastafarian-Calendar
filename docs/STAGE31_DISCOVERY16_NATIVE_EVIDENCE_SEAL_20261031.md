# Stage31 / Discovery16 — evidence-only native seal candidate

Branch `PowerShell+Tagalog`. Implementing SHA `b1a5769c91a76966d552b0eafb8331e3e9784a64`. [Completed run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203036226) status completed/success; all five jobs passed: predecessor Windows PowerShell 5.1 124542480527, verify 124542480546, ordinal 124542480511, extension 124542480411, normative year 5000 124542480598. These results are for the implementing SHA, NOT the new seal commit.

| Native suite | Rows | Passing assertions | Failed |
| --- | ---: | ---: | ---: |
| Predecessor Stage01–30 | — | 664 | 0 |
| Stage31 ordinal First/Step | 50 | 309 | 0 |
| Stage31 ordinal extension | 72 | 441 | 0 |
| Stage31 normative year 5000 | 12 | 85 | 0 |

Stage23 finalizer idempotency twice: original and both resulting SHA256 values `C98CD8E4CEC1CD7D9CE09DB6C43E4F55CED89F7D9C316A3ED2B45C12545E0A51` identical, RESULT=PASS. Verify successful; Stage26 historical expected-red unchanged.

## Observed year-boundary records

The independent normative calendar defines year 5000 with `OpenGateDay < target <= CloseGateDay`. Its open ordinal is **-15057703** and close ordinal **-15053459**: **4244** days; calculation foundation day **-15055671**. These are ordinal days, not civil/Gregorian dates.

| Boundary target | Ordinal day | Seal1 First | Step | Seal2 First | Step |
| --- | ---: | ---: | ---: | ---: | ---: |
| OPEN_MINUS_ONE | -15057704 | 76266340920308200490055191911855398080 | +1 | 84800067940526926493922580788507622754 | -1 |
| OPEN | -15057703 | 58410020366340564589937630166767255430 | -1 | 6086632766952805103303992637466697565 | -1 |
| OPEN_PLUS_ONE | -15057702 | 65050096343968903854972429925749014641 | -1 | 104511211683448320051606037266191650818 | +1 |
| CLOSE_MINUS_ONE | -15053460 | 99725029429649770873545545129828659007 | -1 | 104181584379041736460191170225208925534 | +1 |
| CLOSE | -15053459 | 133619075169271386857618844411670844182 | +1 | 141105229101828615355029793403215013220 | -1 |
| CLOSE_PLUS_ONE | -15053458 | 33919270196152387547247467414017193108 | +1 | 4949813284962496774684112413794622561 | -1 |

The independent `NormativeScroll` First/Step oracle agreed exactly with the implementation on every boundary observation. Boundary: 12 rows, First distinct=12, joint distinct=12, repeat=0; positive=5, negative=7; 85/85 assertions. Total Stage31: 134 deliberately selected rows, 835/835 assertions (309+441+85), zero failures. This does NOT establish uniformity, independence, all-date five-component correctness or Gregorian mapping.

## Compatibility and acceptance

The historic `STAGE30_SEAL_COMMIT_NATIVE_RECHECK=PENDING` marker is stale: Stage30 exact-seal [run 41193007152](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193007152) completed/success on `8d78359ae4a40f69bcd2054a4dcbcd44f7d528b6`. This candidate records it as PASS and changes metadata plus only the regression/finalizer/CI acceptance gates to recognize LAST_COMPLETED_STAGE=31, not production or reference oracle. Historical expected-red is preserved.

**New seal commit still needs its OWN completed/success exact-SHA run**: predecessor/native, all three independent Stage31 suites, finalizer twice and verify. `STAGE31_SEAL_COMMIT_NATIVE_RECHECK=PENDING` is intentional until log evidence. If red, repair the proved failing gate only. Do not merge main.
