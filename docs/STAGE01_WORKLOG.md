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
RTL_STAGE1_BOOTSTRAP=IMPLEMENTED_UNVERIFIED
REFERENCE_ORACLE=PARTIAL_ONLY
FULL_CALENDAR_ORACLE=NOT_IMPLEMENTED
SIMULATOR_LOCAL_AVAILABLE=NO
STAGE1_PASS=NO
```

## Atorneqartut

- `rtl/pcal_stage1_bootstrap.sv`: request/ready, register, context, bounded dispatcher aamma observation.
- `tests/pcal_stage1_oracle_pkg.sv`: test-only SAVE/dayCount/distance/sum/direction, SystemVerilog-imi allataq.
- `tests/tb_stage1.sv`: initial testbench; actual PASS aatsaat simulator-imi uppernarsarneqarsinnaavoq.
- `.github/workflows/stage1-systemverilog.yml`: GitHub Actions iverilog + vvp simulation.
- `SOURCE_LANGUAGE_CATALOG.md`: 17 + 47 atit suli amigaataapput.

## Piumasaqaatit suli amigaataasut

- 64 canonical atit Kalaallisut-imi native review, transliteration policy, immutability SHA.
- Full independent SystemVerilog calendar oracle, fixtures and all canonical witnesses.
- CI test run PASS and independent code review.
- Stage 1 completion certificate only after all above evidence exists.

No stage 2 discovery or patch was opened.
