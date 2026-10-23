// Snapshot regression: exact Stage01 Esperanto names at all canonical indices.
// The initial snapshot was transcribed from the current Gleam source at
// 802829eca9182cc3d8cf2d6f60bea2f8989bde7c. It is independent at
// test execution time, but not an external normative linguistic oracle.
import gleam/list
import gleeunit/should
import pastafari/source_language_catalog
import reference/core

pub fn frozen_cutlet_names_test() {
  let expected = [
    "bronzo",
    "vulpo",
    "reno",
    "Lagaŝo",
    "penso",
    "kvar partoj el naŭ",
    "Palguraŝ",
    "papiruscipero",
    "grapolo",
    "skorpio",
    "cindro",
    "tritiko",
    "rivero",
    "rido",
    "Akado",
    "korno",
    "la malplena kruĉo",
  ]

  core.range_inclusive(1, 17)
  |> list.map(source_language_catalog.cutlet_name)
  |> should.equal(expected)
}

pub fn frozen_month_names_test() {
  let expected = [
    "argilo",
    "granato",
    "kubuto",
    "envio",
    "Eriduo",
    "dentopasto",
    "tri partoj el kvin",
    "Karŝumav",
    "leopardo",
    "stano",
    "nebulo",
    "olibano",
    "spindelo",
    "ripo",
    "karobo",
    "Uruko",
    "honto",
    "kamelo",
    "kupro",
    "puto",
    "ovoflavo",
    "stelo",
    "mielo",
    "lieno",
    "kalkŝtono",
    "ĝojo",
    "figo",
    "Ninevo",
    "rano",
    "peĉo",
    "lampo",
    "la fermita pordo",
    "sezamo",
    "nuko",
    "arĝento",
    "Susa",
    "ŝtormo",
    "azeno",
    "faruno",
    "bedaŭro",
    "Babilono",
    "lango",
    "lino",
    "salo",
    "piro",
    "pafarko",
    "sablo",
  ]

  core.range_inclusive(1, 47)
  |> list.map(source_language_catalog.month_name)
  |> should.equal(expected)
}

pub fn frozen_catalog_metadata_test() {
  source_language_catalog.catalog_version |> should.equal("1.0.0")
  source_language_catalog.natural_language |> should.equal("Esperanto")
  source_language_catalog.cutlet_count |> should.equal(17)
  source_language_catalog.month_count |> should.equal(47)
}
