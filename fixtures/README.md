# Stage 1 fixture топтому

Күн: 2026-10-08

Бул каталог Befunge + Кыргызча линиясынын өзүнүн test-only нормативдик reference файлдарынан кайра чыгарылган fixture/expected-value маалыматтарын камтыйт.

## Булак

`REFERENCE_PRIMITIVE_FIXTURES.tsv` ичиндеги expected output башка программалоо тилиндеги Пастафари ишке ашыруусунан алынган эмес.

Ар бир саптагы output ошол эле сапта көрсөтүлгөн `reference/*.b98` программасын Funge-98 instruction-level development runner менен аткаруудан алынган. Runner календардык формулаларды билбейт; ал Funge-space, stack, arbitrary-precision cell, control flow жана I/O opcodes'ун гана аткарат.

QA учурунда runner'дин өзүндө 32-биттик Funge-space truncation катасы табылып, fixture түзүлгөнгө чейин оңдолду. Оңдоодон кийин arbitrary-precision клеткалар өзгөртүлбөй сакталат. Funge-98 `j` семантикасы расмий спецификация менен кайра текшерилди.

## Статус

Бул fixture топтомунун азыркы версиясы **CURRENT_NATIVE_REPLAY_PASS**.

2026-10-08 күнү PyFunge 0.5-rc2 менен native replay аткарылды. Азыркы эки fixture файлынын 48 + 20 = 68 сабынын баары native interpreter'де expected output менен дал келди. Runtime/smoke/dispatcher текшерүүлөрү менен кошо жалпы 84 программа аткарылып, 0 айырма калды.

Толук далил: `artifacts/stage-01/NATIVE_PYFUNGE_REPLAY.md`.

Ошондуктан бул файлдын болушу:

- fixture generation'дын башталганын жана primitive/integration катмарында кайра чыгарылган expected values бар экенин далилдейт;
- азыркы fixture corpus native replay'ден өткөнүн далилдейт;
- бирок reference али толук бүтө элек болгондуктан `STAGE_1_COMPLETE=YES` дегенди билдирбейт. Кийин кошулган fixture'лер кайра native replay'ден өтүүгө тийиш.

## Формат

TSV тилкелери:

1. `reference_file` — `reference/` астындагы Befunge файл;
2. `input_tokens` — `&` командалары окуй турган бүтүн сан токендери;
3. `expected_output_tokens` — `.` командалары чыгара турган сандык токендер.

Сандык output'тагы Funge-98 trailing space TSVге киргизилген эмес.
