# Fase 2 — DISCOVERY22 — 47 unieke maandnamen, kom 5/zegel 33

## Geaccepteerde voorgaande poort
- Branch `Clojure+Nederlands`, ouder-HEAD `2f379196a022e581bdf5999eb618cf47b9bb1294`.
- GitHub Actions run `41504242421`: `clojure-native-stage02-discovery21` job `125479296510` completed/SUCCESS, ruwe log: **98 tests, 39338 assertions, 0 failures, 0 errors**.
- `verify` job `125479296722` completed/SUCCESS op dezelfde branch en SHA. Alleen DISCOVERY21 is geaccepteerd; Stage 2 en vijf datumcomponenten blijven OPEN.

## Productiecontract: zuivere, begrensde naamreeksen
- `pastafari.maandnamen/aantal-maandnaamreeksen(voorraad,aantal)` met exacte gehele `1<=voorraad<=47`, `1<=aantal<=voorraad` geeft `P(voorraad,aantal)=voorraad!/(voorraad-aantal)!` als BigInt.
- `maandnamen-op-rang(voorraad,aantal,rang)` neemt `1<=rang<=P` en levert precies `aantal` unieke lexicografische **bronindices** uit `1..voorraad` (geen vertaalde labels).
- Productie rekent met een nulgebaseerde gemengd-radix-rang en een eindig 47-bits vrijheidsmasker. Ten hoogste 47 stappen en 47^2 bitproeven; geen enumeratie van `P(47,47)`.
- Fouten: `:invalid-month-name-pool`, `:invalid-month-name-count`, `:invalid-month-name-rank`. Ongeldige, niet-integere, null en extreem grote invoer wordt geweigerd.

## Nieuwe opt-in selectie, zonder oude API te verruimen
- `kies-maandnamen(lijn,berekeningsdag,doeldag[,zoekbudget,celbudget])` erft alle bewezen velden en fouten van `maandselectie/kies-bewezen-maandweving`, standaard `128N,5000000N`; bestaande selectie blijft onaangeroerd.
- Alleen na de budgetbewezen maandweving: de structuursaus voor de eerste dag van het bewezen jaar, **kom 5 / zegel 33**, `keuzestroom/kies-rang` over `P(47,month-count)`.
- Voeg `:month-name-indices` en `:month-name-family-count` toe; behoud álle overige velden. Bij weigering van de upstream-budgetpoort worden saus en rangkeuze niet aangeroepen.
- Voor de normatieve kalender mogen pas na een volledige end-to-end test de exacte vijf datumcomponenten worden samengesteld. DISCOVERY22 doet dit NIET.

## Onafhankelijke tests en acceptatie
- Zelfstandige expliciete recursieve oracle voor **alle rangen** van `P(n,k)` voor `1<=n<=6`, `1<=k<=n`; productiestroom is een andere algoritmische aanpak.
- Extra vergelijking tegen `normative-oracle/unrank-distinct-indices` voor `month-count` 3, 6, 47 en eerste, tweede, middelste, voorlaatste en laatste rang. Vergelijk bronindices, behouden metadata, familieomvang, uniciteit, bereik, kom en zegel.
- Test ook standaard/expliciete budgetdoorgifte, fail-closed vóór saus, ongevalideerde poortlijn, grensrangen van `47!` en precieze foutcodes.
- Statische delimitercontrole op gewijzigde Clojure-bestanden, onafhankelijke numerieke enumeratie, alle GitHub blobs/HEAD controleren; daarna exact één push en CI `clojure -M:test` plus `verify`.
- **Geen DISCOVERY22 PASS** zonder beide completed/SUCCESS op dezelfde SHA én ruwe Native tests/assertions/0 failures/0 errors. Geen main/merge/publicatie.

## NEXT
Na acceptatie van DISCOVERY22: DISCOVERY23 — construeer een **begrensde dag-naar-structuur projectie** voor vijf numerieke datumcomponenten, behoud onafhankelijke `normative-oracle/calendar-date-canonical` als differentiële oracle; wees expliciet over celbudget en kalenderdekking. Eerst contract, tests en eerste veilige implementatie; geen claim van universele datumcorrectheid zonder end-to-end bewijs.
