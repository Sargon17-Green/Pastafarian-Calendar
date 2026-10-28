# Pastafaria kalendaro — Gleam / Esperanto

Ĉi tiu laborarbo estas la komenco mem de tute nova kaj sendependa realiga linio. Ĝi ne estas aldonaĵo al antaŭa deponejo kaj ne estas portado de alia realigo. La sola programlingvo de la linio estas **Gleam**. La sola kanona homlingva fonto estas **Esperanto**.

La unua stadio enhavas nur neŭtralan bazan infrastrukturon: bazan kuntekston, bazan dissendilon, bazan validigilon kaj bazan ŝelon por stato. Ĝi ne enhavas historian eraron el iu posta stadio kaj ne enhavas antaŭtempan flikaĵon.

## Kanona nomkatalogo

`SourceLanguageCatalog` estas frostigita ĉe versio `1.0.0`. Ĉiu el la 17 kotletnomoj kaj 47 monatnomoj havas fiksan `canonicalIndex`. La normiga ordo ĉiam sekvas tiun indekson. Alfabeta ordo, Unikoda ordo, loka komparo kaj la tradukita teksto ne rajtas influi rangigon, malrangigon, elekton aŭ kaŝmemoran ŝlosilon.

Semantike signifohavaj nomoj estas tradukitaj laŭ sia signifo. Propraj loknomoj uzas konvencian Esperantan formon kiam tia formo estas natura; alie ili estas determinisme Esperantigitaj. Sensencaj sonkombinoj estas transskribitaj, ne tradukitaj. La fiksa transskriba regulo por nekanonaj sonkombinoj estas: konservi la konsonantan sinsekvon, reprezenti la hebrean ŝ-sonon per `ŝ`, doni nur la vokalojn eksplicite indikitajn de la fonta formo, kaj ne aldoni inventitan signifon.

## Sendependeco de aliaj realigoj

La testa referenco kaj la Bootstrap-fiksaĵoj estas derivitaj nur el la enigita normiga referenco de la tasko. Neniu alia lingva realigo, ĝiaj eliroj, haŝoj, kontrolsumoj, testoj, fiksaĵoj aŭ generitaj tabeloj estas uzataj.

## Testa normiga referenco

La dosieroj sub `test/reference/` estas testa referenco, ne produkta rezervvojo. Produkta kodo ne rajtas voki ilin. Ili estas intencitaj kiel rekta, pura realigo de la enigita normiga algoritmo por lokaj diferencialaj testoj de ĉi tiu sama Gleam-linio.

## Int-semantiko

La projekto celas la Erlang-celon de Gleam, por ke la normiga tuta entjera aritmetiko restu preciza kaj ne uzu glitkomajn nombrojn.

## Lokaj komandoj

Post kiam Gleam kaj la Erlang-celo estas disponeblaj:

```text
gleam format --check src test
gleam test
```

Neniu alia programlingvo estas parto de la kalkula aŭ testa vojo.

## Stadio 2 — DISCOVERY 01 (preparita, ankoraŭ sen Native-kontrolo)

La antaŭe aprobita DISCOVERY 01 enkondukas intence malnovan modulusan
operacion `old_remainder` tra la vera `dispatch_discovery_01`
vojo, kiu unue validigas kaj dissendas la bazan `MonsterContext`.
Ĝi ne enkondukas `savePatch`, nulan restaĵon al `M` konvertantan
korekton, aŭ kodon de Stadio 3.

La normiga `SAVE(x) = 1 + regular_mod(x - 1, M)`, kie
`M = 2^127 - 1`, restas en `test/reference/core.gleam`.
La kvar testaj kazoj en `test/discovery_01_test.gleam` devas montri:

| Enigo | Legacy | SAVE | Postulo |
| --- | ---: | ---: | --- |
| M | 0 | M | EXPECTED_RED |
| 2M | 0 | M | EXPECTED_RED |
| 3M | 0 | M | EXPECTED_RED |
| M+1 | 1 | 1 | PASS |

La antaŭaj 17 testoj devas pasi. La sumo atendata por `gleam test`
estas 18 sukcesoj kaj precize 3 intencaj malsukcesoj, sed tio ne estas
observita rezulto ĝis Native-kontrolo en GitHub Actions. Ne interpretu
la intencon kiel efektivan CI-rezulton.
