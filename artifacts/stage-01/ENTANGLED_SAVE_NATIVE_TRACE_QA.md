# Stage 1 — SAVE чыныгы Befunge-98 аткаруу далили

Күн: 2026-10-08.

Бул QA документациясы production'ду жөнөкөйлөтүп кайра жаза турган кодду же куруучу программаны камтыбайт. `reference/save.b98` test-only эталону production семантикасына көз каранды эмес.

## Математикалык native далил

- Production: `src/save.b98`; blob `dd6f10aa196e3a9523ee786e4ba41a91f303d199`; canonical commit `b7e5b885a8940db015212e53277e46a392ac2c87`.
- Максаттуу механизм: PyFunge 0.5-rc2, `-v98 -d2 --disable-fprint --no-concurrent --no-filesystem`.
- `SAVE` боюнча independent native Befunge reference differential: **42/42 PASS**. `M=2^127-1` чеги, `M±1`, `2M`, туура эмес sign, отрицателдик нөл жана жүздөн ашык ондук цифраларды камтыйт.
- Native функционалдык QA: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37781561685

## Чыныгы instruction pointer аткаруу жолу

Instrumented PyFunge аркылуу IP координаттары, delta, opcode жана stack depth чогултулду; executable gate cell жазуулары кийин ушул эле клетка жаңы opcode менен иштетилгендиги аркылуу көз карандысыз текшерилди.

- Трассанын чийки TSV, SVG жана metrics artifact: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37781953875

| Native ченөө | Valid, `1 170141183460469231731687303715884105728` | Invalid, `2 10` |
|---|---:|---:|
| Instruction steps | 46,416 | 5,071 |
| Unique coordinates | 3,729 | 3,713 |
| Repeated coordinate visits | 42,687 | 1,358 |
| Executed `p` | 167 | 19 |
| Writes to executable gate | 41 | 4 |
| New gate opcode subsequently executed | 41 | 4 |
| Executed `x` | 1,743 | 189 |
| Four cardinal directions seen | YES | YES |

Натыйжа чын эле Funge-space ар кандай клеткалар аркылуу жүргөн, мурдагы клеткаларга кайра келген жана runtime өзгөртүлгөн executable команда кийин аткарылган.

## Далилдин чеги

Бул толук календардык алгоритмди же бардык 55 этапты бүттү дегенди билдирбейт. Бир процесс арасындагы state reuse, IP concurrency, stack-stack жана толук reference completion өзүнчө сыналат. Stage 1 бүтө элек; `LAST_COMPLETED_STAGE=0`, Stage 2 башталган жок.
