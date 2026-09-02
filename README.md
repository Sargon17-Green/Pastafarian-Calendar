# Pastafarian Calendar — Lean + norsk bokmål

Dette treet er Bootstrap-leveransen for trinn 1 av 55. Implementasjonen er opprettet fra et tomt prosjekt og bruker Lean som eneste programmeringsspråk. Den normative referansen i `PastafariLean/NormativeOracle.lean` er bygget direkte fra det innebygde normative vedlegget i oppgaven.

## Avgrensning i trinn 1

Trinnet inneholder bare nøytral grunninfrastruktur: en påkallingskontekst, en enkel dispatcher, en valideringsgrense og et observasjonsskall. Ingen historisk feil, ingen legacy-rute og ingen av de 26 senere lappene er lagt inn.

`SourceLanguageCatalog` er frosset i dette trinnet. Normativ rekkefølge følger alltid `canonicalIndex`; tekst på norsk bokmål brukes bare ved presentasjon.

## Kjøring

Med Lean 4.33.1 og Lake installert:

```text
lake build
lake exe pastafari_stage1_tests
```

Alle beregninger i testprogrammet, den normative referansen, fixture-kontrollene og hjelpefunksjonene kjøres i Lean. Shell brukes bare til bygging og oppstart.

## Forventet resultat

En fullført lokal kjøring skal avslutte med maskinkoden `STAGE01_PASS` og returkode 0. Ved første feil avslutter testprogrammet med `STAGE01_FAIL` og returkode 1.
