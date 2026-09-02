# Nim + magyar forrásnyelv — 1. szakasz

Ez a könyvtár a Magilla időszámításának önálló Nim-megvalósítási vonalát indítja. A jelenlegi állapot kizárólag az 1. szakaszhoz tartozik: létrejött a pontos egészaritmetikai alap, a tesztelési célú normatív referencia, a magyar forrásnyelvi katalógus, valamint a semleges végrehajtási váz.

A termelési `calendarDateSpaghetti` ezen a szakaszon szándékosan még nem állít elő naptári eredményt. A későbbi történeti hibák és foltok közül egyetlenegy sincs előre beépítve.

## Könyvtárszerkezet

- `src/exact_bigint.nim`: saját, Nimben írt, tetszőleges pontosságú előjeles egészaritmetika.
- `src/source_language_catalog.nim`: a rögzített magyar forrásnyelvi katalógus 17 szelet- és 47 hónapnévvel.
- `src/monster_base.nim`: semleges kontextus, diszpécser, validátor, hibaburkoló és metrikahéj.
- `src/pastafari_spaghetti.nim`: a későbbi termelési út belépési váza.
- `tests/normative_oracle.nim`: tiszta, tesztelési célú normatív referencia az A függelék alapján.
- `tests/bootstrap_fixtures.nim`: helyben levezetett alap-fixture értékek.
- `tests/stage01_tests.nim`: az 1. szakasz tesztcsomagja.
- `SOURCE_LANGUAGE_CATALOG.md`: a magyar névképzés és átírás rögzített szabályai.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`: kizárólag a már megtörtént fejlesztési történet.
- `DEVELOPMENT_STAGE.md`: gépileg olvasható szakaszállapot.
- `HANDOFF_STAGE_01.md`: az átadási csomag leírása.

## Futtatás

A tesztek kizárólag Nim segítségével futtathatók:

```text
nim c -r tests/stage01_tests.nim
```

A projekt nem használ más programozási nyelvű oracle-t, generátort, fixture-forrást vagy futtatókörnyezetet.

## Állapot

A jelen átadási környezetben Nim-fordító nem állt rendelkezésre, ezért a tesztcsomag tényleges fordítása és futtatása még nem igazolt. Emiatt az 1. szakasz addig nem tekinthető befejezettnek, amíg a fenti parancs valódi Nim-környezetben zölden le nem fut.
