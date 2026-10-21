# Stage 1 — aallartinneqartoq (ammasoq)

```text
STAGE=1
STATUS=IN_PROGRESS
PREVIOUS_STAGE=0
DEVELOPMENT_TRACK=CALENDAR_55_STAGES
SILICON_TRACK=S00_S20
SOURCE_LANGUAGE=Kalaallisut
SOURCE_LANGUAGE_QA=NOT_STARTED
SOURCE_LANGUAGE_CATALOG_FROZEN=NO
RTL_STAGE1_BOOTSTRAP=WRITTEN_UNVERIFIED
REFERENCE_ORACLE=PARTIAL_PLUS_FOUNDATION_SAUCE_TEST_ONLY
FULL_CALENDAR_ORACLE=NOT_IMPLEMENTED
SIMULATOR_LOCAL_AVAILABLE=NO
GITHUB_ACTIONS_RUN_OBSERVED=0
FOUNDATION_SAUCE_SIMULATION_STATUS=NOT_EXECUTED
STAGE1_PASS=NO
```

## Atorneqartut

- `rtl/pcal_stage1_bootstrap.sv`: request/ready, register, context, bounded dispatcher aamma observation.
- `tests/pcal_stage1_oracle_pkg.sv`: test-only SAVE/dayCount/distance/sum/direction, SystemVerilog-imi allataq.
- `tests/tb_stage1.sv`: initial testbench; actual PASS aatsaat simulator-imi uppernarsarneqarsinnaavoq.
- `tests/tb_sauce_foundation.sv`: test-only 7 hidden / 46 visible / 6 bowls / 12 saved-sum rounds and normative intermediate witnesses; not yet executed.
- `catalog/catalog_review_queue.csv`: 64 canonical slots: 3 sourced lexical research candidates, 61 empty, 0 native approvals.
- `.github/workflows/stage1-systemverilog.yml`: GitHub Actions iverilog + vvp simulation.
- `SOURCE_LANGUAGE_CATALOG.md`: 17 + 47 atit suli amigaataapput.

## Piumasaqaatit suli amigaataasut

- 64 canonical atit Kalaallisut-imi native review, transliteration policy, immutability SHA.
- Full independent SystemVerilog calendar oracle, fixtures and all canonical witnesses.
- CI test run PASS and independent code review.
- Stage 1 completion certificate only after all above evidence exists.

No stage 2 discovery or patch was opened.

## 2026-10-21 — Suliniutip ingerlaqqinnera

- `tests/tb_stage1_reset.sv`: request interrupted by asynchronous reset and another reset during completion; code written, not simulated.
- `scripts/check_catalog_structure.sh`: 17 cutlet + 47 month contiguous index check; data structure separately checked in the connected GitHub record (64 rows, 8 columns each).
- Three sourced proposals (not native-approved): `terianniaq`, `kuuk`, `ulloriaq`.
- Temporary mathematical inspection of the published Foundation sauce checkpoint reproduced all seven hidden drops' boundary witnesses, drops 1 and 46, orderAt46 and six final bowls. It did **not** execute the SystemVerilog source.
- CI: no branch workflow runs observed at this checkpoint. Stage 1 remains open; Stage 2 remains closed.
