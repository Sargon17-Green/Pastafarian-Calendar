# la .pastafarian. detri — Java joi la .lojban.

ni'o ti du lo pamoi stadi be lo cnino farvi linji. lo farvi linji cu co'a fi lo kunti stura gi'e na se zbasu fi lo drata farvi linji. ro lo se benji samselpla cu se ciska fi la Java po'o. ro lo remna finti se ciska pe lo ti farvi linji cu jbobau.

## lo pamoi stadi

lo pamoi stadi cu zbasu lo se pilno ciste stura .e lo cipra ciste .e lo `NormativeOracle` poi se pilno lo cipra po'o .e lo `SourceLanguageCatalog` .e lo stodi ke se benji datni joi benji jatna joi cipra jatna joi nabmi marbi joi te merli vreji ciste.

lo `NormativeOracle` cu se zbasu fi lo narmanci te javni pe lo pagbu A po'o. lo se pilno ciste na tcidu ra gi'e na cpacu lo ra jalge. no drata farvi linji cu se pilno lo nu zbasu lo te javni .a lo cipra datni .a lo se pacna jalge.

## lo `SourceLanguageCatalog`

lo `SourceLanguageCatalog` cu se tcita la `1.0.0-stage01` gi'e stodi ca lo fanmo be lo pamoi stadi. lo 17 kecti cmene .e lo 47 masti cmene cu se judri lo `canonicalIndex` poi cfari li pa gi'e zenba pa. lo `canonicalIndex` cu seljavni lo ro cmicu'a .e lo ro te porsi judri zbasu .e lo ro te porsi judri facki .e lo se smuni judri. lo jbobau se ciska cu se facki fi lo `canonicalIndex` ca lo fanmo se jalge po'o.

lo valsi poi se smuni cu se fanva lo smuni. mu'a `maxri` cu smuni lo maxri, `lorxu` cu smuni lo lorxu, `xasli` cu smuni lo xasli, `silna` cu smuni lo silna, `perli` cu smuni lo perli, gi'e `rijno` cu smuni lo rijno. lo se cmene tcadu .a lo gugde .a lo finti valsi cu se zbasu lo cmevla. lo se na facki se valsi cu se ciska lo jbobau se smuni valsi tanru .a lo se cmene klesi.

lo cmevla te zbasu cu stodi: lo sance cu se mapti lo jbobau sance; `sh` se basti `c`; lo xarci xabju sance poi simsa `kh` se basti `x`; lo voksa lerfu cu se ralte; lo cmene valsi cu fanmo lo zunsna. va'o lo nu lo se cmene cu fanmo lo voksa lerfu kei `s` se jmina lo nu fanmo lo zunsna. lo ti te javni cu stodi ba lo pamoi stadi.

lo balvi se fanva cu fanva lo jbobau se ciska po'o. ri na se pilno lo nu cmicu'a .a lo nu zbasu lo te porsi judri .a lo nu facki fi lo te porsi judri .a lo nu zbasu lo se smuni judri.

lo mulno cmene liste cu zvati `SOURCE_LANGUAGE_CATALOG.md`.

## lo zbasu .e lo cipra

ko fi lo stura rinka lo `run_stage01_tests.sh` lo nu se benji. lo drani se jalge cu du:

```text
STAGE_01_PASS checks=<N>
```

lo zbasu .e lo cipra cu pilno `javac` .e `java`. no drata samselpla bangu cu se pilno lo te javni .a lo cipra .a lo datni zbasu.

## lo se pilno ciste jimte

lo se pilno ciste ca lo pamoi stadi cu vasru `MonsterContext`, `MonsterDispatcher`, `MonsterValidationManager`, `MonsterErrorBoundary`, `MonsterMetrics`, .e `MonsterManager`. no balvi se srana pluta cu se jmina ca ti.

lo `MonsterContext` cu se zbasu pa mai ro se benji. lo te merli vreji .e lo nabmi catlu vreji cu na se tcidu fi lo narmanci te jdice. lo se smuni datni poi se jmina ca ti cu se ponse lo sama se benji po'o.

