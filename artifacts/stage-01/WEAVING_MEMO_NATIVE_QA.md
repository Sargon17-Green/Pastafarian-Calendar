# Stage 1 — Weaving'дин эскертүү клеткалары боюнча native QA

Күнү: 2026-10-08.

Бул оңдоо **test-only** Befunge-98 эталонуна таандык; production spaghetti архитектурасын түздөбөйт жана ага альтернативдүү implementation бербейт.

## Көйгөй

Funge-space'теги мурда жазылбаган `g` дареги нөл эмес: көп учурда ASCII боштук `32` кайтарат. Эски weaving dynamic-programming эталону нөл менен башталган memo presence flag бар деп ойлоп, даяр эмес маанини даяр катары кабыл алган.

## Оңдоо

`reference/count_weavings.b98` жана `reference/unrank_weaving.b98` файлдарында экиден узундугу өзгөрбөгөн memo presence guard оңдолду. Instruction координаттары жана узун секирүү чекиттери өзгөргөн жок. Башка программалоо тилине эсеп өткөрүлгөн жок.

- `count_weavings.b98` blob `d57ef8da12e7cae7e62153407214f9f903eca280`.
- `unrank_weaving.b98` blob `6caadb311e31cf6f498dc7112f323900034fae96`.
- Native PyFunge 0.5-rc2 replay: **104/104 PASS**, нөл failure.
- Replay: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37773017884

Native иштетүүдөн тандалган ырастоолор:

- `count_weavings 3 3 3 3` → `71`;
- `count_weavings 3 4 4 4` → `1301`;
- `unrank_weaving 3 4 4 4 1` → `1 1 1 1 2 2 2 2 3 3 3 3`;
- `unrank_weaving 3 4 4 4 1301` → `1 2 3 3 3 2 2 1 1 1 2 3`;
- Year 5000 түзүмүнүн интеграциялык fixture'и PASS.

Чоң `3×4×4×4` учурлары PyFunge ичинде орточо 34–35 секундага жеткен. Демек функционалдык тууралык далилденген чакан топтом үчүн ылдамдыкка байланышкан маселе дагы бар.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`. Толук Appendix A reference, production interleaving жана all-stage QA али далилдене элек.
