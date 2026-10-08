# Stage 1 — семантикалык абалдын ээлиги / Mutable Funge-space ownership

**Абал: АУДИТ АЧЫК.** Бул документ 2026-10-08 күнү азыркы өндүрүштүк кодго ылайык жаңыланды.
CURRENT_STAGE=1; LAST_COMPLETED_STAGE=0. Бул жерде акыркы толук PASS жарыяланбайт.

## Эски аудиттин колдонулуу чеги

2026-10-07деги аудит баштапкы бейтарап Bootstrap shell'ге гана тиешелүү болчу.
Анда p/g жок деген билдирүү жаңы өндүрүштүк жол үчүн **жалган**:
src/day_count.b98, src/save.b98, src/interleaved_day_save.b98 жана
src/interleaved_work_counts.b98 азыр чыныгы эки өлчөмдүү Funge-space
жана аткарылып жаткан executable gate'терди p/g аркылуу динамикалык өзгөртөт.
Ошондуктан эски SEMANTIC_STATE_OWNER_VALIDATED=YES белгисин
жаңы production'га жайылтууга болбойт.

## Негизги абал жана менчик чек арасы

- Ар бир жаңы pyfunge процесси өзүнүн IP'син, стегин,
  Funge-space'ин жана киргизүү агымын алат. Процесс аралык глобалдык
  реестр, shared heap же файлга жазылган семантикалык cache production
  келишиминде каралган эмес.
- Runtime code overwrite — ошол invocation'дун Funge-space клеткасына
  p аркылуу берилген семантикалык өзгөртүү; аны жөн гана debug output
  катары эсептөөгө болбойт.
- --no-concurrent --no-filesystem --disable-fprint native QA режими
  тышкы файлдык механизмди, fingerprint'ти жана кошумча IP'лерди
  атайылап чектейт. Бул башка runtime үчүн кепилдик эмес.
- Source .b98 GitHub'та өзгөрүүсүз сакталат; бир process ичиндеги
  self-modification Git blob'ун өзгөртүү эмес.
- Бир interpreter instance ичинде Funge-space кайра колдонулса,
  жүктөө/тазалоо өзүнчө далилдениши керек. Fresh-process QA
  мындай reuse үчүн далил боло албайт.
- reference/ тесттик эталону өзүнүн өзүнчө scratch state'ин колдонот;
  ал production аткаруу жолуна чакырылбайт.

## Жаңы көз карандысыз QA

QA branch: qa-befunge98-stage1-order-isolation-20261008
(канондук repository гана).

- qa/stage1_native_process_isolation.py: native Befunge эталон менен
  салыштыруу, ар түрдүү input тартибинде fresh process replay жана
  эки concurrent process pair.
- qa/sitecustomize.py: PyFunge чыныгы Program.execute_step
  instrumentation; IP координаттары, opcode, stack depth, p алдындагы
  жана андан кийинки Funge-space маанилери. Test-only.
- qa/stage1_native_write_audit.py: native p алдында жана кийинки
  маанини так салыштыруу; жазылган жаңы opcode кийин аткарылган
  учурларды саноо.
- Native workflow: .github/workflows/befunge-kyrgyz-stage1-regression.yml.
  Native QA SUCCESS чыкмайынча булар далил эмес, сыноо талаптары.

## Калган кабыл алуу боштуктары

1. Native CI'ден жаңы isolation жана write audit SUCCESS алуу.
2. p/g write-coordinate whitelist жана executable-cell version
   lifecycle'ын көп valid/invalid input боюнча бекитүү.
3. Бир interpreter instance'ин кайра колдонуу, толук reset,
   state ownership жана reentrancy'ни сыноо.
4. Бардык Stage 1 reference corpus жана геометриянын кабыл алуусун жабуу.

**Корутунду:** азыр толук семантикалык ээлик үчүн
SEMANTIC_STATE_OWNER_VALIDATED=NO_FINAL_AUDIT гана туура;
Stage 1 OPEN бойдон калат.
