# Pastafari-kalender — AWK + nynorsk

Dette treet er Stage 1, bootstrap-steget, for ei sjølvstendig implementasjonsline. Treet er bygd frå null og bruker berre AWK som køyrbart språk.

## Kva som finst i dette steget

- eit desimalt BigInt-lag i rein AWK for eksakt heiltalsrekning;
- ein rein, testberre normativ referanse av kalenderkjernen;
- ein frosen `SourceLanguageCatalog` med 17 kottletnamn og 47 månadsnamn på nynorsk;
- ein nøytral produksjonsgrunnmur med kontekst, dispatch, validering, feilstatus, loggskal og metrikkar;
- lokale fixtures og testar som er avleidde frå den innebygde normative referansen i oppgåva;
- ingen historiske legacy-feil og ingen lapping frå seinare steg.

Produksjonsfunksjonen `calendarDateSpaghetti` er med vilje ikkje ferdig i bootstrap-steget. Ho går berre gjennom den nøytrale grunnmuren og returnerer ein tydeleg ikkje-implementert status. Den testberre referansen er fysisk skild frå produksjonslaget og blir ikkje kalla derfrå.

## Køyring

Frå prosjektrota:

```text
awk -f src/bigint.awk \
    -f src/source_language_catalog.awk \
    -f src/normative_oracle.awk \
    -f src/monster_bootstrap.awk \
    -f test/stage01_fixtures.awk \
    -f test/stage01_tests.awk
```

Språkkontrollen kan køyrast med `test/prose_language_audit.awk` mot prosjekttekstane. Den påkravde maskinverdien i `DEVELOPMENT_STAGE.md` for namnet på naturleg språk er unnateken frå denne kontrollen.

## Eksakt heiltalssemantikk

`mawk` har ikkje vilkårleg presisjon. Alle normative verdiar som kan vekse utover eit lite og trygt indeksområde, blir difor representerte som desimale strengar og rekna med BigInt-funksjonane. Små løkkjeindeksar og avgrensa tabellposisjonar bruker den vanlege AWK-skalarforma berre når verdiane er matematisk små og eksakte.

## Avgrensing for Stage 1

Dette steget inneheld berre generell og nøytral infrastruktur. Det finst ingen kode for patch 01–26, ingen framtidige compatibility-flagg og ingen historiske feilbanar. Slike arr skal først oppstå i dei seinare DISCOVERY- og PATCH-stega.
