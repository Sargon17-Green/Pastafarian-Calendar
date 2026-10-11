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
STAGE_01_PASS checks=249
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
