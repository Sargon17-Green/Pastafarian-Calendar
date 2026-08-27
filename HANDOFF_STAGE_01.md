# Transdona pako — Stadio 1 el 55

## Amplekso

Ĉi tiu pako estas la komenca laborarbo mem por tute nova, sendependa realiga linio Gleam + Esperanto. Ne ekzistas antaŭa cela deponejo, kaj Stadio 1 laŭ la tasko devas komenci de nulo. Sekve nenio estas enmetata en aŭ vicigata kontraŭ ekzistanta realigo.

La pako enhavas nur la Bootstrap-stadion. Ĝi ne enhavas kodon de flikaĵoj 01–26 kaj ne enkondukas estontajn historiajn erarojn aŭ flikaĵojn.

## Komenca arbstrukturo

- `gleam.toml`
- `README.md`
- `DEVELOPMENT_STAGE.md`
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`
- `HANDOFF_STAGE_01.md`
- `src/pastafari/bootstrap.gleam`
- `src/pastafari/source_language_catalog.gleam`
- `test/reference/core.gleam`
- `test/reference/sauce.gleam`
- `test/reference/calendar.gleam`
- `test/bootstrap_test.gleam`

Ĉiuj ĉi dosieroj estas novaj. Neniu antaŭa dosiero ekzistas por modifi aŭ forigi.

## Sendependeco

La linio estis konstruita rekte el la enigita normiga referenco de la tasko. Neniu alia realigo, testaĵo, fiksaĵo, atendata eliro, generita tabelo, kaŝmemoro, spuro, protokolo, haŝo aŭ kontrolsumo estas uzata kiel semantika aŭ testa fonto.

`SourceLanguageCatalog` estas kreita en Esperanto kaj uzas stabilajn `canonicalIndex`-valorojn. La tradukitaj ĉenoj estas nur prezenta tavolo kaj ne partoprenas rangigon, malrangigon aŭ normigan ordon.

## Loka testado

La nuna labormedio ne enhavas la komandon `gleam` kaj ne enhavas la Erlang-celan rultempon. Tial la Gleam-testoj ankoraŭ ne estis efektive rulitaj. La Bootstrap do ankoraŭ ne rajtas esti markita kiel finita aŭ verda.

Kiam la Gleam/Erlang-ilaro estas disponebla, rulu nur:

```text
gleam format --check src test
gleam test
```

Se iu komando malsukcesas, restu en Stadio 1 kaj riparu nur ĉi tiun Bootstrap-stadion.

## Atendita rezulto

Post sukcesa loka validigo:

- ĉiuj Bootstrap-testoj pasas;
- la produkta dosierujo restas libera de estontaj flikaĵspecifaj kondutoj;
- la testa referenco restas sub `test/` kaj neniam estas produktada rezervvojo;
- la nomkatalogo restas frostigita kaj indekse stabila;
- la nova laborarbo povas esti uzata de la uzanto kiel la unua Git-unuo de la projekto.

## Proponita commit-titolo

`Starigu de nulo la Gleam/Esperanto-realigan linion`

## Proponita commit-korpo

`Kreu de nulo la Bootstrap-stadion de nova sendependa Gleam-linio kun Esperanto kiel sola kanona homlingva fonto. Frostigu la SourceLanguageCatalog kun stabilaj canonicalIndex-valoroj, aldonu neŭtralan bazan monster-kuntekston kaj dissendan/validigan ŝelon, kaj konstruu testan normigan referencon rekte el la enigita specifo. Ne aldonu iun el la 26 historiaj flikaĵoj kaj ne uzu artefaktojn, haŝojn, testojn aŭ elirojn de alia realigo.`

## Preta klarigo por GitHub

`Ĉi tiu ŝanĝo estas Stadio 1/55 kaj samtempe la komenca laborarbo de la projekto. Ĝi komencas de nulo novan sendependan Gleam + Esperanto-realigan linion. La Esperanta nomkatalogo estas frostigita kaj la normiga ordo uzas nur canonicalIndex. La produkta infrastrukturo estas intence neŭtrala; neniu posta legacy-eraro aŭ flikaĵo aperas antaŭtempe. La normiga referenco troviĝas nur sub test/ kaj ne estas produktada rezervvojo.`

## Instrukcio al la uzanto

Uzu la enhavon de ĉi tiu pako kiel la radikon de la nova laborarbo. Ne kunfandu ĝin kun alia lingva realigo kaj ne uzu alian realigon por kontroli ĝiajn rezultojn. Poste, kiam Gleam/Erlang estas disponebla, rulu la du lokajn Gleam-komandojn supre. Nur post ambaŭ sukcesoj marku Stadio 1 kiel kompletigita kaj kreu mem la apartan Git-historian unuon.