## lo remoi stadi — lo prula'i namcu javni

ni'o lo `MonsterArithmetic` cu se zbasu fi la Java po'o. ri se pilno lo `BigInteger` tezu'e lo nu se jarco lo mutce barda namcu. ri vasru lo detri pamoi poi se jicmu lo `FOUNDATION_DAY`, lo frinu boi mod javni, lo `save`, lo `wrap1`, lo `ceilDiv`, .e lo `WorkCounts`.

ni'o lo remoi stadi ca se zbasu gi'e na se tcita lo mulno stadi. lo `Stage02Tests` cu cipra lo cnino te javni gi'e srana lo `NormativeOracle` poi vasru lo cipra po'o. ko benji:
```sh
sh run_stage01_tests.sh
sh run_stage02_tests.sh
```
ni'o lo remoi stadi cu nitcu lo balvi zbasu be lo slabu narmanci se jicmu. lo `LAST_COMPLETED_STAGE` cu du li pa.

## lo remoi stadi — lo rokci .e lo djacu drata

ni'o lo `MonsterSauceDrops` cu zbasu lo 46 rokci porsi .e lo 7 mipri djacu drata .e lo 46 se viska djacu drata. lo se pilno stura cu pilno lo stodi `BigInteger` .e lo se sruri papri kopij. lo `prepare` cu cpacu lo se benji detri remei gi'e benji lo cnino `Drops` se ralte.

ni'o lo `Stage02DropsTests` cu cipra ro rokci se namcu .e lo 7 mipri djacu drata .e lo 46 se viska djacu drata gi'e simsa lo `NormativeOracle` poi cipra po'o. ri cipra lo mutce barda namcu .e lo se benji se jorne .e lo frica se benji se ralte .e lo mutce so'i se benji ca lo pa mentu.

```sh
sh run_stage02_drops_tests.sh
```

ni'o lo remoi stadi na se mulno. lo djacu bliku .e lo selcu'a javni cu nitcu lo balvi zbasu.

## lo remoi stadi — lo xa djacu bliku

ni'o lo `MonsterSauceBowls` cu zbasu lo xa djacu bliku .e lo 46 djacu drata porsi .e lo 12 se jarco muvdu rimni. lo `unrankPermutation` cu zbasu lo lexikografike porsi fi lo 720 se cuxna. lo `ask` .e lo `answerAt` cu zbasu lo se cuxna datni.

ni'o lo `Stage02BowlsTests` cu cipra lo ro 720 se cuxna porsi .e lo mulno djacu bliku .e lo selcuxna .e lo detri farvi .e lo se ralte mebyjavni. ko benji `sh run_stage02_bowls_tests.sh`. lo `NormativeOracle` cu vasru lo cipra po'o. lo `LAST_COMPLETED_STAGE` cu du li pa.

## lo remoi stadi — lo se benji be lo barda ciste

ni'o lo `MonsterManager.runSauce` cu benji lo cnino `MonsterContext` fi ro se benji. lo `MonsterDispatcher` cu pilno lo `MonsterSauceBowls` tezu'e lo nu benji lo `MonsterEvaluation` poi stodi gi'e na se galfi lo branch trace .e lo metrics.

ni'o lo `MonsterEvaluation.choose` cu pilno lo `MonsterSelectors` tezu'e lo nu cpacu lo ranki fi lo djacu bliku .e lo seal .e lo se cuxna namcu. lo `Stage02IntegrationTests` cu cipra lo mutce so'i se benji .e lo narmanci jalge .e lo se brivla frica. ko benji `sh run_stage02_integration_tests.sh`. lo remoi stadi cu na se mulno.

## lo se cipra farvi pagbu pe lo remoi stadi

ni'o lo `MonsterSelectors` cu se zbasu gi'e srana lo `chooseShort` .e lo `chooseWide` .e lo `choose`. ri pilno lo pamoi se curmi ranki be lo se cuxna se jimte .e lo barda namcu. ko benji `sh run_stage02_selectors_tests.sh`.

