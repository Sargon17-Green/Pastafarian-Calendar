# Registrum differentiale finale — Gradus 55

Hoc registrum matricem quinquaginta quinque categoriarum audit finalis claudit. Omnis comparatio computatoria fit inter monstrum C++ huius lineae et referentiam C++ test-only eiusdem lineae; nulla implementatio aliena adhibetur. Fasciculi probationum infra nominati in `audit_evidence/historical_run_logs/` servantur in involucro traditionis audit.

| Cat. | Res examinata | Evidentia | Status |
|---:|---|---|---|
| 1 | `c=t=FOUNDATION` | `stage_55_e2e_foundation.log` | PASS |
| 2 | dies ante et post Foundation | `stage_55_e2e_before.log`, `stage_55_e2e_after.log` | PASS |
| 3 | par trans Foundation | `stage_55_e2e_cross.log` | PASS |
| 4–25 | SAVE, subtractio, permutationes, directiones, selectiones breves/latae, portae et limites annorum | `stage_55_helper_differential_audit_tests.log` | PASS |
| 26 | target in porta aperiente | `stage_55_e2e_opening.log` | PASS |
| 27 | target primo die anni | `stage_55_e2e_first.log` | PASS |
| 28 | target in porta interna | `stage_55_e2e_internal_target.log` | PASS |
| 29 | target in porta claudente | `stage_55_e2e_closing.log` | PASS |
| 30 | calculationDay in porta interna | `stage_55_e2e_internal_calc.log` | PASS |
| 31–41 | numeri segmentorum/mensium, longitudines, textura, nomina distincta et occurrence-count | `stage_55_helper_differential_audit_tests.log` | PASS |
| 42 | annus 5000 | `stage_55_e2e_year5000.log` | PASS |
| 43 | annus 5001 | `stage_55_e2e_year5001.log` | PASS |
| 44 | annus 4999 | `stage_55_e2e_year4999.log` | PASS |
| 45 | annus 1 | `stage_55_far_year_1.log` cum `stage_55_far_segment_year_1_fixture.log` | PASS |
| 46 | annus 0 | `stage_55_far_year_0.log` cum `stage_55_far_segment_year_0_fixture.log` | PASS |
| 47 | annus -1 | `stage_55_far_year_minus1.log` cum `stage_55_far_segment_year_minus1_fixture.log` | PASS |
| 48–49 | cache frigidum/calidum | `stage_55_e2e_cache_warm.log`, `stage_55_state_history_worker.log` | PASS |
| 50 | duo calculationDay sub eodem numero anni | `stage_55_e2e_cache_fingerprint.log` | PASS |
| 51–55 | catalogi 17/47, praesentatio locale tantum, canonicalIndex contra collationem, prosa Neo-Latina | `stage_55_catalog_presentation_audit_tests.log` | PASS |

## Differentiae helper requisitae

- `stones`: `stage_09_patch_04_tests.log` et audit helper finalis.
- `hidden drops`: `stage_11_patch_05_tests.log`.
- `visible drops` et predecessores 1/3/7: `stage_13_patch_06_tests.log`, `stage_15_patch_07_tests.log`.
- `every bowl round`: `stage_19_patch_09_tests.log`, `stage_21_patch_10_tests.log`.
- `order at every drop`: `stage_17_patch_08_tests.log`, `stage_23_patch_11_tests.log`.
- `post-stir bowls`: `stage_23_patch_11_tests.log` et `stage_54_integration_tests.log`.
- `answer streams`: `stage_25_patch_12_tests.log`, `stage_27_patch_13_tests.log`, `stage_29_patch_14_tests.log`.
- `gate gaps`: `stage_31_patch_15_tests.log`.
- `year candidate sets`: `stage_33_patch_16_tests.log`, `stage_35_patch_17_tests.log`.
- `composition counts/unrank`: `stage_43_patch_21_tests.log`.
- `name ranks`: `stage_45_patch_22_tests.log`.
- `month-length counts/unrank`: `stage_47_patch_23_tests.log`.
- `weaving counts/unrank`: `stage_49_patch_24_tests.log`.
- `final five-field tuple`: `stage_54_integration_tests.log` et executabilia E2E Gradus 55.

Conclusio: `DIFFERENTIALE_FINALE=55/55 PASS`. Tres executabilia annorum remotissimorum in processibus separatis transierunt: annus 1 per 93.40 s, annus 0 per 91.59 s, annus -1 per 90.44 s.
