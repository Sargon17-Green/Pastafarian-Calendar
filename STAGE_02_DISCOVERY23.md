# Fase 2 — DISCOVERY23 — begrensde vijfveldige dagprojectie

## Vorige bewijsgrens
- Branch: `Clojure+Nederlands`; parent-HEAD `b18bbcdb6aacac5731f630a78d28071c905bf93b`.
- Run `41523934114`: `clojure-native-stage02-discovery22` job `125546690702` completed SUCCESS; native raw **102 tests, 41848 assertions, 0 failures, 0 errors**. Verify job `125546691024` completed SUCCESS op dezelfde branch/SHA. Alleen DISCOVERY22 is geaccepteerd.
- Stage 2 en universele kalenderdatum blijven OPEN.

## Productiecontract
- `pastafari.datumprojectie/projecteer-bewezen-dag(basis,doeldag)` levert exact vijf **numerieke** velden:
  `[jaar, koteletnaamindex, dag-in-kotelet, maandnaamindex, dag-in-maand]`.
- Het doeljaar heeft `252..5778` dagen met `open < doel <= close`, 6..17 aaneengesloten koteletten en 3..47 maanden van 4..123 dagen. De verweving moet precies de opgegeven lengtes per maand bevatten, en de namen van koteletten en maanden moeten geldig en uniek zijn.
- De projectie leest uitsluitend **bestaande bewezen velden**. Geen nieuwe saus, ongecontroleerde enumeratie, kalenderheuristiek of normatieve broncode in productie. Het resultaat is alleen geldig voor een structureel gecontroleerd, reeds geselecteerd jaar.
- Foutcodes: `:invalid-date-projection-structure`, `:target-day-outside-proven-year`, `:date-cutlet-not-found`. Ongeldige structuren worden fail-closed geweigerd.
- `kies-bewezen-datum` is een expliciete opt-in wrapper van `maandnamen/kies-maandnamen`. Ze bewaart alle metadata, geeft standaard `zoekbudget=128N` en `celbudget=5000000N` onveranderd door en voegt **alleen** `:date-components` toe.
- Resourcegrens: O(5778 + 47 + 17) geheugen/bewerkingen voor de projectie (zonder voorafgaande DP), exact één jaar, geen zoeklus. Controleer eerst de vectorlengte; bereken pas daarna de frequenties, zodat een te grote onbewezen invoer geen lineaire scan veroorzaakt. De upstream-selector weigert onbewijsbare maandweefkosten vóór de sauskeuze.

## Onafhankelijke bewijsopzet
- Gebruik de bestaande `normative-oracle/calendar-date-canonical` voor de 252 dagelijkse posities van een gecontroleerd jaar met verweven maanden, plus zeven eindige grensgevallen van een jaar met 47 maanden en 5778 dagen. Stub alleen jaarzoekactie en jaarstructuurbouw; **niet** de canonieke berekening van de vijf velden.
- Deze gecontroleerde differentiaal bewijst de **projectie**, niet een universele end-to-end-uitvoering van jaar/maandkeuze. Er is geen onafhankelijke bron gekopieerd naar productie.
- Negatieve tests: dag vóór/na jaar, onvolledige maanden, ongeldige indices, dubbele naam, gebroken koteletcontinuïteit, buitenlimieten, upstream-budgetweigering.
- Acceptance: statische delimitercontrole en onafhankelijke numerieke gevallen (geen Native); HEAD en alle blobs teruglezen; dan één push; alleen na completed SUCCESS van **Native én verify** op hetzelfde commit plus ruwe test-/assertionaantallen mogen we DISCOVERY23 accepteren.
- Geen main/merge/publicatie.

## NEXT
Na Native-acceptatie van DISCOVERY23: DISCOVERY24 — gecontroleerde echte end-to-end datumdifferential binnen vooraf bewezen celbudget, extra grensgevallen van doeljaren en expliciet onderscheid tussen bewezen en afgewezen input. Geen volledige kalenderclaim vóór verifieerbare dekking.
