# Historio de la spageta evoluo

## Stadio 1 — Bootstrap

La realiga linio komenciĝas de nulo en Gleam kun Esperanto kiel sola homlingva fonto. Neniu alia realigo estas uzata kiel semantika, kalkula aŭ testa fonto.

En ĉi tiu stadio ekzistas ankoraŭ neniu historia eraro kaj neniu flikaĵo. La sistemo ricevas nur neŭtralan bazan kuntekston, validigilon kaj dissendilon. La celo de tiuj tavoloj estas prepari kontrolitan kreskon de la posta monstra arkitekturo sen antaŭe enkonduki kampojn aŭ konduton de estontaj stadioj.

La `SourceLanguageCatalog` estas kreita kaj frostigita. Ĉiu nomo restas ligita al stabila `canonicalIndex`; la Esperanta teksto estas prezenta valoro kaj ne rajtas ŝanĝi normigan ordon.

### Vera ilara kontrolo

Stadio 1 poste estis kontrolita per GitHub Actions sur Ubuntu 24.04.4 LTS kun Gleam 1.18.1 kaj Erlang/OTP 28. La unuaj kontrolruloj malkovris nur problemojn ene de la Bootstrap-amplekso: nevalidan Gleam-sintakson, malnovan `gleam/list.at`-uzon, mankantan `Option`-importon, mankantan Gleeunit-enirpunkton, nekanonan formaton kaj eraron en `remove_at1`, kiu misordigis permutan malrangigon.

Ĉiu trovita problemo estis riparita sen aldoni Stadio-2-kodon aŭ estontajn flikaĵajn mekanismojn. La fina kontrolrulo `33114635728` ĉe commit `8e6dee70e7ab6cfa27f1c1d2b571eb3d5754ce54` pasis: la origina `gleam format --check src test` redonis 0, `gleam test` raportis `9 passed, no failures`, kaj la laborfluo finis per `STADIO_01_REZULTO=PASS`.

Per tiu rezulto Stadio 1 estas GREEN kaj `LAST_COMPLETED_STAGE` fariĝas 1.

## Stadio 2 — DISCOVERY 01 (preparo)

La aprobita DISCOVERY 01 nun havas propran produktan enirejon por la
malnova restaĵo: `dispatch_discovery_01` trapasas la ekzistantan
Bootstrap-kuntekston kaj poste kalkulas `old_remainder`. Tio intence
restas malsama ol kanona SAVE ĉe M, 2M kaj 3M; M+1 estas kontrola
kazo. Ĉi tiu preparo ne estas PATCH 01 kaj ne estas Stage-3-kodo.
La akcepta kondiĉo estas Native-testado montranta precize la tri
intencajn diverĝojn kaj nul regresojn de Stadio 1. Ankoraŭ ne aprobita
kiel finita Stadio 2.

### Native-atesto por DISCOVERY 01 — 2026-10-28

La ekzakte testita commit `81548f336d286573f90196bd83731c86767429bd`
pasis la kanonan formatkontrolon kaj kompiladon per Gleam 1.18.1 / OTP 28.
`gleam test` raportis 18 sukcesojn kaj precize 3 intencajn malsukcesojn:
`discovery_01_m_expected_red_test`, `discovery_01_2m_expected_red_test`,
`discovery_01_3m_expected_red_test` (0 kontraŭ M). La M+1-testo kaj la
17 antaŭaj testoj pasis. La workflow-konkludo `failure` estas la laŭkontrakta
EXPECTED_RED, ne CI-PASS. Stadio 2 povas fermiĝi kiel EXPECTED_RED; ne malfermu
Stadion 3 sen aprobo.

https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40718515839

## Stadio 3 — PATCH 01 (2026-10-30; Native-konfirmo atendata)

La aprobita PATCH 01 aldonas `save_patch` en la ekzistantan produktan
vojon sen perdi la malnovan diagnozan valoron. La korekto konvertas
nur nulan restaĵon al M. La kvar DISCOVERY 01-testoj fariĝas pozitivaj
atestoj pri la historia konduto; ok novaj testoj konfirmas normigan SAVE
ankaŭ por negativaj kaj nulaj enigoj. Planita suma kontrolado:
17 antaŭaj + 4 historiaj + 8 PATCH 01 = 29 testoj. Native-testado sur
la preciza Stage 3 HEAD ankoraŭ estas postulata antaŭ ol fermi la stadion.
