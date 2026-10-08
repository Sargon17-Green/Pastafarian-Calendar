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


## 2026-10-08 — native g-read жана same-interpreter ownership

Test-only qa/sitecustomize.py эми ар бир аткарылган g opcode боюнча
READ_BEFORE жана READ_AFTER окуясын жазат: клетканын дареги, Funge-space
мааниси жана аткаруудан кийинки stack үстүндөгү сан. QAнын
qa/stage1_native_write_audit.py текшерүүчүсү ар бир native g жана p
операциясын бирден жуптап, жөнөкөй артефакттагы жоголгон жана
бузулган окуяларды четке кагат.

(5,0) арифметикалык handoff'тон кийин сканердин жаңы код
клеткасына, scratch клеткасына же кириш көпүрөсүнө жасалган
IP execution, g read, p write = FAIL. Test-only
qa/stage1_native_trace_auditor_selftest.py синтетикалык окуяларды
текшерет (жети атайылап бузулган трасса четке кагылууга тийиш).
Бул native interpreter PASS эмес, аудитордун fail-closed
жөндөмдүүлүгү үчүн гана selftest.

Өз алдынча Funge instruction simulator эски жана интеграцияланган
кандидатты 18 input менен салыштырды: 18/18 output паритети,
3713 кошулган executable source cell боюнча арифметикалык
handoff'тон кийин 0 IP execution, 0 g read, 0 p write. Коддогу
qa/stage1_full_execution_geometry_sim.py эми ошол коргонуу
шартын автоматтык кармайт. Бул 18 testcase гана,
бардык мүмкүн input'тардын далили эмес.

PyFunge 0.5-rc2нин документтелген Program, BufferedPlatform,
Program.execute_step интерфейси менен
qa/stage1_native_same_interpreter_isolation.py кошулду:
24 жаңы Program объекти бир Python процессте ырааттуу
иштетилет жана эки жуп өзүнчө Program объекттери
кадам сайын interleave кылынат. Native CLI менен
чыгарылышы салыштырылат; Funge-space identity
жана мурунку Program snapshot'ы өзгөрбөгөнү талап кылынат.

Кошумча native QA RESULT азырынча ырастала элек.
Дал ошол эле Program объектин reset кылып кайра колдонуу
дагы өзүнчө ачык талап, fresh Program / same-process
reentrancy муну алмаштырбайт. LAST_COMPLETED_STAGE=0.


## 2026-10-08 — Native ownership replay PASS, QA-only source promotion

Бул жаңы checkpoint жогорудагы мурунку "Native текшерилген эмес"
деген билдирүүлөрдү алмаштырат, бирок ошол тарыхый QA белгилерин
өчүрбөйт.

Native run 37831929988 (HEAD cc02c86d75b1fd5aa3598e25a04a64cdf33d5ade):
- \`native-write-audit\` PASS: жупталган бардык p writes жана g reads,
  мыйзамдуу executable gate replay (10 valid, 4 invalid), changed
  executable gates (3 valid, 3 invalid), scanner менен байланышкан
  арифметикалык Funge-space collision аныкталган жок;
- 26,708 valid жана 12,194 invalid **native post-handoff events**
  эски parser менен жаңыланган parser ортосунда так дал келди;
- \`native-same-interpreter-isolation\` PASS: 24 fresh Program объект
  бир Python process'те, 2 жуп stepwise interleaving,
  эски completed anchor Funge-space snapshots өзгөргөн жок.

Эми QA branch \`src/interleaved_work_counts.b98\`
exact native-qualified scanner blob
\`e2b39b066d1d47bcb8ce4f234b093fca94cb21d1\` колдонот.
Канондук branch'тагы original source өзгөрбөйт,
ал эми pre-lexical clone QAда сакталат.

**Ачык далил:** жаңы source promotion'дон кийин алты CI job кайра
толук PASS керек. Так ошол эле \`Program\` объектин контролдуу
reset кылып кайра иштетүүнүн state neutrality далили жок.
Ошондуктан семантикалык ownership'ти Stage 1 боюнча жабык деп
жариялабагыла. LAST_COMPLETED_STAGE=0; Stage 2 жок.


## 2026-10-08 — QA source Native 6/6 PASS, exact-object reset still open

GitHub Actions native run 37833658868, SHA
82fc82929dc301e34041c750587aee7d6b58207f:
алтынын алтысы PASS. Эми \`src/interleaved_work_counts.b98\`
lexical input терс белгини кабыл албайт. Негизги 421 native regression,
123 native oracle-integrated cases, 43+48 lexical parser cases,
8 production lexical rejection case, 10/4 кийин аткарылган
self-modifying gate writes жана г/п/IP трассалары кайра текшерилди.
Бир interpreter ичинде 24 fresh Program жана 2 interleaved pair да PASS.

Ачык болгон өзүнчө ownership милдети: **так ошол эле Program объектти**
кайра колдонуу. Жаңы QA тест:
\`qa/stage1_native_same_program_reset.py\` 16 жолу ошол эле
Program identity менен иштейт, ар бир жолу Funge-space'ти, кириш/чыгыш
платформасын жана IP'ти өзүнчө баштапкы абалга келтирип,
натыйжаны көз карандысыз native PyFunge CLI менен салыштырат.
Эски/жаңы source ортосунда алмашып, \`p\` өзгөрткөн мурунку
Funge-space кийинкиде тийилбегенин текшерет. Бул \`load_code\`
гана аткарып, мурунку өзгөргөн space'ти кайра колдонууга уруксат эмес.

Жетинчи Native job жаңы commit үчүн кошулду, **PASS далили
азырынча жок**. Мындан тышкары FULL_FUNCTIONAL_QA жана
GEOMETRIC_SPAGHETTI_QA мурдагыдай ачык. Stage 1 жабык эмес;
канондук branch жана main өзгөргөн жок; Stage 2 башталган жок.
