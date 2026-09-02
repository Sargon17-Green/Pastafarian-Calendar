# Scheme + dansk — Etap 1

Dette projekt er et selvstændigt implementeringsspor for kalenderalgoritmen. Det er oprettet fra en tom projektmappe og bruger ingen kode, tests, forventede resultater, tabeller, logfiler eller kontrolsummer fra andre implementeringer.

## Programmeringssprog

Al beregningskode i projektet er Scheme. Den konkrete lokale målfortolker er GNU Guile 3.x, som leverer præcise heltal med vilkårlig størrelse. Shellfilerne udfører kun testkommandoen og indeholder ingen kalenderlogik.

## Kildesprog

Alt menneskeskrevet projektindhold er dansk. Navnekataloget er fastlåst ved kanoniske indeks; alfabetisk sortering, Unicode-rækkefølge og dansk kollation må aldrig påvirke den normative semantik.

## Indhold i etap 1

- `src/constants.scm` indeholder de normative konstanter.
- `src/source-language-catalog.scm` indeholder det frosne danske kildesprogskatalog.
- `src/monster-skeleton.scm` indeholder kun neutral grundinfrastruktur: kontekst, dispatcher, validator, fejlwrapper og metrics-skal.
- `test/normative-oracle.scm` er et rent orakel kun til test, bygget direkte fra den indlejrede normative reference.
- `test/fixtures.scm` indeholder små forventede værdier, der kan aflæses direkte af normen.
- `test/run-tests.scm` kontrollerer aritmetik, katalog, sten, permutationer, ordnede familier, vævning, determinisme og de første portgab.
- `test/run-deep-tests.scm` udfører en dyrere kontrol af år 5000.

Der findes ingen historisk fejlsti og ingen lap fra etap 2–53 i denne version.

## Lokal kørsel

Kør fra projektroden:

```text
./run-tests.sh
./run-deep-tests.sh
```

Begge kommandoer skal ende grønt, før etap 1 må erklæres afsluttet.

## Aktuel leveringsbemærkning

Den arbejdscontainer, som oprettede denne pakke, havde ingen Scheme-fortolker installeret, og netværksadgang fra containeren kunne ikke hente en. Koden er derfor forberedt, men den krævede lokale Scheme-kørsel er endnu ikke dokumenteret. `DEVELOPMENT_STAGE.md` markerer derfor ikke etap 1 som afsluttet.
