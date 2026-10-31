# Fase 2 — DISCOVERY12 — begrensde koteletverdeling over poortgaten

## Aanvaarde basis
- Tak: `Clojure+Nederlands`; ouder-HEAD: `0a8d23867df662681ceff6b5bdf02e43a34e5e09`.
- DISCOVERY11: run `41197291131` completed SUCCESS; Native `clojure -M:test`: 56 tests, 5054 assertions, 0 failures, 0 errors; verify SUCCESS op dezelfde SHA.
- Fase 2 en de vijf uiteindelijke datumcomponenten blijven onvoltooid.

## Invoer en uitvoer
- Zuiver: `pastafari.koteletverdeling/aantal-verdelingen(p,k,b)` en `verdeling-op-rang(p,k,b,rank)`.
- `p` is een exact geheel aantal poortgaten in 6..256; `k` is exact geheel in 6..min(17,p); `b` is nil of een exacte interne poortgrens in 1..p-1.
- `verdeling-op-rang` retourneert een lexicografisch gerangschikte vector van `k` strikt positieve gehele getallen met som `p`, waarbij een **interne** cumulatieve som `b` voorkomt als vereist.
- Bewezen integratie: `kies-verdeling(lijn,berekeningsdag,doeldag[,budget])` gebruikt `koteletaantal/kies-aantal`, behoudt het exacte bewezen jaar en geeft `{:year ... :cutlet-count ... :partition ... :partition-count ... :required-boundary ...}`. Geen namen, maanden of vijfdelige datum.

## Wiskunde en onafhankelijkheid
- Zonder interne grens: `C(p-1,k-1)` positieve composities.
- Met grens `b`: som over `j=1..k-1` van `C(b-1,j-1)*C(p-b-1,k-j-1)`; onmogelijke binomiale factoren tellen als nul.
- Productie gebruikt exacte binomiaalcoëfficiënten en lexicografische afranking door telling van vervolgtakken; zij roept de recursieve normatieve oracle niet aan.
- De testoracle heeft een onafhankelijk gememoiseerd recursief toestandsmodel in `test/pastafari/normative_oracle.clj`, `cutlet-partition-family` en `choose-cutlet-partition`.
- Als `berekeningsdag` precies een bewezen poortdag is **binnen** het gekozen jaar (strikt tussen de open- en sluitindex), is `b=gate-index-open-index` verplicht; anders `b=nil`. Ook de externe jaargrenzen geven geen interne grens.
- Gebruik saus van `open-gate-day+1`, kom 2 met zegel 21, en `keuzestroom/kies-rang` op het exacte familieaantal.

## Termineringsbewijs en foutcodes
- Er worden maximaal 257 poortposities hergebruikt; geen verlenging buiten de reeds bewezen lijn.
- `p<=256`, `k<=17`, maximaal 17 afrankstappen en maximaal 256 geprobeerde keuzes per stap. Iedere tellingsstap bevat maximaal 16 binomiale termen, met maximaal 17 vermenigvuldigings-/delingsstappen per term. Geen externe of onbegrensde zoekruimte.
- Onjuiste poortgatwaarde: `:invalid-gate-gap-count`; `p<6`: `:no-cutlet-candidates`; onjuist `k`: `:invalid-cutlet-count`; onjuiste interne grens: `:invalid-required-boundary`; onjuiste rang: `:invalid-cutlet-partition-rank`.
- Bestaande `koteletaantal`-, `doeljaar`- en poortlijnfouten blijven behouden. Geen stilzwijgende extrapolatie.

## Acceptatietests
1. Volledige onafhankelijke brute-force telling en iedere lexicografische rang voor kleine `p=6..10`, `k=6..min(8,p)`, met en zonder interne grens.
2. Eigen normatieve poorttoestand voor drie berekeningsdagen (-157,0,+413) en voor vorig, huidig en volgend doeljaar: jaar, gekozen aantal en exacte compositie; vergelijk rechtstreekse tegen verlengde poortlijn.
3. Expliciete interne poortdag tegenover de dag ervoor; eerste/laatste rang; uitsluitend kom=2, zegel=21.
4. Maximale `p=256,k=17,b=128`, controles op aantal, positieve delen, som, grens; ongeldige `p,k,b,rank`, zeer groot geheel getal; daggrenzen, nulbudget en geërfde fouten.
5. Statische haakjescontrole, GitHub-branch-/blob-readback, daarna Native `clojure -M:test` en `verify` op precies één commit-SHA. Alleen completed SUCCESS plus een ruwe tests/assertions-log laten acceptatie toe.

## NEXT
Na aanvaarding: DISCOVERY13 onderzoekt de **benaming** van de bewezen koteletten met kom 5/zegel 22 en unieke indices zonder herhaling; formuleer een eindig rangcontract en onafhankelijke permutatie-oracle. Geen stage3, main/merge of volledige datumclaim zonder afzonderlijk bewijs.