ni'o lo `MonsterManager.runSauce` cu benji lo cnino `MonsterEvaluation` fi ro se benji. lo `MonsterEvaluation` cu ralte lo stodi `branchTrace` .e lo `metrics` .e lo `SauceResult`. lo `choose` cu cuxna lo ranki fi lo djacu bliku .e lo seal .e lo se cuxna se namcu. ko benji `sh run_stage02_integration_tests.sh`.

ni'o lo remoi stadi cu na se mulno. lo balvi pagbu cu nitcu lo selcmima porsi .e lo vorme .e lo nanca .e lo kecti .e lo masti .e lo mulno detri jalge.

## lo remoi stadi — lo selcmima porsi

ni'o lo `MonsterFamilies` cu zbasu lo binomio namcu .e lo frica cmene porsi .e lo se jimte so'i pagbu kompozicio .e lo kecti pagbu kompozicio poi nitcu lo vorme .e lo masti se jorne porsi. lo `BigInteger` cu rinka lo nu no namcu bancu jimte cu pagre. lo `BoundedCompositionFamily` cu pilno lo drata platu perma'i pe lo namcu se jimte. lo `CutletPartitionFamily` cu pilno lo binomio frinu fi lo nu jmina lo jimte vorme.

ni'o lo `Stage02FamiliesTests` cu cipra lo tcadu barda cmene .e lo mutce barda masti .e lo kecti .e lo se jorne porsi. ko benji `sh run_stage02_families_tests.sh`. lo narmanci `NormativeOracle` cu cipra po'o. lo remoi stadi na se mulno.

## lo remoi stadi — lo vorme

ni'o lo `MonsterGates` cu zbasu lo se namcu vorme fi lo se benji `MonsterSauceBowls`. ro se jicmu `MonsterGates` cu ralte lo pa ke cnino vorme liste gi'e ralte lo barda namcu be lo nu vorme. lo se sisku cu pilno lo binario sisku fi lo se pagbu vorme. lo `snapshot` cu cpacu lo na se galfi datni papri.

ni'o lo `Stage02GateTests` cu cipra lo ni'o se sruri .e lo nu minra lo cizyjavni. ko benji `sh run_stage02_gates_tests.sh`. lo remoi stadi cu na mulno.

## lo remoi stadi — lo nanca ciste

ni'o lo `MonsterYears` cu zbasu lo pamoi nanca poi se namcu li 5000 .e lo balvi nanca .e lo purci nanca. lo `MonsterGates` cu vasru lo te jicmu vorme. lo nu cuxna lo nanca cu pilno lo te jicmu lenku .e lo lo ranki fi lo `MonsterSelectors`.

ni'o lo `Stage02YearTests` cu cipra lo nanca li 5000 .e lo go'i co'a nanca tezu'e lo nu lo detri cu se tolcri. ko benji `sh run_stage02_years_tests.sh`. lo remoi stadi cu na mulno.

## lo remoi stadi — lo kecti .e lo masti platu

ni'o lo `MonsterYearBlueprint` cu se zbasu fi la Java gi'e cuxna lo kecti se namcu .e lo kecti pagbu .e lo kecti cmene .e lo masti se namcu .e lo masti se jimte .e lo masti cmene. lo na se galfi `cutletPartition` .e lo `monthLengths` cu se cpacu fi lo kopij. lo `cutletAt` cu facki lo kecti fi lo se cuxna detri.

ni'o lo masti se jorne porsi cu na se zbasu ca lo platu stadi. lo `MonsterYearBlueprint` na se smuni lo mulno `YearStructure`. ko benji `sh run_stage02_blueprint_tests.sh` tezu'e lo nu cipra lo platu. lo remoi stadi cu na mulno.

## lo kecti detri poi na mulno lo masti detri

