# Pastafari-kalender — Clojure met Nederlands als brontaal

Dit werkpad begint volledig vanaf nul. Het gebruikt uitsluitend Clojure voor uitvoerbare projectcode, tests en het testorakel. Er zijn geen bronbestanden, tests, fixtures, uitvoerwaarden, tabellen, caches, logs of hashes van een andere implementatielijn gebruikt.

## Fase 1

Fase 1 bevat uitsluitend de bootstraplaag:

- een bevroren `SourceLanguageCatalog` met 17 koteletnamen en 47 maandnamen;
- een neutrale context voor één aanroep;
- een neutrale dispatcher, invoervalidatie, foutomslag en metriekenschaal;
- een productiegeraamte zonder historische fouten of toekomstige patches;
- een schoon, uitsluitend voor tests bedoeld normatief orakel dat rechtstreeks uit de ingebedde normatieve referentie is opgebouwd;
- lokaal afgeleide kleine fixtures voor exacte rekenkundige grensgevallen;
- tests voor exacte gehele getallen, SAVE, dagtellingen, stenen, kominitialisatie, permutaties, korte en brede selectie, geordende families, de brontaalcatalogus en de deterministische saus.

De productiefunctie geeft in deze fase bewust nog geen kalenderdatum terug. Zij roept het testorakel niet aan en bevat geen terugval naar het orakel. De historische productielijn wordt pas in latere fasen opgebouwd.

## Exacte gehele getallen

Clojure heeft willekeurig grote gehele getallen. Normatieve vermenigvuldigingen en optellingen die groot kunnen worden gebruiken expliciet de onbeperkte gehele-getalroute. Er wordt geen floating point gebruikt voor normatieve berekeningen.

## Tests

Met een geïnstalleerde Clojure CLI:

```text
clojure -M:test
```

of:

```text
./run_stage01.sh
```

Fase 1 is op 28 oktober 2026 als Native GREEN bevestigd. GitHub Actions voerde `clojure -M:test` uit op commit `2483d0967013fff62cd6ed7e6663fb44b14d9fa6`: 8 tests, 46 assertions, 0 failures, 0 errors. Het bewijs staat in [run 40720041331](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40720041331). De historische productielijn voor een volledige kalenderdatum wordt pas in een later, apart goed te keuren fase gebouwd.
