# Fase 2 — DISCOVERY10 — begrensde doeljaarzoekactie

## Uitgangspunt
- Tak Clojure+Nederlands; ouder-HEAD 47567ba777895e0f45d2b359622e01768383eff2.
- DISCOVERY09, run 41187435629: Native 47 tests / 4940 assertions / 0 fouten; verify completed SUCCESS.
- De normatieve onafhankelijke bron is `test/pastafari/normative_oracle.clj`, `find-target-year`. Productie importeert geen oracle.

## Invoer, uitvoer en semantiek
- Productie `pastafari.doeljaar/vind-doeljaar(lijn, berekeningsdag, doeldag[, budget])`.
- Beide dagen zijn exacte gehele getallen; `lijn` is een gevalideerde poortlijn met straal 0..128, maximaal 257 poorten.
- `budget` is een geheel getal tussen 0 en 128 inclusief; standaard 128 jaarovergangen. Budget 0 accepteert alleen een doel dat in jaar 5000 ligt.
- Resultaat is het bestaande jaarrecord met vijf velden `number`, `open-gate-index`, `close-gate-index`, `open-gate-day`, `close-gate-day`; **niet** de vijf definitieve datumcomponenten.
- Jaarconventie: `open-gate-day < doeldag <= close-gate-day`. Op de openingsdag hoort de dag bij het vorige jaar; op de sluitdag bij het huidige jaar.

## Algoritme en eindigheid
1. Controleer dagtypen, budget en bewezen poortlijn; verwerp doel buiten de eindpoorten met `:year-window-unproven`.
2. Bepaal jaar 5000 met de eerder geaccepteerde kandidaatselectie.
3. Als doel in jaar ligt: retourneer onmiddellijk, zonder een overgang te verbruiken.
4. Ligt doel na sluiting: `volgend-jaar`; ligt doel op/vóór opening: `vorig-jaar`. Beide gebruiken alleen de bestaande begrensde lijn.
5. Voordat een overgang geaccepteerd wordt, bewijs gedeelde poort, strikt stijgende sluitindex in voorwaartse richting of strikt dalende openingsindex in achterwaartse richting, en één verschil in jaarnummer.
6. Als een overgang nodig is terwijl `stappen >= budget`, faal expliciet. Er is geen automatische vensterverlenging, geen extrapolatie en geen oneindige lus.

Foutcodes: `:invalid-day`, `:invalid-step-budget`, `:year-window-unproven`, `:year-step-budget-exhausted`, `:year-search-nonprogress`, naast bestaande `:invalid-gate-line`, `:no-year-candidates` en `:invalid-known-year`.

## Oracle en toetsen
- Normatieve `find-target-year` maakt onafhankelijk eigen gate-state en saus; productie deelt geen zoekfunctie/fixtures met het oracle.
- Drie berekeningsdagen (-157, 0, +413 rond de stichtingsdag), elk met jaar 5000, vooruit en achteruit; directe en incrementeel uitgebreide poortlijn.
- Grensgevallen exact op open/close en de eerstvolgende dag; 0, 1 en 2 toegestane overgangen.
- Negatieve tests voor budget -1, 129, breuk en nil; niet-gehele dagen; ongeldige poortlijn; vensters zonder bewijs; daggrootten 10^101; en geïnjecteerde stilstand.
- Bovenlimiet op jaarovergangen 128, poortstraal 128; eindig werk per overgang uit DISCOVERY09. Geen claim over onbegrensde doeljaren.

## Acceptatie
- Eerst statische delimitercontrole, GitHub branch-lease en blob-readback.
- Native `clojure -M:test` en `verify` beide completed SUCCESS op dezelfde commit, met ruwe log voor aantallen tests/assertions. Queued/in_progress ≠ PASS.
- DISCOVERY10 valt binnen Stage2; Stage2 en de uiteindelijke kalenderdatum zijn **niet** gereed. Geen main/merge.

## NEXT na acceptatie
DISCOVERY11: onderzoek de keuze van de jaarinterne structuur (koteletten) op een bewezen doeljaar, met bijbehorend keuzestroomzegel en onafhankelijke compositie-oracle. Formuleer eerst eindige acceptatiegrenzen; geen volledige datumclaim.