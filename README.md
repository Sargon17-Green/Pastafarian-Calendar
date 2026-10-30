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

## Stadio 2 — DISCOVERY 01 (Native-kontrolita EXPECTED_RED)

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

La antaŭaj 17 testoj pasis. La Native-rulo ĉe commit
`81548f336d286573f90196bd83731c86767429bd`, Gleam 1.18.1 / OTP 28,
raportis **18 passed, 3 failures**. La tri malsukcesoj estis nur la
intencitaj normigaj malkongruoj ĉe M, 2M kaj 3M; M+1 pasis. La ordinara
Stage01-laborfluo do finiĝis kun `failure` pro la laŭdezire ruĝaj testoj,
ne pro kompila aŭ formata eraro. Rulo:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40718515839

Stadio 2 estas fermita kiel EXPECTED_RED; la malnova rezulto restas
havebla per la diagnoza kampo `legacy_remainder`.

## Stadio 3 — PATCH 01 (Native-konfirmita GREEN)

`save_patch` nun mapigas nulan restaĵon al `M`, lasante ĉiujn aliajn
restaĵojn senŝanĝaj. La valida-disenda produkta vojo redonas kaj la
historian `legacy_remainder` kaj la korektitan `patched_remainder`.
La tri diagnozaj atestoj plu pruvas la antaŭan 0-kontraŭ-M-diverĝon,
sed ne plu postulas malsukcesan CI. La ok apartaj PATCH 01-testoj
komparas la produktan rezulton kun la aparta testa `SAVE`-referenco ĉe
M, 2M, 3M, M+1, 0, -M, -1 kaj 1. Kun la 17 antaŭaj kaj kvar diagnozaj
testoj, la akcepta celo estas 29 sukcesoj, neniu malsukceso, kaj pura
`gleam format --check src test` ĉe la preciza nova HEAD. Tio estis pruvita ĉe la preciza commit `e135560968512cc83d2b8ea81529dc0e653f1724`:
`gleam format --check src test` sukcesis, `gleam test` raportis
**29 passed, no failures**, kaj la aparta Canonical Names Lock sukcesis.
Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040314622
Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040314623

## Stadio 4 — DISCOVERY 02 (intenca EXPECTED_RED; Native atendo)

La dua historia eraro estas `old_day_tag(day) = 2 * abs(day - F)`,
kie `F = -15_055_671` estas la fonda tago. La vera produkta vojo
`dispatch_discovery_02` validigas kaj dissendas la ekzistantan
`MonsterContext` antaŭ ol liveri la malnovan tagmarkon. La normiga
`day_count` estas nur en la sendependa testa referenco.

| Enigo | Malnova tagmarko | Normiga tagnumero | Atendata |
| --- | ---: | ---: | --- |
| F−2 | 4 | 4 | PASS |
| F−1 | 2 | 2 | PASS |
| F | 0 | 1 | EXPECTED_RED |
| F+1 | 2 | 3 | EXPECTED_RED |
| F+2 | 4 | 5 | EXPECTED_RED |

La 29 antaŭaj testoj de Stadio 3 devas resti verdaj. Kun ĉi tiuj kvin
novaj testoj la intencita Native-rezulto estas **31 passed, 3 failures**,
kaj la tri malsukcesoj devas esti nur la supraj normigaj diferencoj.
`gleam format --check src test` devas sukcesi. La ordinara laborfluo
povas finiĝi per `failure` laŭ la intenca EXPECTED_RED-kontrakto;
tio ne egalas plenan CI-PASS. Neniu PATCH 02 estas efektivigita.
Ne fermu Stadion 4 sen la preciza HEAD-atesto.