ni'o lo `MonsterCutletCalendar.convert` cu zbasu lo nanca .e lo kecti cmene .e lo kecti se namcu .e lo djedi be lo kecti, sepi'o lo `MonsterYears` .e lo `MonsterYearBlueprint`. lo `MonsterManager.cutletDate` cu zbasu lo cnino se benji. ko benji `sh run_stage02_cutlet_date_tests.sh` tezu'e lo nu cipra lo kecti detri .e lo `NormativeOracle`.

ni'o lo ti jalge na vasru lo masti detri .i lo `MonsterCutletCalendar` na smuni lo mulno kalendri se detri. lo masti se jorne javni .e lo mulno detri cu nitcu lo balvi zbasu.

## lo masti se jorne porsi cipra

ni'o lo `Stage02WeavingDomainTests` cu cipra lo masti se jorne porsi poi masti cu vasru vo .a za'u vo djedi, gi'e srana lo narmanci `NormativeOracle`. lo cipra cu pilno lo rangaji `4` .e `123` tezu'e lo nu cipra lo jimte masti. ko benji `sh run_stage02_weaving_domain_tests.sh`.

ni'o lo ti cipra na se du lo mulno se benji kalendri. lo masti se jorne porsi pe lo mutce so'i masti .e lo mutce so'i djedi cu nitcu lo balvi frica cipra .e lo nu stodi lo memori .e lo temci.

## lo masti detri te stika

ni'o lo `MonsterMonthIndex` cu facki lo masti se namcu .e lo detri be lo masti .e lo stodi cmene fi lo se benji masti porsi. ri verifai lo to'e se snada porsi .e lo masti namcu .e lo pagbu se namcu .e lo te porsi be lo cfari .e lo fanmo. lo se pilno `weaving` cu se benji fi lo zunle ciste gi'e na se zbasu ti. lo `Stage02MonthIndexTests` cu cipra lo te facki fa'u lo narmanci `WeavingFamily` .e lo mulno nanca papri. ko benji `sh run_stage02_month_index_tests.sh`.

## lo detri jalge fi lo se benji porsi

ni'o lo `MonsterCalendarResolver` cu benji lo detri se namcu be lo nanca .e lo kecti .e lo masti va'o lo nu lo `selectedWeaving` cu se benji. lo `ResolvedYear` cu cilre lo nanca prenu datni pa mai gi'e facki lo se srana detri so'i roi. lo `selectedWeaving` cu se nitcu .i ti na se cuxna ra .i lo ti ciste na se mulno narmanci detri fanva. ko benji `sh run_stage02_calendar_resolver_tests.sh`.

## lo balvi nitcu: lo mulno nanca se jorne

ni'o lo `MonsterCalendarResolver` cu se benji lo narmanci `selectedWeaving` fi lo drata ciste. lo nu se cuxna lo drani `selectedWeaving` fi lo `MonsterSelectors` .e lo `MonsterFamilies.WeavingFamily` cu se nitcu lo mutce barda matematik cipra fi lo mulno nanca. lo `WeavingFamily` cu pilno lo se sruri se banzu te jicmu `Map` .i lo ro 47 masti .e lo barda namcu be lo detri cu kakne lo nu mutce zenba lo se sruri datni se namcu. lo ti jimte na se jdice lo ka lo narmanci javni cu drani .i no mulno stadi tcita cu se jmina ca lo se cuxna ciste na se zbasu.

## lo masti porsi be lo pamoi .e lo fanmo

ni'o lo `MonsterWeavingEndpointDP` cu namcu lo drani porsi fi lo `BigInteger` .i lo pamoi detri .e lo fanmo detri be lo fanmo masti cu se ralte fi lo te jicmu porsi .i lo `EndpointTable` cu ralte lo drani trene judri po'o. lo `terminalInsertTotal` cu jmina lo binomio namcu fi lo fanmo masti gi'e na zbasu lo fanmo endpoint te jicmu.

ni'o lo `unrank1` cu cuxna lo porsi fi lo ranki be lo pamoi .i lo `rank1` cu xruti lo ranki fi lo drani porsi .i lo cipra cu se snada lo ka `rank1(unrank1(r))=r` .i lo `NormativeOracle.WeavingFamily` cu se pilno po'o lo cipra.

