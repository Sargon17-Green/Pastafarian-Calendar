# Fase 2 — DISCOVERY09 — begrensde kandidaat-jaargrenzen

## Basis
- Tak: Clojure+Nederlands. Ouder-HEAD: 220f1a3c723f337307425835450002eafa1a0821.
- DISCOVERY08 Native + verify run 41184526443, beide completed SUCCESS; ruwe Native-log: 44 tests, 4908 assertions, 0 failures, 0 errors.
- De normatieve onafhankelijke bron is test/pastafari/normative_oracle.clj: valid-year-pair?, year5000, next-year, previous-year. Productie importeert geen oracle.
- Poortintervallen uit DISCOVERY08 zijn geen jaren; een geldig jaar overspant minstens 6 poorten en duurt 252..5778 dagen.

## Contract, grensbewijs en tie-breakers
- Invoer: gevalideerde eindige poortlijn met straal 0..128, exact gehele berekeningsdag en, voor aangrenzende jaren, een volledig gevalideerd bekend jaar.
- jaar5000-kandidaten(lijn, dag): vereist P(-r) <= dag-5778 en P(r) >= dag+5778. Som alle poortparen (i,j) met j-i>=6, 252<=P(j)-P(i)<=5778, P(i)<dag<=P(j). Sorteer exact op (lengte, openingsdag). Geen afleiding van een kalenderjaar uit enkel één poortinterval.
- jaar5000(lijn, dag): kies uit bovenstaande met saus(dag,dag), kom 1, zegel 10, rang volgens de reeds gevalideerde keuzestroom.
- volgend-jaar(lijn,dag,jaar): opening = vorige sluitindex; bewijs dekking t/m openingsdag+5778; geldige sluitkandidaten oplopend op lengte. Kies met saus(dag, openingsdag), kom 1, zegel 11; nummer+1.
- vorig-jaar(lijn,dag,jaar): sluiting = vorige openingsindex; bewijs dekking vanaf sluitdag-5778; geldige openingskandidaten oplopend op lengte. Kies met saus(dag, sluitdag), kom 1, zegel 12; nummer-1.
- Bewijs venster ontbreekt -> :year-window-unproven, geen extrapolatie. Dag niet geheel -> :invalid-day; bekend jaar ongeldig -> :invalid-known-year; kandidaten ריקים -> :no-year-candidates. Onjuiste poortlijn wordt door de bestaande poort-API afgewezen.
- Tijd: maximaal 257 poorten, hoogstens O(257²) kandidaattoetsen + O(K log K) sortering; geen unbounded scan. BigInt exact. Beschrijving in dit document is het contract vóór Native-kabul.
- Einde jaar: de normatieve conventie is (open-day, close-day]; de sluitpoort is dus het laatste dagpunt van dit jaar, terwijl de volgende jaaropening dezelfde poortdag is. Dit onderdeel volgt expliciet de onafhankelijke bron.

## Toetsen
- Vergelijk drie berekeningsdagen rond stichtingsdag onafhankelijk met year5000-oracle; test totale kandidaatorde, unieke paren, bewezen lengte- en indexgrenzen.
- Vergelijk vorig en volgend jaar met oracle op gedeelde state; continuïteit van poortindices en jaarlabels; direct gebouwd versus stapsgewijs uitgebreid poortvenster.
- Reject: niet-gehele dagen, vensters zonder dekking, 10^101 buiten bereik, ongeldige poortlijn, gecorrumpeerde bekende jaargrenzen.
- Acceptatie vereist completed SUCCESS en echte Native-log voor nieuw commit plus verify SUCCESS. Geen PASS van vijf-componenten-datum of Stage 2 als geheel.

## NEXT
Na DISCOVERY09 Native+verify: DISCOVERY10 — onderzoek van doeljaarzoekactie met strikte voortgang en begrensde jaarstappen, onafhankelijk oracle en stopvoorwaarden; geen onbegrensde kalenderconstructie, geen main/merge.