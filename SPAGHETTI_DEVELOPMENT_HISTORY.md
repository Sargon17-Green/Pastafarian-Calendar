# Historio de la spageta evoluo

## Stadio 1 — Bootstrap

La realiga linio komenciĝas de nulo en Gleam kun Esperanto kiel sola homlingva fonto. Neniu alia realigo estas uzata kiel semantika, kalkula aŭ testa fonto.

En ĉi tiu stadio ekzistas ankoraŭ neniu historia eraro kaj neniu flikaĵo. La sistemo ricevas nur neŭtralan bazan kuntekston, validigilon kaj dissendilon. La celo de tiuj tavoloj estas prepari kontrolitan kreskon de la posta monstra arkitekturo sen antaŭe enkonduki kampojn aŭ konduton de estontaj stadioj.

La `SourceLanguageCatalog` estas kreita kaj frostigita. Ĉiu nomo restas ligita al stabila `canonicalIndex`; la Esperanta teksto estas prezenta valoro kaj ne rajtas ŝanĝi normigan ordon.

### Vera ilara kontrolo

Stadio 1 poste estis kontrolita per GitHub Actions sur Ubuntu 24.04.4 LTS kun Gleam 1.18.1 kaj Erlang/OTP 28. La unuaj kontrolruloj malkovris nur problemojn ene de la Bootstrap-amplekso: nevalidan Gleam-sintakson, malnovan `gleam/list.at`-uzon, mankantan `Option`-importon, mankantan Gleeunit-enirpunkton, nekanonan formaton kaj eraron en `remove_at1`, kiu misordigis permutan malrangigon.

Ĉiu trovita problemo estis riparita sen aldoni Stadio-2-kodon aŭ estontajn flikaĵajn mekanismojn. La fina kontrolrulo `33114635728` ĉe commit `8e6dee70e7ab6cfa27f1c1d2b571eb3d5754ce54` pasis: la origina `gleam format --check src test` redonis 0, `gleam test` raportis `9 passed, no failures`, kaj la laborfluo finis per `STADIO_01_REZULTO=PASS`.

Per tiu rezulto Stadio 1 estas GREEN kaj `LAST_COMPLETED_STAGE` fariĝas 1.