## lo cuxna be lo narmanci masti

ni'o lo `MonsterCanonicalWeaving` cu cuxna lo drani masti porsi fi lo vo moi kabri .e lo 32 moi tcita be lo `MonsterSauceBowls`. lo `MonsterSelectors` cu te cuxna lo ranki fi lo traji barda `BigInteger` .i lo `MonsterCalendarResolver` cu facki lo detri be lo nanca .e lo kecti .e lo masti ca lo nu lo se cuxna `weaving` cu se benji.

## lo 2026-10-11 jimte

ni'o lo `MonsterWeavingEndpointDP.MAX_COUNT_DAYS` cu du li 2048 .i lo `MonsterWeavingEndpointDP.MAX_UNRANK_DAYS` cu du li 384 .i lo `rank1` cu se jimte li 384 detri .i lo 1968 detri se namcu cu se cipra .i lo 384 detri porsi unrank cu se cipra .i lo 252 detri se xruti ranki cu se cipra.

ni'o lo nanca cu kakne lo nu ralte li 5778 detri .i lo ti jimte cu na se banzu lo ro nanca .i lo remoi stadi cu na se mulno .i lo `LAST_COMPLETED_STAGE` cu du li pa.

ni'o ko benji `sh run_stage02_endpoint_weaving_tests.sh` .e `sh run_stage02_canonical_weaving_tests.sh` tezu'e lo nu cipra lo masti porsi .i lo se narmanci javni cu se ciska fi `WEAVING_ENDPOINT_PROOF.md`.

## lo memori jimte te cipra

ni'o lo `run_stage02_weaving_heap_tests.sh` cu cipra lo narmanci `MonsterWeavingEndpointDP` fi lo Java Heap be li 256 MiB pe lo 984 detri nanca .e lo 512 MiB pe lo 1968 detri nanca .i lo Heap cu se jimte fi lo `-Xmx` .i lo te cipra cu se snada po'o ca lo GitHub Actions cu benji lo `PASS`. lo drani javni be li 5778 detri cu za'o nitcu lo balvi se zbasu.

## lo pa se stika jimte be lo fanmo masti

ni'o lo `MonsterWeavingLinearCounter` cu pilno lo nu lo fanmo se viska be lo fanmo masti cu rinka lo fanmo judri be lo mulno porsi .i seni'i lo endpoint te jicmu cu se vimcu fi lo fanmo judri .i lo se namcu be lo te jicmu cu zenba fi lo se pamoi judri po'o. lo `BigInteger` cu ralte lo drani ranki .i lo 5778 detri count cu se cipra fi lo Java Heap be li 256 MiB.

ni'o lo ti sampla cu se pilno lo count .e lo countAfterPrefix po'o .i lo 5778 detri unrank cu za'o na se zbasu .i lo `MonsterWeavingEndpointDP` .e lo `MonsterCanonicalWeaving` cu za'o ralte lo 384 detri jimte.

ni'o lo pa se stika masti namcu te javni cu se ciska fi `WEAVING_LINEAR_PROOF.md`. lo se namcu be lo 5778 djedi cu se cipra fi lo 256 MiB Java Heap .i lo mulno se cuxna masti porsi cu za'o nitcu lo balvi cipra .e lo balvi narmanci javni.

ni'o lo `MonsterWeavingLinearCounter.unrank1` .e lo `rank1` cu se pilno fi lo drani se jmite porsi be li 512 djedi .i lo 5778 djedi count cu za'o drani .i lo drata ranki be lo mulno nanca cu za'o nitcu lo balvi se zbasu.

ni'o lo `MonsterCanonicalWeaving` cu pilno lo `MonsterWeavingLinearCounter` fi lo 512 djedi cuxna .i lo vo moi kabri .e lo 32 moi tcita cu se stodi .i lo mutce barda nanca cuxna cu za'o nitcu lo balvi cipra.
