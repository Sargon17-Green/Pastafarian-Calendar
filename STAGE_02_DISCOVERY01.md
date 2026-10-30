# Fase 2 — DISCOVERY01 — zelfstandig productiedagfundament

Status: code gecommit; native verificatie van dit commit nog vereist.
Vorige gate: Stage 1 Native GREEN, 8 tests en 46 assertions op run 40720041331.

## Omvang

- Eigen productienamespace `pastafari.dagfundament` voor exacte dagtelling, inclusieve afstand, verbinding en richting.
- De dispatcher berekent deze vijf velden na inputvalidatie en legt ze per aanroep vast in `:semantic-state`.
- Geen enkele productie-namespace verwijst naar het testorakel.
- Onvolledig kalenderdatumtraject blijft expliciet `:production-path-not-yet-built`; geen schijndatum en geen fallback.
- Testvectoren aan weerszijden van de stichtingsdag, grote gehele getallen, fouten en 49 onafhankelijke inputparen tegenover het testorakel.

## Verificatie-eisen

1. `clojure -M:test` op dit exacte commit moet slagen: Stage 1-regressie en Stage 2-tests.
2. Canonical Names Lock moet slagen.
3. Rapporteer aantallen tests en assertions uitsluitend uit het native log.
4. Deze ontdekking is geen bewijs voor de saus, de poorten, jaarselectie, kotelet-/maandstructuur of de vijfdelige productiedatum.

## Volgende inhoudelijke stap binnen Fase 2

Na Native GREEN: de vroegste ontbrekende productielaag in het normatieve gegevenspad (SAVE, stenen en de saus) afzonderlijk contracteren en met begrensde fixtures toetsen; niet doorgaan naar een volledige datum zonder verificatie van die tussenlagen.
